#!/usr/bin/env python3
import socket, time, sys

HOST = 'talkto'  # Standard loopback interface address (localhost)
PORT = 2000        # Port to listen on (non-privileged ports are > 1023)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    conn, addr = s.accept()
    with conn:
        print('Connected by', addr)
        while True:
            data = conn.recv(1024)
            print('Received:', data)
            sys.stdout.flush()
            if not data:
                break
            time.sleep(5)
            conn.sendall(data)
