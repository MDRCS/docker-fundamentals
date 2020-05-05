### - Technique 6:
    We’ve explored how to use a container as a monolithic entity (like a classical server) and explained that it
    can be a great way to quickly move a system architecture onto Docker. In the Docker world,
    however, it’s generally considered a best practice to split up your system as much as possible until
    you have one service running per container and have all containers connected by networks.

    The primary reason for using one service per container is the easier separation of concerns
    through the single-responsibility principle. If you have one container doing one job,
    it’s easier to put that container through the software development lifecycle of development,
    test, and production while worrying less about its interactions with other components.
    This makes for more agile deliveries and more scalable software projects.
    It does create management overhead, though, so it’s good to consider whether it’s worth it for your use case.

    + PROBLEM :
    You want to break your application up into distinct and more manageable services.

    + SOLUTION :
    Create a container for each discrete service process.
    As we’ve touched upon already, there’s some debate within the Docker community
    about how strictly the “one service per container” rule should be followed,
    with part of this stemming from a disagreement over the definitions—is it a single process,
    or a collection of processes that combine to fulfill a need? It often boils down to a state- ment that,
    given the ability to redesign a system from scratch, microservices is the route most would chose.

    Let’s take a look at one of the concrete disadvantages of using monoliths inside Docker.
    First, the following listing shows you how you’d build a monolith with a data- base, application, and web server.


    Example:

    - CMD:

    RUN service postgresql start && \
    cat db/schema.sql | psql && \
    service postgresql stop

    `TIP`
    Each Dockerfile command creates a single new layer on top of the previ- ous one,
    but using && in your RUN statements effectively ensures that several commands get run as one command.
    This is useful because it can keep your images small. If you run a package update command
    like apt-get update with an install command in this way, you ensure that whenever the packages are installed,
    they’ll be from an updated package cache.

    In the monlithic Example :
    In the preceding code, the COPY command is split into two separate instructions.
    This means the database won’t be rebuilt every time code changes,
    as the cache can be reused for the unchanged files delivered before the code.
    Unfortunately, because the caching functionality is fairly simple,
    the container still has to be completely rebuilt every time a change is made to the schema scripts.
    The only way to resolve this is to move away from sequential setup steps and create multiple Dockerfiles

    In the microservice Example :
    Whenever one of the db, app, or conf folders changes, only one container will need to be rebuilt.
    This is particularly useful when you have many more than three containers or there are time-intensive
    setup steps. With some care, you can add the bare minimum of files necessary for each step and get more
    useful Dockerfile caching as a result.

    `TIP`
    In the app Dockerfile, the operation of npm install is defined by a single file,
    package.json, so you can alter your Dockerfile to take advantage of Dockerfile
    layer caching and only rebuild the slow npm install step when necessary, as follows.

    :FAST UPDATE NODE.JS

    FROM ubuntu:14.04
    RUN apt-get update && apt-get install nodejs npm
    WORKDIR /opt
    COPY app/package.json /opt/app/package.json
    RUN cd app && npm install
    COPY app /opt/app
    RUN cd app && ./minify_static.sh

