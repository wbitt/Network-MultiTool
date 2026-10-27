#!/bin/sh

WEB_ROOT=/usr/share/nginx/html
NGINX_CONF=/etc/nginx/nginx.conf
HOST_NAME=$(hostname)


# Validate a port value before touching the nginx configuration.
# An empty value means "not set", and is ignored by the caller.
validate_port() {
  _name=$1
  _value=$2
  case "$_value" in
    ''|*[!0-9]*|0*) ;;
    *)
      if [ "$_value" -ge 1 ] && [ "$_value" -le 65535 ]; then
        return 0
      fi
      ;;
  esac
  printf 'Invalid %s: %s (must be an integer between 1 and 65535, without a leading zero)\n' "$_name" "$_value" >&2
  exit 1
}


# Replace the listen port in nginx.conf.
# The patterns are anchored, so a value like HTTP_PORT=443 does not touch the
#   HTTPS line, and a container restart does not rewrite an already changed port.
set_listen_port() {
  _old=$1
  _new=$2
  _with_ssl=$3
  if [ "$_old" = "$_new" ]; then
    return 0
  fi
  if [ -n "$_with_ssl" ]; then
    sed -i "s/^\([[:space:]]*listen[[:space:]]*\)${_old}\([[:space:]]*ssl;\)/\1${_new}\2/" "$NGINX_CONF"
  else
    sed -i "s/^\([[:space:]]*listen[[:space:]]*\)${_old};/\1${_new};/" "$NGINX_CONF"
  fi
}


# Validate the requested ports before any other runtime work.
if [ -n "${HTTP_PORT:-}" ]; then
  validate_port HTTP_PORT "$HTTP_PORT"
fi

if [ -n "${HTTPS_PORT:-}" ]; then
  validate_port HTTPS_PORT "$HTTPS_PORT"
fi

if [ "${HTTP_PORT:-80}" = "${HTTPS_PORT:-443}" ]; then
  printf 'Invalid ports: HTTP_PORT and HTTPS_PORT must differ (both %s).\n' "${HTTP_PORT:-80}" >&2
  exit 1
fi


# Openshift stuff:
# ---------------
# Even though we set USER to a numeric ID in Dockerfile,
#   Openshift still (forcefully) sets yet another "random" UID for USER.
#   In that case 'whoami' cannot find a match for that UID in /etc/passwd,
#   and therefore cannot return the name against that ID,
#   eventually returning a non-zero exit-code.
#
# When RUNTIME_USER_NAME is set (the openshift image sets it), add an entry
#   for the current UID to /etc/passwd, if the file is writable.
#
if [ -n "${RUNTIME_USER_NAME:-}" ] && ! whoami >/dev/null 2>&1; then
  USER_UID=$(id -u)
  if [ -w /etc/passwd ]; then
    printf 'Adding user %s:%s to /etc/passwd file ...\n' "$RUNTIME_USER_NAME" "$USER_UID"
    printf '%s:x:%s:0:%s user:/dev/null:/sbin/nologin\n' \
      "$RUNTIME_USER_NAME" "$USER_UID" "$RUNTIME_USER_NAME" >> /etc/passwd
  else
    printf 'Cannot add user %s:%s to /etc/passwd (file is not writable).\n' \
      "$RUNTIME_USER_NAME" "$USER_UID" >&2
  fi
fi


# The container IP is not always on device 'eth0'.
#   The 'ip -j route' output is JSON, and shows the default route first,
#   with the correct device name and IP address in 'prefsrc'.
CONTAINER_IP=$(ip -j route get 1 2>/dev/null | jq -r '.[0].prefsrc // empty' 2>/dev/null)
if [ -z "$CONTAINER_IP" ]; then
  CONTAINER_IP="unknown"
fi


# If the html directory is mounted, it means user has mounted some content in it.
# In that case, we must not over-write the index.html file.
if mount | grep -q " ${WEB_ROOT} "; then
  printf 'The directory %s is a volume mount.\n' "$WEB_ROOT"
  printf 'Therefore, will not over-write index.html\n'
  printf 'Only logging the container characteristics:\n'
  printf 'WBITT Network MultiTool (with NGINX) - %s - %s - HTTP: %s , HTTPS: %s . (Formerly praqma/network-multitool)\n' \
    "$HOST_NAME" "$CONTAINER_IP" "${HTTP_PORT:-80}" "${HTTPS_PORT:-443}"
else
  printf 'The directory %s is not mounted.\n' "$WEB_ROOT"
  printf 'Therefore, over-writing the default index.html file with some useful information:\n'
  printf 'WBITT Network MultiTool (with NGINX) - %s - %s - HTTP: %s , HTTPS: %s . (Formerly praqma/network-multitool)\n' \
    "$HOST_NAME" "$CONTAINER_IP" "${HTTP_PORT:-80}" "${HTTPS_PORT:-443}" | tee "${WEB_ROOT}/index.html"
fi


# Custom/user-defined ports:
# -------------------------
# If the env variables HTTP_PORT and HTTPS_PORT are set, then
#   modify/replace default listening ports 80 and 443 to whatever the user wants.
# If these variables are not defined, then the default ports 80 and 443 are used.
#
if [ -n "${HTTP_PORT:-}" ]; then
  printf 'Replacing default HTTP port (80) with the value specified by the user - (HTTP_PORT: %s).\n' "$HTTP_PORT"
  set_listen_port 80 "$HTTP_PORT" ""
fi

if [ -n "${HTTPS_PORT:-}" ]; then
  printf 'Replacing default HTTPS port (443) with the value specified by the user - (HTTPS_PORT: %s).\n' "$HTTPS_PORT"
  set_listen_port 443 "$HTTPS_PORT" "ssl"
fi


# Execute the command specified as CMD in Dockerfile:
exec "$@"
