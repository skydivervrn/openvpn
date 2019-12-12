#!/usr/bin/env bash

ENTITYNAME=${ENTITYNAME:-server}

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
  echo "./easyrsa init-pki"
  ./easyrsa init-pki
  echo "./easyrsa build-ca nopass"
  ./easyrsa build-ca nopass
  echo "./easyrsa gen-req ${ENTITYNAME} nopass"
  ./easyrsa gen-req ${ENTITYNAME} nopass
  echo "./easyrsa sign-req client ${ENTITYNAME}"
  ./easyrsa sign-req server ${ENTITYNAME}
  cp pki/private/${ENTITYNAME}.key /etc/openvpn/
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
