FROM alpine:3.13

MAINTAINER Kamran Azeem (kamranazeem@gmail.com) & Henrik Høegh (henrikrhoegh@gmail.com)

# Note: This file (in openshift) branch does things a little differently.
# Reference: https://docs.openshift.com/container-platform/3.3/creating_images/guidelines.html#openshift-container-platform-specific-guidelines



# Using 1180 and 11443, and **not using 8080 or 8443**, 
#   so this (nginx) does not interfere with anything else the user may be running.

EXPOSE 1180 11443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
# Some files need setuid permissions to be able to run on openshift.
#   Otherwise those tools are unusable.

RUN     apk update \
    &&  apk add bash bind-tools busybox-extras curl \
                iproute2 iputils jq mtr \
                net-tools nginx openssl \
                perl-net-telnet procps tcpdump tcptraceroute wget \
    &&  chmod u+s /sbin/apk /bin/busybox  /usr/sbin/arping \
          /usr/bin/tcpdump /usr/bin/tcptraceroute \
    &&  mkdir  /certs  /docker /usr/share/nginx/html \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'
    
# Copy a simple index.html to eliminate text (index.html) noise,
#   which comes with default nginx image.
#
COPY index.html /usr/share/nginx/html/

# Copy a custom/simple nginx.conf which contains directives
#   to redirected access_log and error_log to stdout and stderr.
# Note: Don't use '/etc/nginx/conf.d/' directory for nginx virtual hosts anymore.
#   This 'include' will be moved to the root context in Alpine 3.14.
#
COPY nginx.conf /etc/nginx/nginx.conf

# To be able to manage the ownership and permissions of entrypoint,
#   The file has to be copied into  a dedicated directory.
#
COPY entrypoint.sh /docker/entrypoint.sh

# It is important to run this command after all the COPY operations.
RUN     chgrp -R root  /etc/nginx  /usr/share/nginx  /var/lib/nginx  /var/log/nginx \
          /run  /certs  /docker \
    &&  chmod -R g=u  /etc/nginx  /usr/share/nginx  /var/lib/nginx  /var/log/nginx \
          /run  /docker /etc/passwd \
    &&  chmod 0750 /certs \
    &&  chmod 0640 /certs/*
        


# Notes:
# * /etc/passwd is made group-writable because we would add a user,
#     later in entrypoint.sh script.



# Notes about USER:
# ----------------
# * Switch to "non-root" user - 1001  - advised by openshift documentation.
# * This USER <number> directive MUST be set in Dockerfile, 
#      to satisfy openshift requirements.
# * This USER ID can be any number out of your imagination (max 65535),
#      and it does not need to exist anywhere in the system,
#      and doesn't need to be created before-hand.
# * It's purpose is just to show/prove to openshift that the docker image
#     "does" switch away from "root" user. 
# * Once, openshift sees this, it then "ignores this ID as well",
#     and runs the image with a new random USER ID.
# * This new USER ID (uid) is then detected in entrypoint.sh script,
#     and rest of the tricks are done there.
# * See entrypoint.sh script in this image for more information.

USER 1001

# The variable below is used by docker entrypoint.sh script,
#   to create an entry in /etc/passwd with this username, 
#   and using the (random) uid set by openshift.
#
ENV RUNTIME_USER_NAME=okduser

# What does OKD mean? 
# Few years ago "OpenShift Origin" was renamed to OKD. Not sure why.
#   Confuses the hell out of people.
# Silly explanation here: https://learn.redhat.com/t5/Containers-DevOps-OpenShift/What-does-the-acronym-OKD-stand-for/td-p/246


# Start nginx in foreground:
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]


# Note: If you have not included the "bash" package, 
#         then it is "mandatory" to add "/bin/sh"
#         in the ENTNRYPOINT instruction. 
#       Otherwise you will get strange errors when you try to run the container. 
#       Such as:
#       standard_init_linux.go:219: exec user process caused: no such file or directory

# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/bin/sh", "/docker/entrypoint.sh"]



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
# docker run -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -p 1180:1180 -p 11443:11443 -d  praqma/network-multitool


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=praqma/network-multitool --replicas=1
