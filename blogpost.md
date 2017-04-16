# The Network Multitool container image

![](leatherman-wave.jpg)

## The itch
There was a time ... actually ... many a times, when I needed more than just ping to reach a container running on a particular docker host on a particular docker / container network. 

We know that the idea behind a docker container in general is that it should have just enough software to make sure that the process/service it is supposed to run, is run without any problems; for example: a web server, a java application server, database server, etc.

Just because these docker (container) images are very minimalistic, (in terms of size too), they have no other tools installed in them, making them very lean in nature. If a container is to run a single process all it's life, why bother filling it up with software which is never going to be used! Great! But since they are lean, troubleshooting them sometimes is difficult.

Recently I was working on a Kubernetes cluster, and was not able to resolve services' names setup and provided by Kubernetes addon called SkyDNS. I had nginx running as a container, and being minimalistic in nature, it had no tools inside it except ping. It didn't even have nslookup! I installed nslookup in a running container, the usual `apt-get update` and `apt-get install dnsutils`. It is aother story that nslookup alone did not prove to be much helpful in this particular case. It was just not giving me enough information about what was happening with name resolution. I was not until I decided to install `dig` that I figured out what was going on! It actually took me many container starts and many times going through the same `apt-get` update and install routines, until I reached a point to install dig instead of nslookup and things got very clear after that. 

This officially was a nasty (or very interesting) itch (depending on how you look at it), and I needed a solution for such situations. 


## The solution
Being a big fan and user of the multitools, such as the Leatherman Wave that I carry at all times with me as EDC, I needed a container image which would have all the necessary tools installed in it, which I could use at will - without getting into the apt-* mess. I also wanted the container image to run as a standard (web service) pod too, so I could get two things out of it:

* I will always have a web service to test my connections - nginx in this case; and,
* I will just 'exec' and 'bash' into it and not have to remember complex kubectl commands to run it in interactive mode. 

So I went ahead and created [praqma/network-multitool](https://hub.docker.com/r/praqma/network-multitool/). I am a RedHat fan, so I based my image on CENTOS:7 . Intially I had Apache as web server, but later I replaced it with nginx - nginx being very light weight and very fast.

Creating this network-multitool image has completely soothed this itch. Now, I use it to solve all sorts of problems. Packet capture, telnet , traceroute, mtr, dig, netstat, you name it, it probably has it. I hope you will enjoy using this multitool as much as well as we do at Praqma.

