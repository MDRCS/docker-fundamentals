### - Running containers as daemons :

    + As you get familiar with Docker (and if you’re anything like us),
      you’ll start to think of other use cases for Docker, and one of
      the first of these is to run Docker containers as running services.

### - Steps (on MAC):
    1- Before you open up the Docker daemon, you must first shut the running one down.
       How you do this will vary depending on your operating system.
       If you’re not sure how to do this, you can first try this command.

       - sudo su - (connect as root user)
       - docker run -d -i -p 1234:1234 --name daemon ubuntu nc -l 1234

       :The -d flag, when used with docker run, runs the container as a daemon.
       The -i flag gives this container the ability to interact with your Telnet session.
       With -p you publish the 1234 port from the container to the host.
       The --name flag lets you give the con- tainer a name so you can refer to it later.
       Finally, you run a simple listening echo server on port 1234 with netcat (nc).

       If you now connect to it and send messages with Telnet, you can see that the container
       has received the message by using the docker logs command, as shown in the following listing.
