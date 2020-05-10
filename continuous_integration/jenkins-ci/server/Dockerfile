FROM jenkins/jenkins:2.234
COPY jenkins_plugins.txt /tmp/jenkins_plugins.txt
RUN /usr/local/bin/plugins.sh /tmp/jenkins_plugins.txt
USER root
RUN rm /tmp/jenkins_plugins.txt
RUN groupadd -g 999 docker
RUN addgroup -a jenkins docker
USER jenkins
