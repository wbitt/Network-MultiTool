# Network-Multitool
This is a multitool for container/network testing and troubleshooting. It is originally built with Fedora, but is now based on Alpine Linux. The container starts nginx web server and listens on port 80 and 443. This helps to run it in a straight forward way and use it to run various commands for troubleshooting whatever you are troubleshooting.

## Downloadable from Docker Hub: 
* [https://hub.docker.com/r/praqma/network-multitool/](https://hub.docker.com/r/praqma/network-multitool/)  (Automated Build)

# Tools included:
* apk package manager
* Nginx Web Server (port 80, port 443)
* wget, curl
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
* jq
* git


**Note:** The SSL certificates are generated for localhost, are self signed and placed in `/certs/` directory. During your testing ignore the certificate warning/error. While using curl, you can use `-k` to ignore SSL certificate warnings/errors. 
