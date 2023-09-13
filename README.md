Sciaas Studio 2
========
Sciaas Studio 2 original repository is located at https://git.sqkcloud.com/sqk/sciaas-studio-2.

For a quick start please check our quick start guide.

Sciaas Studio 2 can also be run as a standalone application using a docker container.
First docker image need to be build unless you want to use prebuild from dockerhub. So, any change in the Dockerfile requires to build the image. But if you want to use prebuild version just skip building it and start the container.

Build docker image
---------

1. To build docker image first clone one of the latest sciaas-studio-2

```
git clone https://git.sqkcloud.com/sqk/sciaas-studio-2
```

2. Build the image
```
cd sciaas-studio-2
docker build -t sciaas-studio-2 .
```

3. Start the container
```
docker run -d -p 8080:80 -p 24:22 --name sciaas-studio-2 sciaas-studio-2
```

Now, you can open your browser to access sciaas-studio-2 using the url below.

http://localhost:8080

4. Stop the container
```
docker stop sciaas-studio-2
```

5. Remove the container
```
docker rm sciaas-studio-2
```
