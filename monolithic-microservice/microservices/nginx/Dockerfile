FROM ubuntu:14.04
RUN apt-get update && apt-get install nginx
WORKDIR /opt
COPY conf /opt/conf
RUN cp conf/mysite /etc/nginx/sites-available/ && \
	cd /etc/nginx/sites-enabled && \
	ln -s ../sites-available/mysite
