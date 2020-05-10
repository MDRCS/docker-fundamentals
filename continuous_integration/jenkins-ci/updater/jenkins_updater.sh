#!/bin/sh
set -e
set -x
if ! docker pull jenkins-ci | grep up.to.date
then
	docker stop jenkins-ci
	docker rename jenkins-ci jenkins-ci.bak.$(date +%Y%m%d%H%M)
	cp -r /var/docker/mounts/jenkins_home /var/docker/mounts/jenkins_home.bak.$(date +%Y%m%d%H%M)
	docker run -d --restart always -v /var/docker/mounts/jenkins_home:/var/jenkins_home --name jenkins-ci -p 8080:8080 -p 50000:50000 jenkins-ci
	find /var/docker/mounts/jenkins_home.bak.* -maxdepth 0 -mindepth 0 -ctime +30 | xargs -n1 rm -rf
fi
