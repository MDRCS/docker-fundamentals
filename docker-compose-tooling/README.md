### Technique 1 :

    - PROBLEM :
    You want to coordinate connected containers on your host machine.

    - SOLUTION :
    Use Docker Compose, a tool for defining and running multicontainer Docker applications.
    The central idea is that rather than wiring up container startup commands with complex shell scripts or Makefiles, you declare the application’s startup configuration, and then bring the application up with a single, simple command.

    + Check version of docker compose:  docker-compose --version

![simple-server](./echo-server/simple-echo-server.png)

    The -l 2000 arguments instruct ncat to listen on port 2000, and -k tells it to accept multiple client
    connections simultaneously and to continue running after clients close their connections so more clients can connect.
    The final arguments, --exec /bin/cat, will make ncat run /bin/cat for any incoming connections and forward any data coming
    over the connection to the running program.

    1- docker build -t server .
    2- docker build -t client .


    :TIP
    If you get an error when starting docker-compose that looks like “Couldn’t connect
    to Docker daemon at http+unix://var/run/docker.sock— is it running?”
    the issue may be that you need to run it with sudo.

### Technique 2 :

    SQLite doesn’t come with any concept of a TCP server by default. By building on previous techniques, this technique provides you with a means of achieving TCP server functionality using Docker Compose.
    Specifically, it builds on these previously covered tools and concepts:
    1- Volumes
    2- Proxying with socat
    3- Docker Compose


    PROBLEM
    You want to efficiently develop a complex application referencing external data on
    your host using Docker.
    SOLUTION

    At a high level there are two running Docker containers:
    + one responsible for executing SQLite clients,
    + and the other for proxying separate TCP connections to these clients.
      Note that the container executing SQLite isn’t exposed to the host;
      the proxy container achieves that. This kind of separation of responsibility into discrete units is a common feature of microservices architectures.

![lala](./sqlite_server/sqlite_server_howworks.png)

    It uses socat to create a sqlite server accessible on localhost:12346.

![lala](./sqlite_server/dockerfile.png)
![lala](./sqlite_server/docker-compose.png)

    The socat process in the server container will listen on port 12345 and permit mul- tiple connections,
    as specified by the TCP-L:12345,fork,reuseaddr argument. The part following EXEC: tells socat to run SQLite on the /opt/sqlite/db file
    for every connection, assigning a pseudo-terminal to the process. The socat process in the cli- ent container has the same listening behavior
    as the server container (except on a dif- ferent port), but instead of running something in response to an incoming connection,
    it will establish a TCP connection to the SQLite server.
    One notable difference from the previous technique is the use of networks rather than links—networks present a way to create new virtual networks inside Docker.
    Docker Compose will always use a new “bridge” virtual network by default; it’s just been named explicitly in the preceding Compose configuration.
    Because any new bridge network allows access to containers using their service names, there’s no need to use links (though you still can if you want aliases for services).

    run Docker compose Cluster:

    ```
    chmod +x setup_dbs.sh
    ./setup_dbs.sh
    [sudo] docker-compose up
    [rlwrap] telnet localhost 12346
    [rlwrap] telnet localhost 12346
    select * from t1;
    ```

    If you want to switch the server to live, you can change the configuration by changing
    the volumes line in docker-compose.yml from this,

    - /tmp/sqlitedbs/test:/opt/sqlite/db

    to this:

    - /tmp/sqlitedbs/live:/opt/sqlite/db

    Then rerun this command:
    $ docker-compose up

    WARNING
    Although we did some basic tests with this multiplexing of SQLite clients,
    we make no guarantees about the data integrity or performance of this server under any kind of load.
    The SQLite client wasn’t designed to work in this way. The purpose of this technique is to demonstrate the general
    approach of exposing a binary in this way.

    This technique demonstrates how Docker Compose can take something relatively tricky and complicated,
    and make it robust and straightforward. Here we’ve taken SQLite and given it extra server-like functionality
    by wiring up containers to proxy SQLite invocations to the data on the host. Managing the container complexity
    is made significantly easier with Docker Compose’s YAML configuration, which turns the tricky matter of orchestrating
    containers correctly from a manual, error-prone process to a safer, automated one that can be put under source control.
