FROM alpine:3.24.3

LABEL maintainer="Kamran Azeem & Henrik Høegh (kamranazeem@gmail.com, henrikrhoegh@gmail.com)"

EXPOSE 80 443 1180 11443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
# hadolint ignore=DL3018
RUN     apk update \
    &&  apk add --no-cache \
                bash bind-tools busybox-extras curl \
                iproute2 iputils jq mtr \
                net-tools nginx openssh-client openssl \
                perl-net-telnet procps rsync tcpdump tcptraceroute wget \
    &&  rm -rf /var/cache/apk/* \
    &&  mkdir /certs /docker \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'


# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)

COPY  --chown=nginx:nginx  index.html /usr/share/nginx/html/


# Copy a custom/simple nginx.conf which contains directives
#   to redirected access_log and error_log to stdout and stderr.
# Note: Don't use '/etc/nginx/conf.d/' directory for nginx virtual hosts anymore.
#   This 'include' will be moved to the root context in Alpine 3.14.

COPY --chown=nginx:nginx  nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /docker/entrypoint.sh

# Add a healthcheck to the Dockerfile.
# The healthcheck follows HTTP_PORT, because the entrypoint can move nginx
#   off port 80 at runtime. The shell expands ${HTTP_PORT:-80} at run time.
# hadolint ignore=DL3025
HEALTHCHECK --interval=30s --timeout=3s CMD curl -fsS -m 2 http://localhost:${HTTP_PORT:-80}/ || exit 1

# Start nginx in foreground:
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]



# Note: If you have not included the "bash" package, then it is "mandatory" to add "/bin/sh"
#         in the ENTRYPOINT instruction.
#       Otherwise you will get strange errors when you try to run the container.
#       Such as:
#       standard_init_linux.go:219: exec user process caused: no such file or directory

# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/bin/sh", "/docker/entrypoint.sh"]





###################################################################################################

# Build and Push (to dockerhub) instructions:
# -------------------------------------------
# docker build -t local/network-multitool .
# docker tag local/network-multitool wbitt/network-multitool
# docker login
# docker push wbitt/network-multitool


# Pull (from dockerhub):
# ----------------------
# docker pull wbitt/network-multitool


# Usage - on Docker:
# ------------------
# docker run --rm -it wbitt/network-multitool /bin/bash
# OR
# docker run -d  wbitt/network-multitool
# OR
# docker run -p 80:80 -p 443:443 -d  wbitt/network-multitool
# OR
# docker run -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -p 1180:1180 -p 11443:11443 -d  wbitt/network-multitool


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=wbitt/network-multitool
