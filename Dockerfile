FROM debian:latest

RUN apt-get update \
 && apt-get install -y \
    openvpn \
    easy-rsa

RUN make-cadir /root/openvpn-ca
COPY docker/ .

ENTRYPOINT ["run.sh"]
