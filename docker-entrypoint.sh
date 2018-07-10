#!/bin/bash
sed -i '/If\ you\ read\ this/d' /usr/share/nginx/html/index.html
HOSTNAME=$(hostname)
CONTAINER_IP=$(ip addr show eth0 | grep -w inet| awk '{print $2}')


# echo "<HR>" >> /usr/share/nginx/html/index.html 
# echo "<p>Container hostname: ${HOSTNAME} <BR>" >> /usr/share/nginx/html/index.html
# echo "Container IP: ${CONTAINER_IP} <BR></p>" >> /usr/share/nginx/html/index.html

# Reduced the information in just one line. It overwrites the default text, 
#   indicating that our startup script ran correctly.
echo -e "Praqma Network MultiTool (with NGINX) - ${HOSTNAME} - ${CONTAINER_IP}" > /usr/share/nginx/html/index.html 

# Start nginx in foreground:
nginx -g "daemon off;"
