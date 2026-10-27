# WBITT Network-Multitool (Formerly `praqma/Network-MultiTool`)

A (**multi-arch**) multitool for container/network testing and troubleshooting. The image is based on Alpine Linux and comes in three variants: a minimal image, an image with extra tools, and an OpenShift-compatible image.

The container image contains lots of tools, as well as a `nginx` web server, which listens on port `80` and `443` by default. The web server helps to run this container-image in a straight-forward way, so you can simply `exec` into the container and use various tools.

## Note about name/org change

In September 2016, I created this tool and maintained it with [Henrik](https://github.com/hoeghh) - as `praqma/network-multitool`. During 2020-2021 Praqma was bought by another company, and the new management did not want to promote the **"Praqma"** brand. This meant the network-multitool's git and Docker repositories must go. It was decided by the representatives of the company at that time to hand over the ownership/maintenance of this project to me, so I can continue maintaining it. Apart from a small change in the repository name, nothing in the tool has changed.

The Docker repository to pull this image is now: [https://hub.docker.com/r/wbitt/network-multitool](https://hub.docker.com/r/wbitt/network-multitool)

Or:

```bash
docker pull wbitt/network-multitool
```

## Supported platforms

* `linux/386`
* `linux/amd64`
* `linux/arm/v7`
* `linux/arm64`

## Downloadable from Docker Hub

* [https://hub.docker.com/r/wbitt/network-multitool](https://hub.docker.com/r/wbitt/network-multitool)  (An automated multi-arch build)

## Variants and image tags

* **minimal**: the default Alpine image. It is the smallest one, and `latest` points to it.
* **extra**: the minimal image plus the extra tools listed below.
* **openshift**: the minimal tools, but it runs as a non-root user and listens on `1180` and `11443`.

The tags for each variant:

* minimal: `latest`, `3.24.4`, `3.24`, `sha-<short-sha>-minimal`
* extra: `extra`, `3.24.4-extra`, `3.24-extra`, `sha-<short-sha>-extra`
* openshift: `openshift`, `3.24.4-openshift`, `3.24-openshift`, `sha-<short-sha>-openshift`

Tags from older layouts are not produced anymore. If you still use one of them, switch to the tags above.

## Important notes about the OpenShift variant

OpenShift is very strict about how a container image should run. So, the **openshift variant** of the multitool has the following limitations and changes:

* It runs as a random non-root UID. The entrypoint adds a matching entry to `/etc/passwd`, so `whoami` works.
* It listens on ports `1180` and `11443`, **not** `80` and `443`.
* It has **no setuid binaries**. A setuid binary in a container is a way around the security model, and a restricted SCC blocks privilege escalation anyway.
* Packet capture and `ping` need `NET_RAW`. A restricted SCC does not grant it. Use the host-network DaemonSet, or a privileged workload, when you need capture.
* It has no Docker `HEALTHCHECK`. Use the Kubernetes probes, or check the page yourself, when you run it there.

Remember, this *multitool* is purely a troubleshooting tool, and should be used as such. It is not designed to abuse openshift (or any system's) security, nor should it be used to do so.

## Tools included in "latest" and the minimal variant

* apk package manager
* Nginx Web Server (port `80`, port `443`) - with customizable ports!
* awk, cut, diff, find, grep, sed, vi editor, wc
* curl, wget
* dig, nslookup
* ip, ifconfig, route, ss
* traceroute, tracepath, mtr, tcptraceroute (for layer 4 packet tracing)
* ping, arp, arping
* ps, netstat
* gzip, cpio, tar
* telnet client
* tcpdump
* jq
* bash
* ssh, scp, sftp, ssh-keygen
* rsync
* openssl
* mii-tool

**Size:** about 25 MB compressed, about 106 MB uncompressed.

## Tools included in the extra variant

All tools from the minimal image, plus:

* iperf3
* ethtool
* nmap and nmap-scripts
* tshark
* lftp
* netcat (nc), socat
* ApacheBench (ab)
* mysql and postgresql clients
* git
* samba client (smbclient)
* net-snmp tools (snmpget, snmpwalk)

**Size:** about 94 MB compressed, about 427 MB uncompressed.

The openshift variant includes the same tools as the minimal variant, with the limitations listed above. Its compressed size is about 25 MB, and its uncompressed size is about 106 MB.

Sizes change with every Alpine and package update. These were measured in October 2026.

**Note:** The SSL certificates are generated for "localhost", are self signed, and are placed in `/certs/` directory. During your testing, ignore the certificate warning/error. While using curl, you can use `-k` to ignore SSL certificate warnings/errors.

The private key is baked into the image, so it is public. Treat this certificate as a test fixture only, and never trust it for anything real.

---

# How to use this image

## How to use this image in normal **container/pod network**

### Docker

```bash
docker run -d wbitt/network-multitool
```

Then:

```bash
docker exec -it container-name /bin/bash
```

### Kubernetes

Create single pod - without a deployment:

```bash
kubectl run multitool --image=wbitt/network-multitool
```

Create a deployment:

```bash
kubectl create deployment multitool --image=wbitt/network-multitool
```

Then:

```bash
kubectl exec -it pod-name /bin/bash
```

**Note:** You can pass additional parameter `--namespace=<your-desired-namespace>` to the above kubectl commands.

### OpenShift

```bash
oc new-project test-project-1

oc new-app wbitt/network-multitool:openshift --name multitool-openshift

oc status

oc get pods

oc logs pod-name

oc exec -it pod-name /bin/sh

oc port-forward pod-name 1180:1180 11443:11443
```

## How to use this image on **host network**

Sometimes you want to do testing using the **host network**. This can be achieved by running the multitool using host networking.

### Docker

```bash
docker run --network host -d wbitt/network-multitool
```

**Note:** If port 80 and/or 443 are already busy on the host, then pass the extra arguments to multitool, so it can listen on a different port, as shown below:

```bash
docker run --network host -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -d wbitt/network-multitool
```

The Docker healthcheck follows `HTTP_PORT`, so the container stays `healthy` when you move the web server.

### Kubernetes

For Kubernetes, there is a manifest file `kubernetes/multitool-daemonset.yaml` in the `kubernetes` directory, that will run an instance of the multitool on all hosts in the cluster using host networking.

```bash
kubectl apply -f kubernetes/multitool-daemonset.yaml
```

The manifest pins the image to a release tag. Change that tag deliberately, after you have tested the new release.

**Notes:**

* You can pass additional parameter `--namespace=<your-desired-namespace>` to the above kubectl command.
* Due to a possibility of something (some service) already listening on port 80 and 443 on the worker nodes, the `daemonset` is configured to run multitool on port `1180` and `11443`. You can change this in the YAML file if you want.
* The DaemonSet adds `NET_ADMIN` and `NET_RAW`, and raises the memory limit to `256Mi`, so packet capture works. Lower it only if you know you do not need capture.

# Configurable HTTP and HTTPS ports

There are times when one may want to join this (multitool) container to another container's IP namespace for troubleshooting, or on the host network. This is true for both Docker and Kubernetes platforms. During that time if the container in question is a web server (nginx, apache, etc), or a reverse-proxy (traefik, nginx, haproxy, etc), then network-multitool cannot join it in the same IP namespace on Docker, and similarly it cannot join the same pod on Kubernetes. This happens because network multitool also runs a web server on port 80 (and 443), and this results in port conflict on the same IP address. To help in this sort of troubleshooting, there are two environment variables **HTTP_PORT** and **HTTPS_PORT** , which you can use to provide the values of your choice instead of 80 and 443. When the container starts, it uses the values provided by you/user to listen for incoming connections. Below is an example:

```bash
docker run -e HTTP_PORT=1180 -e HTTPS_PORT=11443 \
    -p 1180:1180 -p 11443:11443 -d local/network-multitool
```

```text
4636efd4660c2436b3089ab1a979e5ce3ae23055f9ca5dc9ffbab508f28dfa2a


$ docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                                                             NAMES
4636efd4660c        local/network-multitool   "/docker-entrypoint.…"   4 seconds ago       Up 3 seconds        80/tcp, 0.0.0.0:1180->1180/tcp, 443/tcp, 0.0.0.0:11443->11443/tcp   recursing_nobel
6e8b6ed8bfa6        nginx                     "nginx -g 'daemon of…"   56 minutes ago      Up 56 minutes       80/tcp                                                            nginx


$ curl http://localhost:1180
WBITT Network MultiTool (with NGINX) - 4636efd4660c - 172.17.0.3 - HTTP: 1180 , HTTPS: 11443 . (Formerly praqma/network-multitool)


$ curl -k https://localhost:11443
WBITT Network MultiTool (with NGINX) - 4636efd4660c - 172.17.0.3 - HTTP: 1180 , HTTPS: 11443 . (Formerly praqma/network-multitool)
```

If these environment variables are absent/not-provided, the container will listen on normal/default ports 80 and 443. A value that is not a valid port number, including a value with a leading zero, is rejected at startup with a clear message, and so are two equal ports, instead of a broken nginx configuration.

---

# Keeping the image current

The Dockerfiles pin the Alpine base to an exact patch. At the time of writing it is `3.24.3`. I check the Alpine release page once a month. When there is a new 3.24 patch, I bump the base in all three Dockerfiles, rebuild, run the smoke tests, and publish a new release tag.

The image release tag and the Alpine patch are separate numbers. A release can be `3.24.4` while the base is `3.24.3`. Check `/etc/alpine-release` inside the image for the real base.

There is no dependency bot on purpose. I do not take automated PRs for this repository.

The release process is short:

1. Merge the tested change to `master`.
2. Create a tag such as `3.24.4` on `master`.
3. Push the tag. The pipeline builds and tests all three variants, then publishes them.

A push to `master` does not publish anything. Only a stable release tag publishes. It also moves `latest`, `extra`, and `openshift`. `latest` moves only for the minimal variant.

## Testing the image

The smoke test is in `tests/smoke-test.sh`. Run it against a locally built image:

```bash
sh tests/smoke-test.sh local/network-multitool:minimal minimal
sh tests/smoke-test.sh local/network-multitool:extra extra
sh tests/smoke-test.sh local/network-multitool:openshift openshift
```

It checks the nginx configuration, the tools, the default and custom ports, the healthcheck, invalid port input, a container restart, the mounted-html log line, and the OpenShift runtime user.

---

# FAQs

## Why this multitool runs a web-server?

Well, normally, if a container does not run a daemon/service, then running it (the container) involves using *creative ways / hacks* to keep it alive. If you don't want to suddenly start browsing the internet for "those creative ways", then it is best to run a small web server in the container - as the default process.

This helps you when you are using Docker. You simply execute:

```bash
docker run -d wbitt/network-multitool
```

This also helps when you are using Kubernetes. You simply execute:

```bash
kubectl run multitool --image=wbitt/network-multitool
```

The multitool container starts as web server - so it remains `UP`. Then, you simply connect to it using:

```bash
docker exec -it some-silly-container-name /bin/sh
```

Or, on Kubernetes:

```bash
kubectl exec -it multitool-3822887632-pwlr1 -- /bin/sh
```

This is why it is good to have a web-server in this tool. Hope this answers the question! Besides, I believe that having a web server in a multitool is like having yet another tool! Personally, I think this is cool! [Henrik](https://www.linkedin.com/in/henrikrenehoegh/) thinks the same!

## Why is `latest` only the minimal image?

Because `latest` should be predictable. The minimal image is the default image, and it is the one most people want. The extra image is bigger, and the openshift image has different ports and a different user. If you want those, ask for them by name: `extra` or `openshift`.

## Why no setuid binaries in the openshift variant?

A setuid binary inside a container gives any process a way to run as root. That defeats the non-root design, and a restricted SCC blocks privilege escalation anyway. If you need packet capture, use the host-network DaemonSet, which has the capabilities it needs.

## I can't find a tool I need for my use-case?

We have tried to put in all the most commonly used tools, while keeping it small and practical. We can't have all the tools under the sun, otherwise it will end up as [something like this](https://www.amazon.ca/Wenger-16999-Swiss-Knife-Giant/dp/B001DZTJRQ).

However, if you have a special need, for a special tool, for your special use-case, then I would recommend to simply build your own Docker image using this one as base image, and expanding it with the tools you need.

## Why not use LetsEncrypt for SSL certificates instead of generating your own?

There is absolutely no need to use LetsEncrypt. This is a testing tool, and validity of SSL certificates does not matter.

## Why use a daemonset when troubleshooting host networking on Kubernetes?

One could argue that it is possible to simply install the tools on the hosts and get over with it. However, we should keep the infrastructure immutable and not install anything on the hosts. *Ideally* we should never `ssh` to our cluster worker nodes. Some of the reasons are:

* It is generally cumbersome to install the tools since they might be needed on several hosts.
* New packages may conflict with existing packages, and *may* break some functionality of the host.
* Removing the tools and dependencies after use could be difficult, as it *may* break some functionality of the host.
* By using a `daemonset`, it makes it easier to integrate with other resources. e.g. Use volumes for packet capture files, etc.
* Using the `daemonset` provides a *'cloud native'* approach to provision debugging/testing tools.
* You can `exec` into the `daemonset`, without needing to SSH into the node.

## How to contribute to this project?

Contributions are welcome for packages/tools considered **"absolutely necessary"**, of **"core"** nature, are **"minimal"** in size, and **"have large number of use-cases"**. Remember, the goal is not to create yet another Linux distribution! :)
