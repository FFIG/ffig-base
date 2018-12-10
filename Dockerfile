# Defines an image that is used as the base for all FFIG Docker images. This
# includes the dependencies required to build and use FFIG, but not the FFIG
# code or derived applications.

FROM ubuntu:17.10
MAINTAINER FFIG <support@ffig.org>

RUN apt-get -y update && \
    apt-get install -y \
        python-software-properties \
        software-properties-common

# Software dependencies - sorted alphabetically
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get -y update && \
    apt-get install -y \
        clang \
        cmake \
        curl \
        dos2unix \
        git \
        golang \
        libc++-dev \
        libc++1 \
        libclang-5.0-dev \
        libunwind8 \
        luajit \
        mono-devel \
        ninja-build \
        pypy \
        python-pip \
        python3 \
        python3-pip \
        ruby \
        ruby-dev


# Install .NET Core
ENV DOTNET_SDK_VERSION 2.0.2
ENV DOTNET_DOWNLOAD_URL https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz

RUN curl -SL $DOTNET_DOWNLOAD_URL --output dotnet.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch


# Python dependencies
RUN pip2 install --upgrade pip==9.0.3 && \
    pip2 install jinja2 nose pycodestyle virtualenv && \
    pip3 install --upgrade pip==9.0.3 && \
    pip3 install jinja2 nose pycodestyle virtualenv 

# Ruby dependencies
RUN gem install ffi

# Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.31.0
    
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='0077ff9c19f722e2be202698c037413099e1188c0c233c12a2297bf18e9ff6e7' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='f139e5be4ea2db7ff151c122f5d24af3c587c4fc74a7414e262cb34403278ad3' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='c7d5471e71a315134e7499af75eb177d1f574858f1c6b8e61b436702d671a4e2' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='909ce4e2d0c9bf60ba5a85426c38cceb5ae77979ab2b1e354e76b9851b5ec5ed' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.14.0/${rustArch}/rustup-init"; \
    curl -SL $url --output rustup-init; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

# User and environment setup
RUN useradd ffig && \
    mkdir -p /home/ffig && \
    chown ffig /home/ffig

ENV HOME=/home/ffig \
    LD_LIBRARY_PATH=/usr/lib/llvm-5.0/lib:$LD_LIBRARY_PATH
