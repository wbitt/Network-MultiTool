#!/bin/bash
sed -i '/If\ you\ read\ this/d' /usr/share/nginx/html/index.html
HOSTNAME=$(hostname)
CONTAINER_IP=$(ifconfig eth0 | grep -w inet | awk '{print $2}')

echo "<HR>" >> /usr/share/nginx/html/index.html 
echo "<p>Container hostname: ${HOSTNAME} <BR>" >> /usr/share/nginx/html/index.html
echo "Container IP: ${CONTAINER_IP} <BR></p>" >> /usr/share/nginx/html/index.html

# Start nginx in foreground:
nginx -g "daemon off;"
