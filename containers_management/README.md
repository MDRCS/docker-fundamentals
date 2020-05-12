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


### - Technique 2 - In this technique we’ll show you how to achieve local orchestration functionality that’s similar to docker-compose using systemd :

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


