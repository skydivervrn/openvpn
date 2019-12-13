#!/usr/bin/env bash
set -e

ENTITYNAME=${ENTITYNAME:-server}
CLIENT_COUNT=${CLIENT_COUNT:-3}
OPENVPN_PORT=${OPENVPN_PORT:-1194}

server_run() {
  openvpn "/etc/openvpn/server.conf"
}

client() {
  echo "Client"
}

crt() {
  cd /root/openvpn-ca
  if [[ -f pki/private/ca.key ]]; then
    echo "FILE: pki/private/ca.key - already exist"
    server_run
  else
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
    cp pki/private/${ENTITYNAME}.key pki/ca.crt ta.key pki/dh.pem pki/issued/server.crt /etc/openvpn/
    mkdir -p /etc/openvpn/client-configs/keys
    mkdir -p /etc/openvpn/client-configs/files
    chmod -R 700 /etc/openvpn/client-configs
    cp ta.key pki/ca.crt /etc/openvpn/client-configs/keys/
    export EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
    dockerize -template /etc/openvpn/client-configs/base.tmpl.conf:/etc/openvpn/client-configs/base.conf
    for i in $(seq 1 $CLIENT_COUNT); do
      echo "Start creating client${i} cert"
      ./easyrsa gen-req client${i} nopass
      ./easyrsa sign-req client client${i}
      cp pki/private/client${i}.key pki/issued/client${i}.crt /etc/openvpn/client-configs/keys/
      /etc/openvpn/client-configs/make_config.sh client${i}
      echo "End creating client${i} cert"
    done
    echo  "Creation client certificates - complete"
    server_run
  fi
  echo "Something WRONG!!!!!!!"
  exit 1
}

crt
