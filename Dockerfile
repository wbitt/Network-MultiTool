FROM fedora:38

MAINTAINER Kamran Azeem & Henrik Høegh (kamranazeem@gmail.com, henrikrhoegh@gmail.com )

EXPOSE 80 443 1180 11443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN     yum -y install \
            bind-utils cpio diffutils findutils gzip jq \
            iproute iputils mtr net-tools nginx openssl \
            procps-ng telnet traceroute vim-minimal wget \
    &&  mkdir /certs \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'


# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)
COPY index.html /usr/share/nginx/html/

# Copy a custom nginx.conf with log files redirected to stderr and stdout
COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /


# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/bin/sh" , "/entrypoint.sh"]


# Start nginx in foreground:
CMD ["nginx", "-g", "daemon off;"]


###################################################################################################

# Build and Push (to dockerhub) instructions:
# -------------------------------------------
# docker build -t local/network-multitool:fedora .
# docker tag local/network-multitool praqma/network-multitool:fedora
# docker login
# docker push praqma/network-multitool:fedora


# Pull (from dockerhub):
# ----------------------
# docker pull praqma/network-multitool:fedora


# Usage - on Docker:
# ------------------
# docker run --rm -it praqma/network-multitool:fedora /bin/sh 
# OR
# docker run -d  praqma/network-multitool:fedora
# OR
# docker run -p 80:80 -p 443:443 -d  praqma/network-multitool:fedora
# OR
# docker run -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -p 1180:1180 -p 11443:11443 -d  praqma/network-multitool:fedora


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=praqma/network-multitool:fedora
