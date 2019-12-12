#!/usr/bin/env bash

ENTITYNAME=${ENTITYNAME:-EntityName}

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
  ./easyrsa init-pki
  ./easyrsa build-ca nopass
  ./easyrsa gen-req ${ENTITYNAME}
  ./easyrsa sign-req client ${ENTITYNAME}
  echo "CRT"
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
