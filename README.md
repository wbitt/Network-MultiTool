# Xan Manning's Network-Multitool (Based on `wbitt/Network-MultiTool`)

A (**multi-arch**) multitool for container/network testing and troubleshooting.
The main container image is based on Alpine Linux and contains lots of tools.

## Why this image?

Whilst much the same to WBITT's image, this one is a little bit more
opinionated as to which tools should be included. This image will eventually
be scanned weekly with Trivy and rebuilt if there are vulnerabilities found.

## Supported platforms:

- linux/amd64
- linux/arm64

## Downloadable from Docker Hub:

- [https://hub.docker.com/r/xanmanning/network-multitool](https://hub.docker.com/r/xanmanning/network-multitool) (An automated multi-arch build)

## Variants / image tags:

- **latest**, minimal (The main/default **'minimal'** image - Alpine based)
- extras (Alpine based image - with **extra tools**)

## Tools included in "latest, minimal":

- apk package manager
- awk, cut, diff, find, grep, sed, vi editor, wc
- curl, wget
- dig, nslookup
- ip, ifconfig, route
- traceroute, tracepath, mtr, tcptraceroute (for layer 4 packet tracing)
- ping, arp, arping
- ps, netstat
- gzip, cpio, tar
- telnet client
- tcpdump
- jq

## Tools included in "extras":

All tools from "minimal", plus:

- iperf3
- ethtool, mii-tool, route
- nmap
- ss
- tshark
- ssh client, lftp client, rsync, scp
- netcat (nc), socat
- ApacheBench (ab)
- database client (usql)
- git

# How to use this image?

## How to use this image in normal **container/pod network** ?

### Docker:

```bash
$ docker run --rm -it xanmanning/network-multitool sh
```


### Kubernetes:

Create single pod - without a deployment:

```bash
$ kubectl run --rm -it network-multitool --restart=Never --image=xanmanning/network-multitool -- sh
```

**Note:** You can pass additional parameter `--namespace=<your-desired-namespace>` to the above `kubectl` commands.


## How to use this image on **host network** ?

Sometimes you want to do testing using the **host network**.  This can be achieved by running the multitool using host networking.


### Docker:

```bash
$ docker run --rm -it --network=host xanmanning/network-multitool sh
```
