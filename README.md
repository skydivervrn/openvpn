# openvpn
This is the simple openvpn server in Docker container. Just run
```
docker-compose up -d --build
```
And take you .ovpn client configs from `/var/lib/docker/volumes/openvpn_openvpn/_data/client-configs/files/` and move it ti clients devices.
# Ansible
 Necessary to use dynamic inventory ec2.py

# Docker
Provide necessary client names as CLIENTS_OPENVPN env var. Format "name1:ovpnIP:port:proto,name2:ovpnIP:port:proto".
Only "name is required"
```
      CLIENTS_OPENVPN: "client1:10.8.0.11:22:tcp,client2:10.8.0.12:80:udp"
      CLIENTS_OPENVPN: "client1:10.8.0.11:22:tcp,client2,client3:10.8.0.13"
```
And pass ports to the container like:
```
    ports:
      - target: 8080
        published: 1194
        protocol: udp
        mode: host
      - target: 22
        published: 8081
        protocol: tcp
        mode: host
```
Don't forget to expose this 'target' ports in you firewall.
For example in "security group" AWS cloud.
Provide docker volumes to the docker container
```
    volumes:
      - openvpn:/etc/openvpn
      - ca:/root/openvpn-ca
```
