#!/bin/sh


# If the html directory is mounted, it means user has mounted some content in it.
# In that case, we must not over-write the index.html file.

WEB_ROOT=/usr/share/nginx/html
MOUNT_CHECK=$(mount | grep ${WEB_ROOT})
HOSTNAME=$(hostname)

if [ -z "${MOUNT_CHECK}" ] ; then
  echo "The directory ${WEB_ROOT} is not mounted."
  echo "Therefore, over-writing the default index.html file with some useful information:"

  # CONTAINER_IP=$(ip addr show eth0 | grep -w inet| awk '{print $2}')
  # Note:
  #   CONTAINER IP cannot always be on device 'eth0'. 
  #     It could be something else too, as pointed by @arnaudveron .
  #   The 'ip -j route' shows JSON output, 
  #     and always shows the default route as the first entry.
  #     It also shows the correct device name as 'prefsrc', with correct IP address. 
  CONTAINER_IP=$(ip -j route get 1 | jq -r '.[0] .prefsrc')

  # Reduced the information in just one line. It overwrites the default text.
  echo -e "WBITT Network MultiTool (with NGINX) - ${HOSTNAME} - ${CONTAINER_IP} - HTTP: ${HTTP_PORT:-80} , HTTPS: ${HTTPS_PORT:-443} . (Formerly praqma/network-multitool)" | tee  ${WEB_ROOT}/index.html 
else
  echo "The directory ${WEB_ROOT} is a volume mount."
  echo "Therefore, will not over-write index.html"
  echo "Only logging the container characteristics:"
  echo -e "WBITT Network MultiTool (with NGINX) - ${HOSTNAME} - ${CONTAINER_IP} - HTTP: ${HTTP_PORT:-80} , HTTPS: ${HTTPS_PORT:-443} . (Formerly praqma/network-multitool)"

fi

# Custom/user-defined ports:
# -------------------------
# If the env variables HTTP_PORT and HTTPS_PORT are set, then
#   modify/Replace default listening ports 80 and 443 to whatever the user wants.
# If these variables are not defined, then the default ports 80 and 443 are used.

if [ -n "${HTTP_PORT}" ]; then
  echo "Replacing default HTTP port (80) with the value specified by the user - (HTTP_PORT: ${HTTP_PORT})."
  sed -i "s/80/${HTTP_PORT}/g"  /etc/nginx/nginx.conf
fi

if [ -n "${HTTPS_PORT}" ]; then
  echo "Replacing default HTTPS port (443) with the value specified by the user - (HTTPS_PORT: ${HTTPS_PORT})."
  sed -i "s/443/${HTTPS_PORT}/g"  /etc/nginx/nginx.conf
fi


# Execute the command specified as CMD in Dockerfile:
exec "$@"

