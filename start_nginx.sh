#!/bin/bash
sed -i '/If\ you\ read\ this/d' /usr/share/nginx/html/index.html
HOSTNAME=$(hostname)
CIP=$(ifconfig eth0 | grep -w inet | awk '{print $2}')

echo "<p>Container Name: ${HOSTNAME}" >> /usr/share/nginx/html/index.html
echo "Container IP: ${CIP} <BR></p>" >> /usr/share/nginx/html/index.html


nginx -g "daemon off;"
