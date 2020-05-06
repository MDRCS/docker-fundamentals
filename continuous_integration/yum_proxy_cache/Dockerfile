FROM centos:centos7
RUN yum update -y && yum install -y net-tools
    RUN echo "proxy=http://$(route -n | \
   awk '/^0.0.0.0/ {print $2}'):8080" >> /etc/yum.conf
   RUN sed -i 's/^mirrorlist/#mirrorlist/' \
  /etc/yum.repos.d/CentOS-Base.repo
   RUN sed -i 's/^#baseurl/baseurl/' \
    /etc/yum.repos.d/CentOS-Base.repo
RUN rm -f /etc/yum/pluginconf.d/fastestmirror.conf
RUN yum update -y
CMD ["/bin/bash"]
