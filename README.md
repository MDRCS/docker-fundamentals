# docker-fundamentals
All-in-One Docker Commands High-Performance Architecture For Production needs.

### - Docker Architecture :

![archi](./static/docker-architecture.png)

    + Docker on your host machine is (at the time of writing) split into two parts—a dae- mon with a RESTful API and a client that talks to the daemon.
      Figure above shows your host machine running the Docker client and daemon.
      RESTFUL A RESTful API is one that uses standard HTTP request types such as GET, POST, DELETE, and others to perform functions that usually correspond
      to those intended by HTTP’s designers.

      You invoke the Docker client to get information from or give instructions to the daemon; the daemon is a server that receives requests and returns
      responses from the cli- ent using the HTTP protocol. In turn, it will make requests to other services
      to send and receive images, also using the HTTP protocol. The server will accept requests from the command-line client or anyone else authorized to connect.
      The daemon is also responsible for taking care of your images and containers behind the scenes, whereas the client acts as the intermediary between you
      and the RESTful API.

      The private Docker registry is a service that stores Docker images. These can be requested from any Docker daemon that has the relevant access.
      This registry is on an internal network and isn’t publicly accessible, so it’s considered private.
      Your host machine will typically sit on a private network. The Docker daemon will call out to the internet to retrieve images, if requested.
      The Docker Hub is a public registry run by Docker, Inc. Other public registries can also exist on the internet, and your Docker daemon can interact with them.


### - Technique 1:
    + Problem:
      You want to make multiple Docker container services available on a port from your host machine.

    + Solution:
      Use Docker’s -p flag to map a container’s port to your host machine.
      In this example we’re going to use the tutum-wordpress image. Let’s say you want
      to run two of these on your host machine to serve different blogs.
      Because a number of people have wanted to do this before, someone has prepared
      an image that anyone can acquire and start up. To obtain images from external
      loca- tions, you can use the docker pull command. By default,
      images will be downloaded from the Docker Hub:

      1- docker pull tutum/wordpress
      To run the first blog, use the following command:
      2- docker run -d -p 10001:80 --name blog1 tutum/wordpress

      This docker run command runs the container as a daemon (-d) with the publish
      flag (-p). It identifies the host port (10001) to map to the container
      port (80) and gives the container a name to identify it
      (--name blog1 tutum/wordpress).

      You can do the same for the second blog:
      3- docker run -d -p 10002:80 --name blog2 tutum/wordpress

      4- docker ps | grep blog
      5- docker rm -f blog1 blog2 (remove them both)

    `TIP`
    It can be easy to forget which port is the host’s and which port is the container’s
    when using the -p flag. We think of it as being like reading a sentence from left to right.
    The user connects to the host (-p) and that host port is passed to the container port (host_port:container_port).
    It’s also the same format as SSH’s port-forwarding commands, if you’re familiar with them.

### - Technique 2:
    + Problem :
      You want to allow communication between containers for internal purposes.

    + Solution :
      Employ user-defined networks to enable containers to communicate with each other.
      User-defined networks are simple and flexible. We have a couple of WordPress blogs running
      in containers from the previous technique, so let’s take a look at how we can reach them
      from another container (rather than from the outside world, which you’ve seen already).


      First you’ll need to create a user-defined network:
      1- docker network create my_network

      This command creates a new virtual network living on your machine that you can use to manage
      container communication. By default, all containers that you connect to this network will
      be able to see each other by their names.

      Next, assuming that you still have the blog1 and blog2 containers running from the previous
      technique, you can connect one of them to your new network on the fly.
      2- docker network connect my_network blog1

      Checking
      - Finally, you can start up a new container, explicitly specifying the network,
      and see if you can retrieve the first five lines of HTML from the landing page of the blog.

      run ubuntu container and add it to the network (my-network)
      3- docker run -it --network my_network ubuntu:16.04 bash
      -> root@06d6282d32a5:/# (you are coonected to ubuntu container)
      4- apt update && apt install -y curl
      5- curl -sSL blog1 | head -n5

      `TIP`
       TIP Giving containers names is very useful for assigning memorable hostnames you can later refer to,
       but it’s not strictly necessary—if connections are only outgoing, then you probably won’t need to look up the container.
       If you find you do want to look up the host and haven’t assigned a name, you can resort to using the short image ID
       as listed in the terminal prompt (unless it has been overridden with a hostname) or in the docker ps output.

       `DISCUSSION`
       You can use this technique to set up any number of containers in a cluster on their own private network,
       only requiring that the containers have some way of discovering each other’s names.
       In technique 80 you’ll see a method of doing this that integrates well with Docker networks.
       Meanwhile, the next technique will start much smaller, demonstrating some benefits of being able
       to make an explicit connection between a single container and the service it provides.
       One additional point of note is the interesting final state of the blog1 container.
       All containers are connected to the Docker bridge network by default,
       so when we asked for it to join my_network, it did so in addition to the network it was already on


### - Technique 3:
       In the previous technique you saw how to get containers to communicate with user- defined networks. But there’s an older method of declaring container communication— Docker’s link flag. This isn’t the recommended way of working anymore, but it has been part of Docker for a long time, and it’s worth being aware of in case you encounter it in the wild.
       + PROBLEM :
         You want to allow communication between containers without using user-defined networks.

       + SOLUTION :
         Use Docker’s linking functionality to allow the containers to communicate with each other.
         Taking up the torch of the WordPress example, we’re going to separate the MySQL database tier
         from the WordPress container, and link these to each other without port
         configuration or creating a network. Figure below gives an overview of the final state.

![connect](./static/connect-containers.png)

        ++ NOTE Why bother with linking if you can already expose ports to the host and use that?
           Linking allows you to encapsulate and define the relationships between containers without exposing services
           to the host’s network (and potentially, to the outside world). You might want to do this for security reasons, for example.

        1- docker run --name wp-mysql -e MYSQL_ROOT_PASSWORD=yoursecretpassword -d mysql
        2- docker logs wp-mysql (check if mysql container ready to receive connections)
        3- docker run --name wordpress --link wp-mysql:mysql -p 10003:80 -d  wordpress

        4- http://localhost:10002 (check in the browser (if you don't know the port of wordpress run docker ps))

        + By splitting your workload into separate containers, you’ve taken a step toward creating
          a microservices architecture for your application. In this case you could perform work on the MySQL
          container while leaving the WordPress container untouched, or vice versa. This fine-grained control
          over running services is one of the key opera- tional benefits of a microservices architecture.

### - Technique 4:
    - Setting up a local Docker registry
    + PROBLEM :
      You want a way to host your images locally.
    + SOLUTION
      Set up a registry server on your local network. Simply issue the following command on a machine with plenty of disk space:
      1- docker run -d -p 5000:5000 -v $HOME/registry:/var/lib/registry registry:2

      - This command makes the registry available on port 5000 of the Docker host
        (-p 5000:5000). With the -v flag, it makes the registry folder on your host
        (/var/lib/registry) available in the container as $HOME/registry.
        The registry’s files will therefore be stored on the host in the /var/lib/registry folder.

      - On all of the machines that you want to access this registry, add the following to your daemon options
        (where HOSTNAME is the hostname or IP address of your new reg- istry server):
        --insecure-registry HOSTNAME (see appendix B for details on how to do this).
        You can now issue the following command: docker push HOSTNAME:5000/ image:tag.

      `TIP`
       As you can see, the most basic level of configuration for a local registry, with all data stored
       in the $HOME/registry directory, is simple. If you wanted to scale up or make it more robust,
       the repository on GitHub (https://github.com/docker/distribution/ blob/v2.2.1/docs/storagedrivers.md)
       outlines some options, like storing data in Amazon S3.

### - Technique 5:
    PROBLEM :
    You want to find an application or tool as a Docker image and try it out.
    SOLUTION :
    Use the docker search command to find the image to pull, and then run it.

    Let’s say you’re interested in playing with Node.js. In the following example we
    searched for images matching “node” with the docker search command:

    1- docker search node
    2- docker pull node (download docker image with name node)
![docker-hub](./static/docker-hub.png)


### - Technique 6:

    If you’ve ever developed any kind of software, you’ve likely exclaimed,
    “I’m sure it was working before!” at least once. Perhaps your language was not as sober as this.
    The inability to restore a system to a known good (or maybe only “better”) state when you’re hurriedly
    hacking away at code to hit a deadline or fix a bug is the cause of many bro- ken keyboards.

    Source control has helped significantly with this, but there are two problems in this particular case:

    - The source may not reflect the state of your “working” environment’s filesystem.
    - You may not be willing to commit the code yet.

    The first problem is more significant than the second. Although modern source control tools
    like Git can easily create local throwaway branches, capturing the state of your entire development
    filesystem isn’t the purpose of source control.

    Docker provides a cheap and quick way to store the state of your container’s development filesystem
    through its commit functionality, and that’s what we’re going to explore here.

    + PROBLEM :
    You want to save the state of your development environment.

    + SOLUTION :
    Regularly commit your container so you can recover state at that point.
    Let’s imagine you want to make a change to your to-do application.
    The CEO of ToDoCorp isn’t happy and wants the title of the browser to show
    “ToDoCorp’s ToDo App” instead of “Swarm+React - TodoMVC.”
    You’re not sure how to achieve this, so you probably want to fire up your applica-
    tion and experiment by changing files to see what happens.

    1- docker run -d -p 8000:8000 --name todobug1 dockerinpractice/todoapp (in the background run the image)
    2 docker exec -i -t todobug1 /bin/bash - (get into the application folder inside docker container)

    3- install some tools
        apt-get update
        apt-get install vim

    4- vi local.html (make change)
    5- docker commit todobug1
    6- docker run -p 8001:8000 b0e9352771d1

### - Technique 7:
     + PROBLEM :
       Downloading docker images and pushing them to my repo on docker hub
     + Solution :
       1- docker pull debian:wheezy
       2- docker tag debian:wheezy mdrahali/debian:mywheezy1
       3- docker push mdrahali/debian:mywheezy1

    + PROBLEM :
      make an image smaller
    + Solution :
      1- docker run -ti --name smaller --entrypoint /bin/bash \
         dockerinpractice/log-cleaner
      2- apt-get autoremove
      3- apt-get clean


### - Clean up Docker:

    docker container stop $(docker container ls -aq) -> remove all containers
    docker image prune
    docker container prune
    docker volume prune
    docker network prune
    docker rmi -f $(docker images -a -q)

### - Other commands :
    + docker build --no-cache .
    + docker inspect ubuntu | head (for images)
    + docker inspect --format '{{.NetworkSettings.IPAddress}}' 555263b8906b
       or docker inspect 555263b8906b | grep "IPAddress" (Gor IP Address of the Container)

    + docker inspect 555263b8906b (for containers)
    + history | grep name (searching for `name` in my previous commands)

    + sudo addgroup -a username docker (running docker commands without sudo)
    + docker ps -a -q | xargs --no-run-if-empty
    + docker rm -f

### - Docker Security :

    Docker access and what it means
    You may be wondering what sort of damage a user can do if they can run Docker. As a simple example, the following command (don’t run it!) would delete all the binaries in /sbin on your host machine (if you took out the bogus --donotrunme flag):
    $ docker run --donotrunme -v /sbin:/sbin busybox rm -rf /sbin

    SOLUTION
    Drop the capabilities available to the container by using the --drop-cap flag.

![](./static/linux_cap1.png)
![](./static/linux_cap2.png)
![](./static/linux_cap3.png)

    + One extreme approach is to remove all the capabilities that are switched
      on in Docker by default from the container, and see what stops working.
      Here we start up a bash shell with the capabilities that are enabled
      by default removed:

        $ docker run -ti --cap-drop=CHOWN --cap-drop=DAC_OVERRIDE \
        --cap-drop=FSETID --cap-drop=FOWNER --cap-drop=KILL --cap-drop=MKNOD \
        --cap-drop=NET_RAW --cap-drop=SETGID --cap-drop=SETUID \
        --cap-drop=SETFCAP --cap-drop=SETPCAP --cap-drop=NET_BIND_SERVICE \
        --cap-drop=SYS_CHROOT --cap-drop=AUDIT_WRITE debian /bin/bash

    TIP
    If you want to enable or disable all capabilities, you can use all instead
    of a specific capability, such as docker run -ti --cap-drop=all ubuntu bash.

### - Technique 8 - HTTP auth on your Docker instance :

    + This technique combines those two: you’ll be able to access
      your daemon remotely and view the responses.

    PROBLEM
    You’d like basic authentication with network access available on your Docker daemon.

    SOLUTION
    Use HTTP authentication to share your Docker daemon with others temporarily.

    NOTE
    This discussion assumes your Docker daemon is using Docker’s default
    Unix socket method of access in /var/run/docker.sock.

    $ docker run -d -p 2375:2375 -v /var/run:/var/run mdrahali/docker-authenticate
    $ curl http://username:password@localhost:2375/info


    # Access remotly machine-to-machine

    $ docker run -d --name docker-authenticate-client \
          -p 127.0.0.1:12375:12375 \
          dockerinpractice/docker-authenticate-client \
          192.168.1.5:2375 username:password


    $ docker -H localhost:12375 ps

    Note
    that localhost or 127.0.0.1 won’t work for specifying the other end of the authenticated
    connection—if you want to try it out on one host, you must use ip addr
    to identify an external IP address for your machine.

### - Technique 9 - Securing your Docker API

    In this technique we’ll show how you can open up your Docker server to others over a TCP port
    while at the same time ensuring that only trusted clients can connect. This is achieved
    by creating a secret key that only trusted hosts will be given. As long as that trusted
    key remains a secret between the server and client machines, the Docker server should remain secure.

    PROBLEM
    You want your Docker API to be served securely over a port.
    SOLUTION
    Create a self-signed certificate, and run the Docker daemon with the --tls-verify flag.
    This method of security depends on so-called key files being created on the server.
    These files are created using special tools that ensure they’re difficult to copy
    if you don’t have the server key.

    + Figure below gives an overview of this how this works :

![](./dockerd_remote_access/key_setup.png)

    SETTING UP THE DOCKER SERVER CERTIFICATE
    First you create the certificates and keys.
    Generating keys requires the OpenSSL package

![](./dockerd_remote_access/keys_setup_commands1.png)
![](./dockerd_remote_access/keys_setup_commands2.png)

    $ On the client host, create the Docker configuration folder in /etc as you did earlier:
    $ user@client:~$ sudo su
    $ root@client:~$ mkdir -p /etc/docker

    Then SCP the files from the server to the client. Make sure you replace “client” in the following commands with the hostname of your client machine. Also make sure that all the files are readable by the user that will run the docker command on the client.
    user@server:~$ sudo su
    root@server:~$ scp /etc/docker/ca.pem client:/etc/docker
    roost@server:~$ scp /etc/docker/cert.pem client:/etc/docker
    root@server:~$ scp /etc/docker/key.pem client:/etc/docker

    Then connect with the credentials, which should return useful output:
    + root@client~: docker --tlsverify --tlscacert=/etc/docker/ca.pem \
    --tlscert=/etc/docker/cert.pem --tlskey=/etc/docker/key.pem \
    -H myserver.localdomain:2376 info

### - Technique 10 - Monitoring and logging

    it’s reasonable for applications you write yourself to log to syslog.
    Unfortunately, this will stop working once you containerize your application
    (because there’s no syslog daemon in containers, by default). If you do decide
    to start a syslog daemon in all of your containers, you’ll need to go to each
    individual container to retrieve the logs.

    PROBLEM
    You want to capture syslogs centrally on your Docker host.

    SOLUTION
    Run a service container that acts as the syslog daemon for Docker containers.
    The basic idea of this technique is to run a service container that runs a syslog daemon,
    and share the logging touchpoint (/dev/log) via the host’s filesystem.
    The log itself can be retrieved by querying the syslog Docker container,
    and it’s stored in a volume.

    Figure 15.1 illustrates how /tmp/syslogdev on the host’s filesystem can be used as a
    touchpoint for all syslogging taking place on containers on the host.
    The logging con- tainers mount and write their syslog to that location,
    and the syslogger container col- lates all those inputs.

    TIP
    The syslog daemon is a process that runs on a server, collecting and man- aging messages
    sent to a central file, which is normally a Unix domain socket. It generally uses /dev/log
    as a file to receive log messages, and it logs out to /var/log/syslog.

![](./monitoring_logging/syslogger/centralise_logging.png)

![](./monitoring_logging/syslogger/syslogger_container.png)

    # Build and Run
    $ docker build -t syslogger .
    $ docker run --name syslogger -d -v /tmp/syslogdev:/dev syslogger

    For this demonstration, we’re going to start up 100 daemon containers that log
    their own starting order from 0 to 100 to the syslog, using the logger command.
    Then you’ll be able to see those messages by running a docker exec on the host
    to look at the syslogger container’s syslog file.

    for d in {1..100}
    do
        docker run -d -v /tmp/syslogdev/log:/dev/log ubuntu logger hello_$d
    done

    #see logs of 100 containerss

    $ docker exec -ti syslogger tail -f /var/log/syslog


    You can use a modified exec command to archive these syslogs if you wish.
    For exam- ple, you could run the following command to get all logs for hour 11 on May 25th
    archived to a compressed file:

    $ docker exec syslogger bash -c "cat /var/log/syslog | \
    grep '^May 25 11'" | xz - > /var/log/archive/May25_11.log.xz

### - Technique 11 - Monitoring containers with cAdvisor
    PROBLEM
    You want to monitor the performance of your containers.
    SOLUTION
    Use cAdvisor as a monitoring tool.
    cAdvisor is a tool developed by Google for monitoring containers. It’s open- sourced on GitHub at https://github.com/google/cadvisor.
    cAdvisor runs as a daemon that collects performance data on running containers. Among other things, it tracks
    + Resource isolation parameters
    + Historical resource usage
    + Network statistics

    #run cAdvisor

![](./monitoring_logging/monitoring_usage_containers/cAdvisor.png)

    $   docker run \
        --volume /:/rootfs:ro \
        --volume /var/run:/var/run:rw \
        --volume /sys:/sys:ro \
        --volume /var/lib/docker/:/var/lib/docker:ro \
        -p 8080:8080 -d --name cadvisor \
        --restart on-failure:10 google/cadvisor

    Once you’ve started the image, you can visit http://localhost:8080 with your browser
    to start examining the data output. There’s information about the host, but by click- ing
    on the Docker Containers link at the top of the homepage, you’ll be able to exam- ine graphs of CPU,
    memory, and other historical data. Just click on the running containers listed under
    the Subcontainers heading.

### - Technique 12 - Restricting the cores a container can execute on

    By default, Docker allows containers to execute on any cores on your machine.
    Con- tainers with a single process and thread will obviously only be able to max out one core,
    but multithreaded programs in a container (or multiple single-threaded pro- grams) will be able
    to use all your CPU cores. You might want to change this behavior if you have a container that’s
    more important than others—it’s not ideal for customer- facing applications to have to fight for
    the CPU every time your internal daily reports run. You could also use this technique to prevent
    runaway containers from locking you out of SSH to a server.

    PROBLEM
    You want a container to have a minimum CPU allocation, have a hard limit on CPU consumption,
    or otherwise want to restrict the cores a container can run on.

    SOLUTION
    Use the --cpuset-cpus option to reserve CPU cores for your container.
    To properly explore the --cpuset-cpus option, you’ll need to follow this
    tech- nique on a computer with multiple cores. This may not be the case
    if you’re using a cloud machine.

    TIP
    Older versions of Docker used the flag --cpuset, which is now depre-
    cated. If you can’t get --cpuset-cpus to work, try using --cpuset instead.

    If you now run htop, you’ll probably see that none of your cores are busy. To simu- late some load inside a couple of containers, run the following command in two dif- ferent terminals:
    $ docker run ubuntu:14.04 sh -c 'cat /dev/zero >/dev/null'
    Looking back at htop, you should see that two of your cores now show 100% use. To restrict this to one core, docker kill the previous containers and then run the follow- ing command in two terminals:
    $ docker run --cpuset-cpus=0 ubuntu:14.04 sh -c 'cat /dev/zero >/dev/null'
    Now htop will show that only your first core is being used by these containers.

### - Technique 13 -  Giving important containers more CPU :
    Containers on a host will normally share CPU usage equally when they compete for it.
    cycles, robbing a web server on the machine of the ability to serve end users. PROBLEM

    SOLUTION
    Use the -c/--cpu-shares argument to the docker run command to define the rela- tive share of CPU usage.
    When a container is started up, it’s given a number (1024 by default) of CPU shares. When only one process is running,
    it will have access to 100% of the CPU if necessary, no matter how many CPU shares it has access to.
    It’s only when competing with other containers for CPU that the number is used.

    Imagine we have three containers (A, B, and C) all trying to use all available CPU resources:
    + If they’ve all been given equal CPU shares, they will each be allocated one third of the CPU.
    + If A and B are given 512 and C is given 1024, C will get half of the CPU, and A and B will get a quarter each.
    + If A is given 10, B is given 100, and C is given 1000, A will get under 1% of the available CPU resources and will only be able to do anything resource-hungry if B and C are idle.

    - All of this assumes that your containers can use all cores on your machine (or that you only have one core).
      Docker will spread the load from containers across all cores where possible. If you have two containers
      running single-threaded applications on a two-core machine, there’s obviously no way to apply relative weighting
      while maxi- mally using the available resources. Each container will be given a core to execute on, regardless of its weight.

    # run a container without cpu

    $ docker run --cpuset-cpus=0 -c 10000 ubuntu:14.04 \
    sh -c 'cat /dev/zero > /dev/null' &

    $ docker run --cpuset-cpus=0 -c 1 -it ubuntu:14.04 bash

    # error minimum cpu-shares for a container is 2

### - Technique 14 - Limiting the memory usage of a container

    When you run a container, Docker will allow it to allocate as much memory from the host as possible.
    Usually this is desirable (and a big advantage over virtual machines, which have an inflexible
    way of allocating memory). But sometimes applications can go out of control, allocate too much
    memory, and bring a machine grinding to a halt as it starts swapping. It’s annoying,
    and it’s happened to us many times in the past. We want a way of limiting a container’s
    memory consumption to prevent this.

    PROBLEM
    You want to be able to limit the memory consumption of a container.
    SOLUTION
    Use the -m/--memory parameter to docker run.

    If you’re running Ubuntu, chances are that you don’t have the memory-limiting
    capability enabled by default. To check, run docker info. If one of the lines in the output is a warning
    about No swap limit support, there’s unfortunately some setup work you need to do.
    Be aware that making these changes can have performance implications on your machine for all applications—see
    the Ubuntu installation docu- mentation for more information (http://docs.docker.com/engine/installation/ubuntulinux/#adjust-memory-and-swap-accounting).
    In short, you need to indicate to the kernel at boot that you want these limits to be available.
    To do this, you’ll need to alter /etc/default/grub as follows. If GRUB_CMDLINE _LINUX already has values in it,
    add the new ones at the end:

    -GRUB_CMDLINE_LINUX=""
    +GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"

    - You now need to run sudo update-grub and restart your computer. Running docker info should no longer give you the warning, and you’re now ready to proceed with the main attraction.

![](./static/memory_limiting.png)

    There’s a gotcha with this kind of constraint. To demonstrate this, we’ll use the jess/ stress image,
    which contains stress, a tool designed for testing the limits of a system.
    TIP
    Jess/stress is a helpful image for testing any resource limits you impose on your container.
    Try out the previous techniques with this image if you want to experiment more.
    If you run the following command, you might be surprised to see that it doesn’t exit immediately:

    $ docker run -m 100m jess/stress --vm 1 --vm-bytes 150M --vm-hang 0

    You’ve asked Docker to limit the container to 100 MB, and you’ve instructed stress to take up 150 MB.
    You can verify that stress is operating as expected by running this command:

    $ docker top <container_id> -eo pid,vsz,args

    The size column is in KB and shows that your container is indeed taking about 150 MB of memory,
    raising the question of why it hasn’t been killed. It turns out that Docker double-reserves memory—half
    for physical memory and half to swap. If you try the following command, the container will terminate immediately:

    $ docker run -m 100m jess/stress --vm 1 --vm-bytes 250M --vm-hang 0

    ### - Technique 15 - Using Docker to run cron jobs

    PROBLEM
    You want your cron jobs to be centrally managed and auto-updated.

    SOLUTION
    Pull and run your cron job scripts as Docker containers.

    At this point you may be wondering why it’s worth bothering with this, if you already have a solution that works.
    Here are some advantages of using Docker as the delivery mechanism:
    - Whenever a job is run, the job will update itself to the latest version from the central location.
    - Your crontab files become much simpler, because the script and the code are encapsulated in a Docker image.
    - For larger or more complex changes, only the deltas of the Docker image need be pulled, speeding up delivery and updates.
    - You don’t have to maintain the code or binaries on the machine itself.
    - You can combine Docker with other techniques, such as logging output to the sys- log, to simplify and centralize
      the management of these administration services.

![](./static/crontab_docker_registry.png)
![](./static/cronjob.png)

    # Log cleaner crontab entry with alerting on error

    00*** \
    (IMG=dockerinpractice/log_cleaner && \
    docker pull $IMG && \
    docker run -v /var/log/myapplogs:/log_dir $IMG 1) \ || my_alert_command 'log_cleaner failed'

    0 0 * * * IMG=dockerinpractice/log_cleaner && docker pull $IMG && docker run -v /var/log/myapplogs:/log_dir $IMG 1
    0 0 * * * (IMG=dockerinpractice/log_cleaner && docker pull $IMG && docker run -v /var/log/myapplogs:/log_dir $IMG 1) || my_alert_command 'log_cleaner failed'


### - Technique 15 - backups

    If you’ve ever run a transactional system, you’ll know that when things go wrong,
    the ability to infer the state of the system at the time of the problem is essential
    for a root- cause analysis.

    Usually this is done through a combination of means:
    - Analysis of application logs
    - Database forensics (determining the state of data at a given point in time)
    - Build history analysis (working out what code and config was running on the
        service at a given point in time)
    - Live system analysis (for example, did anyone log onto the box and change
        something?)

    PROBLEM
    You want to keep backups of Docker containers.
    SOLUTION
    Commit the containers while running, and push the resulting image as a dedicated Docker repository.

![](./static/backup.png)

    # Setup a local registry on port 0.0.0.0:5000

    $ docker run -d -p 5000:5000 -v $HOME/registry:/var/lib/registry registry:2
    docker pull tutum/wordpress
    $ DATE=$(date +%Y%m%d_%H%M%S)
    $ TAG="0.0.0.0:5000/wordpress_backup:$(hostname -s)_${DATE}"
    $ docker ps -> names -> competent_gauss
    $ docker commit -m="$DATE" -a="Backup Admin" competent_gauss $TAG

    check weather your image is in the registry or nah
    $ docker images

    curl -X GET http://0.0.0.0:5000/v2/_catalog

    WARNING
    This technique will pause the container while it runs, effectively taking it out of service.
    Your service should either tolerate outages, or you should have other nodes running at
    the time that can service requests in a load-balanced fashion.

    ++ The backups only push the differences between the base image and the state of the container
       at the time it’s backed up, and the backups are staggered to ensure that the service stays
       up on at least one host. The registry server only stores one copy of the base image and
       the diffs at each commit point, saving disk space.

### - Technique 16 - Disabling the OOM killer :

    - The “OOM killer” sounds like a bad horror film or severe disease, but it is in fact a thread within the Linux operating
      system kernel that decides what to do when the host is running out of memory. After the operating system has run out of hardware memory,
      used up any available swap space, and removed any cached files out of mem- ory, it invokes the OOM killer to decide which processes
      should be killed off.

    PROBLEM
    You want to prevent containers from being killed by the OOM killer.
    SOLUTION
    Use the --oom-kill-disable flag when starting your container.
    Solving this challenge is as simple as adding a flag to your Docker container.
    But as is often the case, the full story isn’t that simple.
    The following listing shows how you disable the OOM killer for a container:

    $ docker run -ti --oom-kill-disable ubuntu sleep 1

    WARNING: Disabling the OOM killer on containers without setting a '-m/--memory' limit may be dangerous.
    WARNING: OOM killer is disabled for the container, but no memory limit is set, this can result in the system running out of resources.

    % best practice :
    $ docker run -ti --oom-kill-disable --memory 4M ubuntu sleep 1


    NOTE
    The minimum amount of memory you can allocate is 4M, where the “M” stands for megabytes.
    You can also allocate by “G” for gigabytes.

    # check if your container is OOM-KILLER - take any container id

    $ docker inspect 3ef3e1668397 | grep OOMKilled


###  debugging :

    # if you want to check th error behind a command failure

    $ docker pull image/logger
    error
    $ echo $?
    134

    - an exit code of 0 means the call was successful, and a nonzero code indicates an error
      or exceptional condition of some kind.
