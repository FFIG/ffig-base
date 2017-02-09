# docker_images
Docker images for different stages of the product

Suggestions

Using the current ffig/Dockerfile

ffig_base - will change very rarely - sys requirements

```
FROM ubuntu:16.04
MAINTAINER Jonathan B Coe <jbcoe@me.com>

RUN apt-get -y update && apt-get install -y python-software-properties software-properties-common
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt-get -y update && apt-get install -y python-pip git cmake ninja-build ruby pypy python3 python3-pip clang libclang-3.8-dev libc++1 libc++-dev ruby-dev golang

RUN pip install --upgrade pip && pip install flask nose jinja2 
RUN pip3 install --upgrade pip && pip install flask nose jinja2
RUN gem install ffi

RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

ffig_ci - used to run tests on travis

```
FROM ffig:ffig_base
RUN useradd c-api-user && mkdir -p /home/ffig && chown c-api-user /home/ffig
ENV HOME /home/ffig
ENV LD_LIBRARY_PATH /usr/lib/llvm-3.8/lib:$LD_LIBRARY_PATH

COPY . /home/ffig
WORKDIR /home/ffig
```

ffig_web_base 

```
FROM ffig:ffig_ci
RUN pip install jupyter && pip3 install jupyter
COPY . /home/ffig/flask
WORKDIR /home/ffig/flask
EXPOSE 5000
RUN python -m flask
```

ffig_demo

```
FROM ffig:ffig_ci
RUN pip install jupyter && pip3 install jupyter
EXPOSE 8888
COPY docker/run-server.sh .
CMD ["./run-server.sh"]
```


