#!/usr/bin/env bash

ENTITYNAME=${ENTITYNAME:-server}
CLIENT_COUNT=${CLIENT_COUNT:-3}


display_usage() {
  echo
  echo "Usage: $0"
  echo
  echo " -h, --help   Display usage instructions"
  echo " --server Using as server"
  echo " --client   Using as client"
  echo " --crt    Using for certificates creation"
  echo
}

server() {
  echo "Server"
}

client() {
  echo "Client"
}

crt() {
  cd /root/openvpn-ca
  echo "Execute command: ./easyrsa init-pki"
  ./easyrsa init-pki
  echo "Execute command: ./easyrsa build-ca nopass"
  ./easyrsa build-ca nopass
  echo "Execute command: ./easyrsa gen-req ${ENTITYNAME} nopass"
  ./easyrsa gen-req ${ENTITYNAME} nopass
  echo "Execute command: ./easyrsa sign-req server ${ENTITYNAME}"
  ./easyrsa sign-req server ${ENTITYNAME}
  echo "Execute command: ./easyrsa gen-dh"
  ./easyrsa gen-dh
  openvpn --genkey --secret ta.key
  cp pki/private/${ENTITYNAME}.key ca.crt ta.key pki/dh.pem pki/issued/server.crt /etc/openvpn/
  mkdir -p /etc/openvpn/client-configs/keys
  chmod -R 700 /etc/openvpn/client-configs
  for i in {0..$CLIENT_COUNT}
  do
    echo "Start creating client${i} cert"
    ./easyrsa gen-req client${i} nopass
    ./easyrsa sign-req client client${i}
    cp pki/private/client${i}.key pki/issued/client${i}.crt ta.key ca.crt /etc/openvpn/client-configs/keys/client${i}/
    echo "End creating client${i} cert"
  done
}

argument="$1"

if [[ -z $argument ]] ; then
  display_usage
else
  case $argument in
    -h|--help)
      display_usage
      ;;
    --server)
      server
      ;;
    --client)
      client
      ;;
    --crt)
      crt
      ;;
  esac
fi
