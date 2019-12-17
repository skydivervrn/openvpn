#!/usr/bin/env bash
set -e

export EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

function elog() {
    datestring=`date +"%Y-%m-%d %H:%M:%S"`
    echo "${datestring}  ${@}"
}
server_run() {
  elog "Run exec openvpn"
  iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun0 -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
  cd /etc/openvpn
  dockerize -template /etc/openvpn/templates/server.tmpl.conf:/etc/openvpn/server/server.conf
  cd /etc/openvpn
  exec "openvpn" "--config" "/etc/openvpn/server/server.conf"
}

client() {
  elog "Client"
}

make_client_conf() {
  dockerize -template /etc/openvpn/templates/base.tmpl.conf:/etc/openvpn/client-configs/base.conf
  /etc/openvpn/client-configs/make_config.sh ${OVPN_CLIENT_NAME}
}

client_crt() {
  cd /root/openvpn-ca
  IFS=',' # hyphen (-) is set as delimiter
  read -ra CLIENT_CONFIG <<< "$CLIENTS_OPENVPN" # str is read into an array as tokens separated by IFS
  for i in "${CLIENT_CONFIG[@]}"; do # access each element of array
    IFS=':'
    read -ra CLIENT_IP_SET <<< "$i"
    export OVPN_CLIENT_NAME="${CLIENT_IP_SET[0]}"
    export OVPN_CLIENT_IP="${CLIENT_IP_SET[1]}"
    export OVPN_CLIENT_PORT_NAT="${CLIENT_IP_SET[2]}"
    export OVPN_CLIENT_PORT_NAT_PROTO="${CLIENT_IP_SET[3]}"
    elog "Check creating ${OVPN_CLIENT_NAME} cert....."
    if [[ -f pki/private/${OVPN_CLIENT_NAME}.key ]]; then
      elog "Client key ${OVPN_CLIENT_NAME} exist"
    else
      elog "Creating ${OVPN_CLIENT_NAME} key and cert..."
      export EASYRSA_REQ_CN=${OVPN_CLIENT_NAME}
      ./easyrsa gen-req ${OVPN_CLIENT_NAME} nopass
      ./easyrsa sign-req client ${OVPN_CLIENT_NAME}
      cp pki/private/${OVPN_CLIENT_NAME}.key pki/issued/${OVPN_CLIENT_NAME}.crt /etc/openvpn/client-configs/keys/
      export EASYRSA_REQ_CN=""
      elog "...creation ${OVPN_CLIENT_NAME} key and cert complete"
    fi
    make_client_conf
    if [[ -z "${OVPN_CLIENT_IP}" ]]; then
      elog "Client static IP is not set"
    else
      elog "Starting template client ccd.."
      dockerize -template /etc/openvpn/templates/client.tmpl:/etc/openvpn/ccd/${OVPN_CLIENT_NAME}
      elog "Client ccd created"
    fi
    if [[ -z "${OVPN_CLIENT_PORT_NAT}" ]]; then
      elog "Port for client ${OVPN_CLIENT_NAME} wasn't specified"
    else
      iptables -t nat -A PREROUTING -p ${OVPN_CLIENT_PORT_NAT_PROTO} --dport ${OVPN_CLIENT_PORT_NAT} -j DNAT --to-dest ${OVPN_CLIENT_IP}:${OVPN_CLIENT_PORT_NAT}
    fi
  export OVPN_CLIENT_NAME=""
  export OVPN_CLIENT_IP=""
  export OVPN_CLIENT_PORT_NAT=""
  export OVPN_CLIENT_PORT_NAT_PROTO=""
  done
  IFS=' ' # reset to default value after usage
  elog "Creation client certificates - complete"
}

server_crt() {
  cd /root/openvpn-ca
  if [[ -f pki/private/ca.key ]]; then
    elog "File:  pki/private/ca.key - already exist"
  else
    elog "Execute command: ./easyrsa init-pki"
    ./easyrsa init-pki
    elog "Execute command: ./easyrsa build-ca nopass"
    ./easyrsa build-ca nopass
    cp pki/ca.crt /etc/openvpn/
    cp pki/ca.crt /etc/openvpn/client-configs/keys/
    chmod -R 700 /etc/openvpn/client-configs
  fi
  if [[ -f pki/private/server.key ]]; then
    elog "File: server.key exist"
  else
    elog "Execute command: ./easyrsa gen-req server nopass"
    ./easyrsa gen-req server nopass
    elog "Execute command: ./easyrsa sign-req server server"
    ./easyrsa sign-req server server
    elog "Execute command: ./easyrsa gen-dh"
    cp pki/private/server.key pki/issued/server.crt /etc/openvpn/
  fi
  if [[ -f pki/dh.pem ]]; then
    elog "File: pki/dh.pem exist"
  else
    ./easyrsa gen-dh
    cp pki/dh.pem /etc/openvpn/
  fi
  if [[ -f ta.key ]]; then
    elog "File: ta.key exist"
  else
    openvpn --genkey --secret ta.key
    cp ta.key /etc/openvpn/
    cp ta.key /etc/openvpn/client-configs/keys/
  fi
  iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
}

server_crt
client_crt
server_run