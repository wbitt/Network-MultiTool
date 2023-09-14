FROM alpine:3.18

MAINTAINER Kamran Azeem & Henrik Høegh (kamranazeem@gmail.com, henrikrhoegh@gmail.com )

EXPOSE 80 443 1180 11443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN     apk update \
    &&  apk add apache2-utils bash bind-tools busybox-extras curl ethtool git \
                iperf3 iproute2 iputils jq lftp mtr mysql-client \
                netcat-openbsd net-tools nginx nmap nmap-scripts openssh-client openssl \
                perl-net-telnet postgresql-client procps rsync socat \
                tcpdump tcptraceroute tshark wget \
    &&  mkdir /certs \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'


# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)
COPY index.html /usr/share/nginx/html/

# Copy a custom/simple nginx.conf which contains directives
#   to redirected access_log and error_log to stdout and stderr.
# Note: Don't use '/etc/nginx/conf.d/' directory for nginx virtual hosts anymore.
#   This 'include' will be moved to the root context in Alpine 3.14.

COPY nginx.conf /etc/nginx/nginx.conf

COPY docker-entrypoint.sh /docker-entrypoint.sh


# Start nginx in foreground:
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]



# Note: If you have not included the "bash" package, then it is "mandatory" to add "/bin/sh"
#         in the ENTNRYPOINT instruction. 
#       Otherwise you will get strange errors when you try to run the container. 
#       Such as:
#       standard_init_linux.go:219: exec user process caused: no such file or directory

# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]



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
