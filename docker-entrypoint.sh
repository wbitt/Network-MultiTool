#!/bin/bash
sed -i '/If\ you\ read\ this/d' /usr/share/nginx/html/index.html
HOSTNAME=$(hostname)
CONTAINER_IP=$(ip addr show eth0 | grep -w inet| awk '{print $2}')


# Modify/Replace default listening ports 80 and 443 to whatever the user wants.
# This works only if the env variables HTTP_PORT and HTTPS_PORT are defined.
# If these variables are not defined, then the default ports 80 and 443 are used.

if [ -n "${HTTP_PORT}" ]; then
  sed -i "s/80/${HTTP_PORT}/g"  /etc/nginx/conf.d/default.conf
fi

if [ -n "${HTTPS_PORT}" ]; then
  sed -i "s/443/${HTTPS_PORT}/g"  /etc/nginx/conf.d/default.conf
fi


# Reduced the information in just one line. It overwrites the default text, 
#   indicating that our startup script ran correctly.
echo -e "Praqma Network MultiTool (with NGINX) - ${HOSTNAME} - ${CONTAINER_IP}" > /usr/share/nginx/html/index.html 

# Start nginx in foreground:
nginx -g "daemon off;"
