FROM centos
MAINTAINER Kamran Azeem (kaz@praqma.net) (kamranazeem@gmail.com)

# Copy the NGINX yum repo file into /etc/yum.repos.d/
 
COPY nginx-yum.repo /etc/yum.repos.d/

# Install some tools in a centos container, as busybox does not have enough troubleshooting tools.
RUN yum -y install bind-utils net-tools nmap tcpdump telnet traceroute mtr openssh-clients nginx && yum clean all 

# Interesting:
# Users of this image may wonder, why this multitool runs a web server? Well, when we use this with Kubernetes,
#   for troubleshooting purpose, then a simple image means creating a special deployment.yaml file, 
#   which keeps the pod alive, so we can connect to it and do our testing, etc.
# If you do not want to create that extra file (you normally first lookup the internet for such file - waste of time),
#   then it is best to 'also' run a web server and setup the image to do so by default. 

# This helps when you are on kubernetes platform and simply say:
# $ kubectl run centos-multitool --image=kamranazeem/centos-multitool --replicas=1

# It starts , as web server, then then you simply connect to it using:
# $ kubectl exec centos-multitool-3822887632-pwlr1  -i -t -- "bash" 

# That is why it is good to have a webserver in this tool. Besides, I believe that having a web server 
# in a multitool is like having yet another tool. Now you can do simple connectivity tests to the webserver too!
# Personally, I think this is cool!

# Copy a simple index.html , to eliminate text noise, when you curl the container on port 80.

## Use the path below for apache 
## COPY index.html /var/www/html

# Use the path below for nginx
COPY index.html /usr/share/nginx/html/

EXPOSE 80 443

# CMD ["executable","param1","param2"]

# Use the following for apache, if you are using that. 
## CMD ["apachectl", "-D", "FOREGROUND"]

# Use the following for nginx, if you are using that.
CMD ["nginx", "-g", "daemon off;"]


# Build and Push (to dockerhub) instructions:
# -------------------------------------------
# docker build -t network-multitool .
# docker tag network-multitool kamranazeem/network-multitool
# docker login
# docker push kamranazeem/network-multitool

# Pull (from dockerhub) and Usage:
# --------------------------------
# docker pull kamranazeem/network-multitool

# docker run --rm -it kamranazeem/network-multitool /bin/bash 
