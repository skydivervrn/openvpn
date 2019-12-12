#!/usr/bin/env bash

display_usage() {
  echo
  echo "Usage: $0"
  echo
  echo " -h, --help   Display usage instructions"
  echo " --master   Using server as master node"
  echo " --slave    Using server as slave node"
  echo " --witness    Using server as witness node"
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
  source vars
  ./clean-all
  ./build-ca

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
