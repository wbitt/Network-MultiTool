FROM fedora:27
MAINTAINER Kamran Azeem & Henrik Høegh (kaz@praqma.net, heh@praqma.net)

# Install some tools in the container.
RUN    yum -y install procps-ng hostname bind-utils iputils iproute net-tools nmap tcpdump telnet traceroute mtr openssh-clients nginx postgresql mariadb nmap-ncat rsync ftp jq git \
    && yum clean all  \
    && mkdir /certs \
    && chmod 700 /certs

# Interesting:
# Users of this image may wonder, why this multitool runs a web server? 
# Well, normally, if a container does not run a daemon, 
#   ,then running it involves creating a special deployment.yaml file, 
#   ,which keeps the pod alive, so we can connect to it and do our testing, etc.
# If you don't want to create that extra file, 
#   ,then it is best to 'also' run a web server (as a daemon) in the container - as default process.
# This helps when you are on kubernetes platform and simply execute:
#   $ kubectl run multitool --image=praqma/network-multitool --replicas=1

# The multitool container starts - as web server. Then, you simply connect to it using:
#   $ kubectl exec -it multitool-3822887632-pwlr1  bash 

# This is why it is good to have a webserver in this tool. 
# Besides, I believe that having a web server in a multitool is like having yet another tool! 
# Personally, I think this is cool! Henrik thinks the same!

# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)
COPY index.html /usr/share/nginx/html/


# Copy a custom nginx.conf with log files redirected to stderr and stdout
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-connectors.conf /etc/nginx/conf.d/
COPY server.* /certs/

EXPOSE 80 443

COPY start_nginx.sh /

# Run the startup script instead, which updates the index.html with our hostname, and starts nginx.
CMD ["/start_nginx.sh"]


###################################################################################################

# Build and Push (to dockerhub) instructions:
# -------------------------------------------
# docker build -t network-multitool .
# docker tag network-multitool praqma/network-multitool
# docker login
# docker push praqma/network-multitool


# Pull (from dockerhub):
# ----------------------
# docker pull praqma/network-multitool


# Usage - on Docker:
# ------------------
# docker run --rm -it praqma/network-multitool /bin/bash 
# OR
# docker run -p 80:80 -p 443:443 -d  praqma/network-multitool


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=praqma/network-multitool --replicas=1
