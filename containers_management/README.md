### + Containers Management

### - Technique 1 - Managing your host’s containers with systemd :

    + PROBLEM :
    You want to manage the running of Docker container services on your host.

    + SOLUTION :
    Use systemd to manage your container services.
    systemd is a system-management daemon that replaced SysV init scripts in Fedora some time ago. It manages services on your system—everything from mount points to processes to one-shot scripts—as individual “units.”

    + install systemd or use vagrant VM

    # Vagrant VM
    1- mkdir centos7_docker/
    2- cd centos7_docker/
    3- vagrant init williamyeh/centos7-docker
    4- vagrant up
    5- vagrant ssh

    $ sudo su -
    $ systemctl status
    $ cd /etc/systemd/system/

    #todo.service
        [Unit]
        Description=Simple ToDo Application
        After=docker.service
        Requires=docker.service
        [Service]
        TimeoutStartSec=1200
        Restart=always
        ExecStartPre=/bin/bash \
        -c '/usr/bin/docker rm -f todo || /bin/true'
        ExecStartPre=/usr/bin/docker pull mdrahali/todo_app
        ExecStart=/usr/bin/docker run --name todo \
        -p 8000:8000 mdrahali/todo_app
        ExecStop=/usr/bin/docker rm -f todo
        [Install]
        WantedBy=multi-user.target

    NOTE
    Docker doesn’t set any container restart policies by default,
    but be aware that any you set will conflict with most process managers.
    Don’t set restart policies if you’re using a process manager.

    $ check password for root ->  cat /etc/group | grep root
    $ systemctl enable /etc/systemd/system/todo.service

    $ systemctl start todo.service
    $ systemctl status todo.service


### - Technique 2 :

    NOTE
    If you run into trouble with this technique, you may need to upgrade your version of Docker.
    Version 1.7.0 or greater should work fine.

    + PROBLEM :
    You want to manage more complex container orchestration on one host in production.

    + SOLUTION :
    Use systemd with dependent services to manage your containers.

    A key difference here is that rather than the SQLite service being treated as a single monolithic entity, each container is a discrete entity. In this sce- nario, the SQLite proxy can be stopped independently of the SQLite server.

![](./systemd/systemd-docker.png)

    $ touch /etc/systemd/system/sqliteserver.service

    [Unit]
    Description=SQLite Docker Server
    After=docker.service
    Requires=docker.service
    [Service]
    TimeoutStartSec=1200
    Restart=always
    ExecStartPre=-/bin/touch /tmp/sqlitedbs/test
    ExecStartPre=-/bin/touch /tmp/sqlitedbs/live
    ExecStartPre=/bin/bash \
    -c '/usr/bin/docker kill sqliteserver || /bin/true'
    ExecStartPre=/bin/bash \
    -c '/usr/bin/docker rm -f sqliteserver || /bin/true'
    ExecStartPre=/usr/bin/docker \
    pull dockerinpractice/docker-compose-sqlite
    ExecStart=/usr/bin/docker run --name sqliteserver \
    -v /tmp/sqlitedbs/test:/opt/sqlite/db \
    dockerinpractice/docker-compose-sqlite /bin/bash -c \
    'socat TCP-L:12345,fork,reuseaddr \
    EXEC:"sqlite3 /opt/sqlite/db",pty'
    ExecStop=/usr/bin/docker rm -f sqliteserver

    [Install]
    WantedBy=multi-user.target

    $ touch /etc/systemd/system/sqliteproxy.service

    [Unit]
    Description=SQLite Docker Proxy
    After=sqliteserver.service
    Requires=sqliteserver.service
    [Service]
    TimeoutStartSec=1200
    Restart=always
    ExecStartPre=/bin/bash -c '/usr/bin/docker kill sqliteproxy || /bin/true'
    ExecStartPre=/bin/bash -c '/usr/bin/docker rm -f sqliteproxy || /bin/true'
    ExecStartPre=/usr/bin/docker pull dockerinpractice/docker-compose-sqlite
    ExecStart=/usr/bin/docker run --name sqliteproxy \
    -p 12346:12346 --link sqliteserver:sqliteserver  dockerinpractice/docker-compose-sqlite /bin/bash \
    -c 'socat TCP-L:12346,fork,reuseaddr TCP:sqliteserver:12345'
    ExecStop=/usr/bin/docker rm -f sqliteproxy

    [Install]
    WantedBy=multi-user.target


    $ sudo systemctl enable /etc/systemd/system/sqliteserver.service
    $ sudo systemctl enable /etc/systemd/system/sqliteproxy.service

    # Startup

    #Disable Docker (docker-main.repo) and enable CentOS (CentOS-Base.repo)
    - /etc/yum.repos.d
    - vi docker-main.repo -> change enable=1 to 0
    - vi CentOS-Base.repo -> change enable=0 to 1
    - yum -y install telnet

    [NOTE] -> (https://forums.centos.org/viewtopic.php?t=61460)
    After installing you should get back docker to 1 and CentOS to 0.

    systemctl start telnet.socket
    systemctl enable telnet.socket
    iptables -I INPUT -p tcp --dport 12346 -j ACCEPT
    systemctl daemon-reload

    - sudo systemctl start sqliteproxy.service
    - netstat -tapnl | grep 443
        tcp        0      0 10.0.2.15:46800         `104.18.124.25`:443       ESTABLISHED 896/dockerd
    - telnet 104.18.124.25 12346


### - Technique 3 - Manual multi-host Docker with Helios

    + PROBLEM :
    You want to be able to provision multiple Docker hosts with containers but retain manual control over what runs where.

    + SOLUTION :
    Use the Helios tool from Spotify to precisely manage containers on other hosts.
    Helios is the tool Spotify currently uses to manage their servers in production,
    and it has the pleasing property of being both easy to get started with and stable
    (as you’d hope). Helios allows you to manage the deployment of Docker containers across multiple hosts.
    It gives you a single command-line interface that you can use to specify what you want to run and where to run it,
    as well as the ability to take a look at the cur- rent state of play.

![helios](./multi-host-docker/helios.png)

    As you can see, there’s only one additional service required when running Helios: Zookeeper.
    Helios uses Zookeeper to track the state of all of your hosts and as a communication channel between the masters and agents.

    TIP
    Zookeeper is a lightweight distributed database written in Java that’s optimized for storing configuration information.
    It’s part of the Apache suite of open source software products. It’s similar in functionality to etcd.

    $ docker run --name zookeeper -d jplock/zookeeper:3.4.6
    $ docker inspect -f '{{.NetworkSettings.IPAddress}}' zookeeper

    NOTE
    When starting a Zookeeper instance on its own node, you’ll want to expose ports to make it
    accessible to other hosts and use volumes to persist data. Take a look at the Dockerfile
    on the Docker Hub for details about which ports and folders you should use
    https://hub.docker.com/r/jplock/zookeeper/dockerfile/

    + You can inspect the data Zookeeper has stored by using the zkCli.sh tool,

    $ docker exec -it zookeeper bin/zkCli.sh -> enter
    $ ls /

    + Nothing’s running against Zookeeper yet, so the only thing currently being stored
      is some internal Zookeeper information. Leave this prompt open, and we’ll revisit it as we progress.

    + Helios itself is split into three parts:
    - The master—This is used as an interface for making changes in Zookeeper.
    - The agent—This runs on every Docker host, starts and stops containers based on
    Zookeeper, and reports state back.
    - The command-line tools—These are used to make requests to the master.

![helios-host](./multi-host-docker/helios-hos.png)

    -- We need to run the master while specifying the IP address of the Zookeeper node we started earlier.
    1- IMG=dockerinpractice/docker-helios
    2- docker run -d --name hmaster $IMG helios-master --zk 172.17.0.2
    3- docker logs --tail=3 hmaster
    4- docker inspect -f '{{.NetworkSettings.IPAddress}}' hmaster

    # Now let’s see what’s new in Zookeeper:

    $ ls /
    $ ls /status/masters
    $ ls /status/hosts

    -- Unfortunately we don’t have any hosts yet.
       Let’s solve this by starting up an agent that will use the current
       host’s Docker socket to start containers on:

    $ docker run -v /var/run/docker.sock:/var/run/docker.sock -d --name hagent \
      dockerinpractice/docker-helios helios-agent --zk 172.17.0.2

    $ docker logs --tail=3 hagent
    $ docker inspect -f '{{.NetworkSettings.IPAddress}}' hagent

    master 172.17.0.3
    host 172.17.0.4

    # Now let’s see what’s new in Zookeeper Again:
    $ ls /status/hosts
    $ ls /status/hosts/ae45a8e70086
    $ get /status/hosts/ae45a8e70086/agentinfo

    NOTE
    When running on multiple hosts, you’ll want to pass --name $(host- name -f)
    as an argument to both the Helios master and agent. You’ll also need to expose ports
    5801 and 5802 for the master and 5803 and 5804 for the agent.

    master -> IP 172.17.0.3
    Note - 5801 (master port)
    + that the command-line interface needs to be pointed at the Helios master rather than Zookeeper.

    $ alias helios="docker run -i --rm dockerinpractice/docker-helios \
      helios -z http://172.17.0.3:5801"


    $ helios create -p nc=8080:8080 netcat:v1 ubuntu:14.04.2 -- \
      sh -c 'echo hello | nc -l 8080'

    $ helios jobs

    -- You can use helios hosts to list hosts available for job deployment,
       and then actu- ally perform the deployment with helios deploy.
       The helios status command then shows us that the job has successfully started:

    $ helios hosts
    $ helios deploy netcat:v1 ae45a8e70086
    $ helios status

    -- Of course, we now want to verify that the service works:
    $ curl localhost:8080
    $ helios status

    -- clearup
    $ helios undeploy -a --yes netcat:v1
    $ helios remove --yes netcat:v1

    ++ this simplicity comes at a cost once you move to more advanced deployment
       scenarios—features like resource limits, dynamic scaling,
       and so on are currently miss- ing, so you may find yourself reinventing parts of tools like Kubernetes
