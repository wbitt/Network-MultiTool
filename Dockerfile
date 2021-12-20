FROM fedora:33

MAINTAINER Kamran Azeem & Henrik Høegh (kamranazeem@gmail.com, henrikrhoegh@gmail.com )

EXPOSE 80 443 1180 11443

COPY extra-software.repo /etc/yum.repos.d/

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN     yum -y install \
            bind-utils cpio diffutils findutils git gzip jq \
            iproute iputils logstash mariadb mtr mutt net-tools nginx \
            openssh-clients openldap openldap-clients openssl \
            postfix postgresql procps-ng tcpdump td-agent-bit telnet traceroute vim-minimal wget

RUN     curl -sLO https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.12.0-x86_64.rpm \
    &&  curl -sLO https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-basiclite-21.1.0.0.0-1.x86_64.rpm \
    && curl -sLO https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm \
    &&  rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch \
    &&  yum -y localinstall https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm \
    &&  yum -y localinstall oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm \
    &&  rm -f *.rpm \
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
# docker build -t local/network-multitool:fedora-es-db-tools .
# docker tag local/network-multitool praqma/network-multitool:fedora-es-db-tools
# docker login
# docker push praqma/network-multitool:fedora-es-db-tools


# Pull (from dockerhub):
# ----------------------
# docker pull praqma/network-multitool:fedora-es-db-tools


# Usage - on Docker:
# ------------------
# docker run --rm -it praqma/network-multitool:fedora-es-db-tools /bin/sh
# OR
# docker run -d  praqma/network-multitool:fedora-es-db-tools
# OR
# docker run -p 80:80 -p 443:443 -d  praqma/network-multitool:fedora-es-db-tools
# OR
# docker run -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -p 1180:1180 -p 11443:11443 -d  praqma/network-multitool:fedora-es-db-tools


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=praqma/network-multitool:fedora-es-db-tools
