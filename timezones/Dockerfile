FROM centos:7
RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/GMT /etc/localtime
CMD date +%Z
