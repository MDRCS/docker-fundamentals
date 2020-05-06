FROM debian
RUN apt-get update -y && apt-get install net-tools
  RUN echo "Acquire::http::Proxy \"http://$( \
route -n | awk '/^0.0.0.0/ {print $2}' \
 ):8000\";" \
 > /etc/apt/apt.conf.d/30proxy
RUN echo "Acquire::http::Proxy::ppa.launchpad.net  DIRECT;" >> \
         /etc/apt/apt.conf.d/30proxy
CMD ["/bin/bash"]
