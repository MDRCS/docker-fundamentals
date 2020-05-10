FROM debian
RUN apt-get update && apt-get install -y python3
ADD client.py /client.py
CMD ["/usr/bin/python3","/client.py"]

