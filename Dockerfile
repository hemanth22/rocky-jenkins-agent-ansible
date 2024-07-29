FROM quay.io/hemanth22/rockylinux9:9

# Install necessary packages
RUN yum -y update && \
    yum -y install java-17-openjdk java-17-openjdk-devel fontconfig wget git sudo git git-lfs less patch && \
    yum clean all && \
    rm -rf /var/cache/yum

# Set up directories and environment variables for Jenkins agent
ENV AGENT_WORKDIR="/home/jenkins/agent"

# Set timezone environment variable
ENV TZ=Etc/UTC

# Set LANG environment variable
ENV LANG=C.UTF-8

# Define Jenkins user and group
ENV user=jenkins
ENV group=jenkins
ENV uid=1000
ENV gid=1000

# Set up Jenkins agent user
RUN groupadd -g "1000" "jenkins" && useradd -l -c "Jenkins user" -d /home/jenkins -u "1000" -g "1000" -m "jenkins" -s /bin/bash

# Give Jenkins user passwordless sudo privileges
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up volumes and working directory
USER jenkins
RUN mkdir -p /home/jenkins/.jenkins && mkdir -p "${AGENT_WORKDIR}"
RUN mkdir -p /home/jenkins/.ansible
VOLUME /home/jenkins/.ansible
VOLUME /home/jenkins/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR /home/jenkins

ENV VERSION=3256.v88a_f6e922152
ADD --chown="jenkins":"jenkins" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

# Switch to root user temporarily to install additional tools or binaries
USER root

# Copy custom Jenkins agent script and set permissions
COPY jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent \
    && ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

# Switch back to Jenkins user
USER jenkins

# Define entrypoint for inbound agent
ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
