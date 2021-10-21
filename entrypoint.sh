#!/bin/sh

# Openshift stuff:
# ---------------
# Even though we set USER to a numeric ID in Dockerfile,
#   Openshift still (forcefully) sets yet another "random" UID for USER.
#   In that case 'whoami' cannot find a match for that UID in /etc/passwd,
#   and therefore cannot return the name against that ID,
#   eventually returning a non-zero exit-code.

if ! whoami &> /dev/null; then

  # As explained above, we reached this section because,
  #   whoami returned error, which is exactly what the above condition checks.
  #   So, now we create an entry for this user in /etc/passwd.
  # i.e. we set the USER_NAME as whatever we set RUNTIME_USER_NAME in Dockerfile,
  #      The user-id  (uid) as the uid forcefully set by openshift.
  #      USER_HOME as '/dev/null',  and login shell as '/sbin/nologin'.

  USER_NAME=${RUNTIME_USER_NAME:-default}
  USER_UID=$(id -u)
  USER_HOME=/dev/null
  USER_SHELL=/sbin/nologin

  echo
  echo "The container is running as UID: ${USER_UID}"
  echo "The container is running as USER_NAME: ${USER_NAME}"
  echo
   
  if [ -w /etc/passwd ]; then
    # RUNTIME_USER_NAME is set in Dockerfile.
    #   If it is not defined there, then simply set it to the word 'default'.
    echo "${USER_NAME}:x:${USER_UID}:0:${USER_NAME} user:${USER_HOME}:${USER_SHELL}" >> /etc/passwd
  fi

  # wireshark stuff:  
  if [ -w /etc/group ]; then
    # This won't work as regular user: addgroup ${USER_NAME} wireshark
    sed -i "s/^\(wireshark\:x\:[[:digit:]]*\)\:.*/\1:${USER_NAME}/g" /etc/group
    echo "/etc/group updated for wireshark group:"
    grep wireshark /etc/group
  fi
fi


# * If the env variables HTTP_PORT and HTTPS_PORT are defined, then
#     modify/Replace default listening ports 1180 and 11443 to whatever the user wants.
# * If these variables are not defined, then the default ports 1180 and 11443 are used.
# * Above explanation (and code below) is only valid for "openshift" version of this image.

echo

if [ -n "${HTTP_PORT}" ]; then
  echo "nginx.conf - Replacing default HTTP port (1180) with the value specified by the user - (HTTPS_PORT: ${HTTP_PORT})."
  sed -i "s/1180/${HTTP_PORT}/g"  /etc/nginx/nginx.conf
fi

if [ -n "${HTTPS_PORT}" ]; then
  echo "nginx.conf - Replacing default HTTPS port (11443) with the value specified by the user - (HTTPS_PORT: ${HTTPS_PORT})."
  sed -i "s/11443/${HTTPS_PORT}/g"  /etc/nginx/nginx.conf
fi


# ----------------------------------------------------------------------

# Regular stuff:
# -------------


# If the html directory is mounted, it means user has mounted some content in it.
# In that case, we must not over-write the index.html file.

WEB_ROOT=/usr/share/nginx/html
MOUNT_CHECK=$(mount | grep ${WEB_ROOT})
HOSTNAME=$(hostname)

echo

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
  echo -e "Praqma Network MultiTool (with NGINX) - ${HOSTNAME} - ${CONTAINER_IP} - HTTP: ${HTTP_PORT:-1180} - HTTPS: ${HTTPS_PORT:-11443}" | tee ${WEB_ROOT}/index.html 
else
  echo "The directory ${WEB_ROOT} is a volume mount. Will not over-write index.html ."

fi


echo

# Execute the command specified as CMD in Dockerfile:
exec "$@"

