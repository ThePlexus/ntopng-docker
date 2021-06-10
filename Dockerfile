FROM ubuntu:20.04
MAINTAINER Simon Newton <simon.newton@gmail.com>
ENV WORKDIR /ntop
WORKDIR ${WORKDIR}
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y \
  autoconf \
  autogen \
  automake \
  bison \
  build-essential \
  debhelper \
  dkms \
  dpkg-sig \
  flex \
  gcc \
  geoipupdate \
  golang-go \
  git \
  libxtables-dev \
  libcairo2-dev \
  libcap-dev \
  libcurl4-openssl-dev \
  libgeoip-dev \
  libhiredis-dev \
  libjson-c-dev \
  libmaxminddb0 \
  libmaxminddb-dev \
  libmysqlclient-dev \
  libncurses5-dev \
  libnetfilter-conntrack-dev \
  libnetfilter-queue-dev \
  libpango1.0-dev \
  libpcap-dev \
  libpng-dev \
  libreadline-dev \
  librrd-dev \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  libtool-bin \
  libxml2-dev \
  libzmq5-dev \
  mmdb-bin \
  net-tools \
  pkg-config \
  subversion \
  redis-server \
  rrdtool \
  wget \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 3.4-stable https://github.com/ntop/nDPI.git nDPI
RUN git clone --branch 4.2-stable https://github.com/ntop/ntopng.git ntopng
RUN git clone --branch dockerv0.0.2 https://github.com/shamen123/netflow2ng netflow2ng
COPY Makefile .
RUN make -B -j8
RUN ["chmod", "+x", "ntopng/ntopng"]
COPY run.sh .
RUN ["chmod", "+x", "run.sh"]
EXPOSE 3000/tcp
EXPOSE 2055/udp
RUN mkdir -p /var/lib/ntopng
RUN useradd ntopng
RUN chown ntopng:ntopng /var/lib/ntopng
RUN ["chown", "-R", "ntopng:ntopng", "/ntop"]
ENTRYPOINT ${WORKDIR}"/run.sh"

