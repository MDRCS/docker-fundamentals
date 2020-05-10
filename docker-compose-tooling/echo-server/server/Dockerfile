FROM debian
RUN apt-get update && apt-get install -y netcat && apt-get install -y nmap
CMD ncat -l 2000 -k --exec /bin/cat
