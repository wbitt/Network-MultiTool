# Network-MultiTool
Multitool for container network troubleshooting. Based on CENTOS.

## Downloadable from Docker Hub: 
Use any of the following links:
* [https://hub.docker.com/r/praqma/network-multitool/](https://hub.docker.com/r/praqma/network-multitool/)  (Automated Build)
* [https://hub.docker.com/r/kamranazeem/network-multitool/](https://hub.docker.com/r/kamranazeem/network-multitool/)

# Tools included:
* Nginx Web Server (port 80, port 443)
* curl
* dig, nslookup
* ifconfig, mii-tool, route
* ping, nmap, arp, arping
* awk, sed, grep, cut, diff, wc, find, vi editor
* netstat, ss
* gzip, cpio
* tcpdump
* telnet client, ssh client
* traceroute, tracepath, mtr
* yum, rpm 

**Note:** The SSL certificates are self signed and are generated for localhost. During your testing ignore the certificate error. While using curl, you can use `-k` to ignore SSL certificate errors. 
