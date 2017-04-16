# The Network Multitool container image

![](leatherman-wave.jpg)

## The itch
There was a time ... actually ... many a times, when I needed more than just ping to reach a container running on a particular docker host on a particular docker / container network. 

We know that the idea behind a docker container in general is that it should have just enough software to make sure that the process/service it is supposed to run, is run without any problems; for example: a web server, a java application server, database server, etc.

Just because these docker (container) images are very minimalistic, (in terms of size too), they have no other tools installed in them, making them very lean in nature. If a container is to run a single process all it's life, why bother filling it up with software which is never going to be used! Great! But since they are lean, troubleshooting them sometimes is difficult.

Recently I was working on a Kubernetes cluster, and was not able to resolve services' names setup and provided by Kubernetes addon called SkyDNS. I had nginx running as a container, and being minimalistic in nature, it had no tools inside it except ping. It didn't even have nslookup! I installed nslookup in a running container, the usual `apt-get update` and `apt-get install dnsutils`. It is another story that nslookup alone did not prove to be much helpful in this particular case. It was just not giving me enough information about what was happening with name resolution. I was not until I decided to install `dig` that I figured out what was going on! It actually took me many container starts and many times going through the same `apt-get` update and install routines, until I reached a point to install dig instead of nslookup and things got very clear after that. 

This officially was a nasty (or very interesting) itch (depending on how you look at it), and I needed a solution for such situations. 


## The solution
Being a big fan and user of the multitools, such as the [Leatherman Wave](https://www.leatherman.com/wave-10.html) that I carry at all times with me as [EDC](https://en.wikipedia.org/wiki/Everyday_carry), I needed a container image which would have all the necessary tools installed in it, which I could use at will - without getting into the apt-* mess. I also wanted the container image to run as a standard (web service) pod too, so I could get two things out of it:

* I will always have a web service to test my connections - nginx in this case; and,
* I will just 'exec' and 'bash' into it and not have to remember complex kubectl commands to run it in interactive mode. 

So I went ahead and created [praqma/network-multitool](https://hub.docker.com/r/praqma/network-multitool/). I am a RedHat fan, so I based my image on CENTOS:7 . Intially I had Apache as web server, but later I replaced it with nginx - nginx being very light weight and very fast.

## Example usage:
This image can be used in any environment which allows you to run containers; docker, docker-swarm, kubernetes, etc. Here are few eamples on how you can run and use this image:

### On Docker host:

First, pull the image, though not entirely necessary.
```
[kamran@kworkhorse ~]$ docker pull praqma/network-multitool
Using default tag: latest
Trying to pull repository docker.io/praqma/network-multitool ... 
sha256:970b1ef9c12f4368c67b1fdbcaaedf4030861dae8263a410701fe040d59d1317: Pulling from docker.io/praqma/network-multitool

93857f76ae30: Already exists 
6c1308705eea: Pull complete 
82a705257117: Pull complete 
1a824777af48: Pull complete 
dfe620fcbab4: Pull complete 
417b019d6dbe: Pull complete 
1d9e1b44b10a: Pull complete 
4e922c058a8f: Pull complete 
Digest: sha256:970b1ef9c12f4368c67b1fdbcaaedf4030861dae8263a410701fe040d59d1317
Status: Downloaded newer image for docker.io/praqma/network-multitool:latest
[kamran@kworkhorse ~]$ 
```

**Interactive:**
```
[kamran@kworkhorse ~]$ docker run --rm -it praqma/network-multitool bash

[root@92288413e051 /]# nslookup yahoo.com
Server:		192.168.100.1
Address:	192.168.100.1#53

Non-authoritative answer:
Name:	yahoo.com
Address: 98.138.253.109
Name:	yahoo.com
Address: 98.139.183.24
Name:	yahoo.com
Address: 206.190.36.45

[root@92288413e051 /]# 
```

**Datached / Daemon mode:**
```
[kamran@kworkhorse ~]$ docker run -P -d  praqma/network-multitool
a76d156c674f2b61c9b9fb10f87c645620c4fcbe88a13162546379abc9a87f14
[kamran@kworkhorse ~]$ 
```

```
[kamran@kworkhorse ~]$ docker ps
CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS              PORTS                                           NAMES
a76d156c674f        praqma/network-multitool   "/start_nginx.sh"   31 seconds ago      Up 30 seconds       0.0.0.0:32769->80/tcp, 0.0.0.0:32768->443/tcp   silly_franklin
[kamran@kworkhorse ~]$
```

```
[kamran@kworkhorse ~]$ docker exec -it silly_franklin bash

[root@a76d156c674f /]# curl -I yahoo.com 
HTTP/1.1 301 Redirect
Date: Sun, 16 Apr 2017 16:09:20 GMT
Via: https/1.1 ir28.fp.ne1.yahoo.com (ApacheTrafficServer)
Server: ATS
Location: https://www.yahoo.com/
Content-Type: text/html
Content-Language: en
Cache-Control: no-store, no-cache
Connection: keep-alive
Content-Length: 304

[root@a76d156c674f /]# 
```

### On Kubernetes cluster:
First run the container image as **deployment (detached/daemon mode)**:

```
[kamran@kworkhorse ~]$ kubectl run multitool --image=praqma/network-multitool
deployment "multitool" created
[kamran@kworkhorse ~]$ 
```

Find the pod name and connect to it in **interactive mode**:
```
[kamran@kworkhorse ~]$ kubectl get pods
NAME                                  READY     STATUS    RESTARTS   AGE
multitool-2814616439-hd8p6            1/1       Running   0          1m
[kamran@kworkhorse ~]$ 
```

```
[kamran@kworkhorse ~]$ kubectl exec -it multitool-2814616439-hd8p6 bash

[root@multitool-2814616439-hd8p6 /]# traceroute google.com                                                                         
traceroute to google.com (64.233.184.102), 30 hops max, 60 byte packets
 1  gateway (10.112.1.1)  0.044 ms  0.014 ms  0.009 ms
 2  wa-in-f102.1e100.net (64.233.184.102)  0.716 ms  0.701 ms  0.896 ms
[root@multitool-2814616439-hd8p6 /]# exit
exit
[kamran@kworkhorse ~]$ 
```

## Summary:
Creating this network-multitool image has completely soothed this itch. Now, I use it to solve all sorts of problems. Packet capture, telnet , traceroute, mtr, dig, netstat, curl - you name it, it probably has it! I hope you will enjoy using this multitool as much as well as we do at Praqma.


