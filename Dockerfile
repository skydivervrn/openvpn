FROM debian:latest

RUN apt-get update \
 && apt-get install -y \
    dnsutils \
    openvpn \
    easy-rsa \
    wget

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
 && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
 && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

RUN make-cadir /root/openvpn-ca
COPY docker/ .

ENTRYPOINT ["/run.sh"]
