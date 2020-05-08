### - Continuous Integration :
      :NOTE
       In case you don’t know, continuous integration is a software lifecycle strategy used to speed up
       the development pipeline. By automatically rerun- ning tests every time a significant
       change is made to the codebase, you get faster and more stable deliveries because there’s
       a base level of stability in the software being delivered.

       + Docker Hub automated builds :
         --> The Docker Hub automated build feature :
         - if you point to a Git repository containing a Dockerfile, the Docker Hub will handle
           the process of building the image and making it available to download.
           An image rebuild will be triggered on any changes in the Git repository,
           making this quite useful as part of a CI process.


### - Technique 1 :

![ci](docker_ci.png)

       + PROBLEM :
       You want to automatically test and push changes to your image when the code changes.

       + SOLUTION :
       Set up a Docker Hub repository and link it to your code.
       Although the Docker Hub build isn’t complicated, a number of steps are required:
       1- Create your repository on GitHub or BitBucket.
       2- Clone the new Git repository.
       3- Add code to your Git repository.
       4- Commit the source.
       5- Push the Git repository.
       6- Create a new repository on the Docker Hub.
       7- Link the Docker Hub repository to the Git repository.
       8- Wait for the Docker Hub build to complete.
       9- Commit and push a change to the source.
       10- Wait for the second Docker Hub build to complete.

### - Technique 2 + Setting up a package cache for faster builds :

![cache](squid_proxy_cache.png)

      As Docker lends itself to frequent rebuilding of services for development,
      testing, and production, you can quickly get to a point where you’re repeatedly
      hitting the net- work a lot. One major cause is downloading package files from the internet.
      This can be a slow (and costly) overhead, even on a single machine.
      This technique shows you how to set up a local cache for your package downloads, covering apt and yum.

      - PROBLEM :
      You want to speed up your builds by reducing network I/O.

      - SOLUTION
      Install a Squid proxy for your package manager. Figure above illustrates how this tech- nique works.
      Because the calls for packages go to the local Squid proxy first, and are only requested
      over the internet the first time, there should only be one request over the internet for each package.
      If you have hundreds of containers all pulling down the same large packages from the internet,
      this can save you a lot of time and money.

     Example - local :
     1- install squadman
     2- configure port on 8080 and launch
     3- telnet localhost 8080

