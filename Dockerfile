# Env setup:
# $ alias docker='sudo docker'

# Now, build sandbox:
# $ docker build -t quagga --no-cache=true .
# _OR_
# $ docker build -t quagga .

# Run it:
# $ docker run -d --privileged --name quagga -p 179:179 -p 2605:2605 quagga

# Usefull commands:
# $ docker logs quagga
# $ docker exec -i -t quagga /bin/bash
# $ docker cp quagga:/usr/local/src/quagga_0.99.23.1-1+deb8u4petski1_amd64.deb .
#
# To pin to this version:
# $ cat /etc/apt/preferences.d/quagga
# Package: quagga
# Pin: version 0.99.23.1-1+deb8u4petski1
# Pin-Priority: 1001

FROM debian:jessie
MAINTAINER Patrick Kuijvenhoven <patrick.kuijvenhoven@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

RUN sed -i -e '/^deb[[:space:]]/!d' -e 'p; s/^deb/deb-src/' /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y dpkg-dev devscripts vim-tiny 
RUN apt-get install -y quagga
RUN apt-get build-dep -y quagga

RUN mkdir -p /usr/local/src/
WORKDIR /usr/local/src/

RUN apt-get source -y quagga

WORKDIR /usr/local/src/quagga-0.99.23.1

COPY do_not_sync.patch debian/patches/
RUN echo do_not_sync.patch >> debian/patches/series

ENV DEBFULLNAME "Patrick Kuijvenhoven"
ENV DEBEMAIL "patrick.kuijvenhoven@gmail.com"
RUN dch --local petski 'Non-maintainer upload'
RUN dch -a             'Do not sync()'

RUN debuild -us -uc

WORKDIR /usr/local/src/

RUN dpkg -i quagga_0.99.23.1-1+deb8u4petski1_amd64.deb
RUN dpkg-query -l quagga

COPY bgpd.conf /etc/quagga/bgpd.conf
RUN chown quagga:quagga /etc/quagga/bgpd.conf

# bgp  179/tcp  # Border Gateway Protocol
# bgp  179/udp  # Border Gateway Protocol
# bgpd 2605/tcp # bgpd vty (zebra)

EXPOSE 179 2605

CMD ["/usr/lib/quagga/bgpd"]
