# Network-Multitool
This is a multitool for container/network testing and troubleshooting. It was originally built with Fedora, but is now based on Alpine Linux. The container image contains lots of tools, as well as nginx web server, which listens on port 80 and 443 by default. The web server helps to run this container-image in a straight-forward way, so you can simply `exec` into the container and use various tools.

## Downloadable from Docker Hub: 
* [https://hub.docker.com/r/praqma/network-multitool/](https://hub.docker.com/r/praqma/network-multitool/)  (Automated Build)

# Tools included:
* apk package manager
* Nginx Web Server (port 80, port 443) - customisable ports!
* wget, curl, iperf3
* dig, nslookup
* ip, ifconfig, mii-tool, route
* ping, nmap, arp, arping
* awk, sed, grep, cut, diff, wc, find, vi editor
* netstat, ss
* gzip, cpio
* tcpdump
* telnet client, ssh client, ftp client, rsync
* traceroute, tracepath, mtr
* netcat (nc), socat
* ApacheBench (ab)
* mysql client
* postgresql client
* jq
* git


**Note:** The SSL certificates are generated for 'localhost', are self signed, and placed in `/certs/` directory. During your testing, ignore the certificate warning/error. While using curl, you can use `-k` to ignore SSL certificate warnings/errors.

# Configurable HTTP and HTTPS ports:
There are times when one may want to join this (multitool) container to another container's IP namespace for troubleshooting. This is true for both Docker and Kubernetes platforms. During that time if the container in question is a web server (nginx), then network-multitool cannot join it in the same IP namespace on Docker, and similarly it cannot join the same pod on Kubernetes. This is because network multitool also runs a web server on port 80 (and 443), and this results in port conflict on the same IP address. To help in this sort of troubleshooting, there are two envronment variables **HTTP_PORT** and **HTTPS_PORT** , which you can use to provide the values of your choice instead of 80 and 443. When the container starts, it uses the values provided by you/user to listen for incoming connections. Below is an example:

```
[kamran@kworkhorse network-multitool]$ docker run -e HTTP_PORT=1180 -e HTTPS_PORT=1443 -p 1180:1180 -p 1443:1443 -d local/network-multitool
4636efd4660c2436b3089ab1a979e5ce3ae23055f9ca5dc9ffbab508f28dfa2a

[kamran@kworkhorse network-multitool]$ docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                             NAMES
4636efd4660c        local/network-multitool   "/docker-entrypoint.…"   4 seconds ago       Up 3 seconds        80/tcp, 0.0.0.0:1180->1180/tcp, 443/tcp, 0.0.0.0:1443->1443/tcp   recursing_nobel
6e8b6ed8bfa6        nginx                     "nginx -g 'daemon of…"   56 minutes ago      Up 56 minutes       80/tcp                                                            nginx

[kamran@kworkhorse network-multitool]$ curl localhost:1180
Praqma Network MultiTool (with NGINX) - 4636efd4660c - 172.17.0.3/16

[kamran@kworkhorse network-multitool]$ curl -k https://localhost:1443
Praqma Network MultiTool (with NGINX) - 4636efd4660c - 172.17.0.3/16
[kamran@kworkhorse network-multitool]$ 
```  

If these environment variables are absent/not provided, the container will listen on normal/default ports 80 and 443.
