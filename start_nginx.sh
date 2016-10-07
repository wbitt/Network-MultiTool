#!/bin/bash
sed -i '/If\ you\ read\ this/d' /usr/share/nginx/html/index.html
HOSTNAME=$(hostname)
CIP=$(ifconfig eth0 | grep -w inet | awk '{print $2}')

echo "Container Hostname: ${HOSTNAME}" >> /usr/share/nginx/html/index.html
echo "Container IP: ${CIP}" >> /usr/share/nginx/html/index.html


nginx -g "daemon off;"
