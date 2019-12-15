#!/usr/bin/env bash
set -e

CLIENT_COUNT=${CLIENT_COUNT:-3}
OPENVPN_PORT=${OPENVPN_PORT:-1194}

server_run() {
  echo "Run exec openvpn"
  cd /etc/openvpn
  dockerize -template /etc/openvpn/server/server.tmpl.conf:/etc/openvpn/server/server.conf
  exec "openvpn" "--config" "/etc/openvpn/server/server.conf"
}

client() {
  echo "Client"
}

make_base_conf() {
  export EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
  dockerize -template /etc/openvpn/client-configs/base.tmpl.conf:/etc/openvpn/client-configs/base.conf
}

client_crt() {
  cd /root/openvpn-ca
  make_base_conf
  for i in $(seq 1 $CLIENT_COUNT); do
    echo "Start creating client${i} cert"
    if [[ -f pki/private/client${i}.key ]]; then
      echo "Client key client${i} exist"
    else
      ./easyrsa gen-req client${i} nopass
      ./easyrsa sign-req client client${i}
      cp pki/private/client${i}.key pki/issued/client${i}.crt /etc/openvpn/client-configs/keys/
      /etc/openvpn/client-configs/make_config.sh client${i}
      echo "End creating client${i} cert"
    fi
  done
  echo  "Creation client certificates - complete"
}

server_crt() {
  cd /root/openvpn-ca
  if [[ -d /etc/openvpn/client-configs/keys ]]; then
    echo "Dir: /etc/openvpn/client-configs/keys exist"
  else
    mkdir -p /etc/openvpn/client-configs/keys
    mkdir -p /etc/openvpn/client-configs/files
  fi
  if [[ -f pki/private/ca.key ]]; then
    echo "File:  pki/private/ca.key - already exist"
  else
    echo "Execute command: ./easyrsa init-pki"
    ./easyrsa init-pki
    echo "Execute command: ./easyrsa build-ca nopass"
    ./easyrsa build-ca nopass
    cp pki/ca.crt /etc/openvpn/
    cp pki/ca.crt /etc/openvpn/client-configs/keys/
    chmod -R 700 /etc/openvpn/client-configs
  fi
  if [[ -f pki/private/server.key ]]; then
    echo "File: server.key exist"
  else
    echo "Execute command: ./easyrsa gen-req server nopass"
    ./easyrsa gen-req server nopass
    echo "Execute command: ./easyrsa sign-req server server"
    ./easyrsa sign-req server server
    echo "Execute command: ./easyrsa gen-dh"
    cp pki/private/server.key pki/issued/server.crt /etc/openvpn/
  fi
  if [[ -f pki/dh.pem ]]; then
    echo "File: pki/dh.pem exist"
  else
    ./easyrsa gen-dh
    cp pki/dh.pem /etc/openvpn/
  fi
  if [[ -f ta.key ]]; then
    echo "File: ta.key exist"
  else
    openvpn --genkey --secret ta.key
    cp ta.key /etc/openvpn/
    cp ta.key /etc/openvpn/client-configs/keys/
  fi
}

server_crt
client_crt
server_run