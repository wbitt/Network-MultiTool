FROM alpine
MAINTAINER Kamran Azeem & Henrik Høegh (kaz@praqma.net, heh@praqma.net)

# Install some tools in the container.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN     apk update \
    &&  apk add apache2-utils bash bind-tools busybox-extras curl ethtool git \
                iperf3 iproute2 iputils jq lftp mtr mysql-client \
                netcat-openbsd net-tools nginx nmap openssh-client \
	        perl-net-telnet postgresql-client procps rsync socat tcpdump wget \
    &&  mkdir /certs \
    &&  chmod 700 /certs


# Interesting:
# Users of this image may wonder, why this multitool runs a web server? 
# Well, normally, if a container does not run a daemon, 
#   ,then running it involves using creative ways / hacks to keep it alive.
# If you don't want to suddenly start browsing the internet for "those creative ways",
#  ,then it is best to run a web server in the container - as the default process.
# This helps when you are on kubernetes platform and simply execute:
#   $ kubectl run multitool --image=praqma/network-multitool --replicas=1
# Or, on Docker:
#   $ docker run  -d praqma/network-multitool

# The multitool container starts as web server. Then, you simply connect to it using:
#   $ kubectl exec -it multitool-3822887632-pwlr1  bash
# Or, on Docker:
#   $ docker exec -it silly-container-name bash 

# This is why it is good to have a webserver in this tool. Hope this answers the question!
#
# Besides, I believe that having a web server in a multitool is like having yet another tool! 
# Personally, I think this is cool! Henrik thinks the same!

# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)
COPY index.html /usr/share/nginx/html/


# Copy a custom nginx.conf with log files redirected to stderr and stdout
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-connectors.conf /etc/nginx/conf.d/default.conf
COPY server.* /certs/

EXPOSE 80 443

COPY docker-entrypoint.sh /


# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/docker-entrypoint.sh"]


# Start nginx in foreground:
CMD ["nginx", "-g", "daemon off;"]


###################################################################################################

# Build and Push (to dockerhub) instructions:
# -------------------------------------------
# docker build -t local/network-multitool .
# docker tag local/network-multitool praqma/network-multitool
# docker login
# docker push praqma/network-multitool


# Pull (from dockerhub):
# ----------------------
# docker pull praqma/network-multitool


# Usage - on Docker:
# ------------------
# docker run --rm -it praqma/network-multitool /bin/bash 
# OR
# docker run -d  praqma/network-multitool
# OR
# docker run -p 80:80 -p 443:443 -d  praqma/network-multitool
# OR
# docker run -e HTTP_PORT=1080 -e HTTPS_PORT=1443 -p 1080:1080 -p 1443:1443 -d  praqma/network-multitool


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=praqma/network-multitool --replicas=1
