#!/bin/sh
# Smoke tests for the Network-MultiTool image variants.
# Usage: tests/smoke-test.sh <image> <minimal|extra|openshift>
# Runs on linux/amd64. Uses containers with unique names and removes them on exit.

set -u

IMAGE=${1:-}
VARIANT=${2:-}
PLATFORM=linux/amd64
CLEANUP_NAMES=""
TMPDIR=""
SUFFIX=$$

usage() {
  printf 'Usage: %s <image> <minimal|extra|openshift>\n' "$0" >&2
  exit 2
}

cleanup() {
  # shellcheck disable=SC2086
  for _name in $CLEANUP_NAMES; do
    docker rm -f "$_name" >/dev/null 2>&1 || true
  done
  if [ -n "$TMPDIR" ]; then
    rm -rf "$TMPDIR"
  fi
}

trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

fail() {
  printf 'FAIL [%s] %s\n' "$VARIANT" "$*" >&2
  exit 1
}

pass() {
  printf 'PASS [%s] %s\n' "$VARIANT" "$*"
}

track() {
  CLEANUP_NAMES="$CLEANUP_NAMES $1"
}

start_container() {
  _name=$1
  shift
  track "$_name"
  docker run -d --platform "$PLATFORM" --name "$_name" --label "nmt-smoke=$SUFFIX" "$@" >/dev/null
}

wait_http() {
  _name=$1
  _port=$2
  _scheme=$3
  _i=0
  while [ "$_i" -lt 30 ]; do
    if docker exec "$_name" curl -fsSk -m 2 "$_scheme://localhost:$_port/" >/dev/null 2>&1; then
      return 0
    fi
    _i=$((_i + 1))
    sleep 1
  done
  return 1
}

http_body() {
  docker exec "$1" curl -fsSk -m 3 "$3://localhost:$2/"
}

wait_healthy() {
  _name=$1
  _i=0
  while [ "$_i" -lt 30 ]; do
    _state=$(docker inspect --format '{{.State.Health.Status}}' "$_name" 2>/dev/null || printf 'none')
    if [ "$_state" = "healthy" ]; then
      return 0
    fi
    if [ "$_state" = "unhealthy" ]; then
      return 1
    fi
    _i=$((_i + 1))
    sleep 1
  done
  return 1
}

wait_exit() {
  _name=$1
  _i=0
  while [ "$_i" -lt 20 ]; do
    _running=$(docker inspect --format '{{.State.Running}}' "$_name" 2>/dev/null || printf 'false')
    if [ "$_running" = "false" ]; then
      return 0
    fi
    _i=$((_i + 1))
    sleep 1
  done
  return 1
}

[ -n "$IMAGE" ] || usage
case "$VARIANT" in
  minimal|extra|openshift) ;;
  *) usage ;;
esac

docker image inspect "$IMAGE" >/dev/null 2>&1 || fail "image not found: $IMAGE"

if [ "$VARIANT" = "openshift" ]; then
  DEFAULT_HTTP=1180
  DEFAULT_HTTPS=11443
  RUN_USER="--user 1234567890"
  HEALTH_ARGS=""
else
  DEFAULT_HTTP=80
  DEFAULT_HTTPS=443
  RUN_USER=""
  HEALTH_ARGS="--health-interval=1s --health-timeout=2s --health-retries=5"
fi

# 1. Configuration and expected tools.
docker run --rm --platform "$PLATFORM" --entrypoint /bin/sh "$IMAGE" -c 'nginx -t' >/dev/null 2>&1 \
  || fail "nginx -t failed"

for tool in bash curl dig ip jq nginx tcpdump; do
  docker run --rm --platform "$PLATFORM" --entrypoint /bin/sh "$IMAGE" -c "command -v $tool >/dev/null" \
    || fail "missing tool: $tool"
done
pass "nginx config and core tools"

if [ "$VARIANT" = "extra" ]; then
  for tool in nmap tshark iperf3 psql mysql; do
    docker run --rm --platform "$PLATFORM" --entrypoint /bin/sh "$IMAGE" -c "command -v $tool >/dev/null" \
      || fail "missing extra tool: $tool"
  done
  pass "extra tools present"
fi

# 2. Default startup and default ports.
DEFAULT_NAME="nmt-smoke-$SUFFIX-default"
# shellcheck disable=SC2086
start_container "$DEFAULT_NAME" $RUN_USER $HEALTH_ARGS "$IMAGE"

wait_http "$DEFAULT_NAME" "$DEFAULT_HTTP" http || fail "HTTP $DEFAULT_HTTP did not answer"
case "$(http_body "$DEFAULT_NAME" "$DEFAULT_HTTP" http)" in
  *"WBITT Network MultiTool"*) ;;
  *) fail "default page did not contain the WBITT marker" ;;
esac
pass "default HTTP on $DEFAULT_HTTP"

wait_http "$DEFAULT_NAME" "$DEFAULT_HTTPS" https || fail "HTTPS $DEFAULT_HTTPS did not answer"
pass "default HTTPS on $DEFAULT_HTTPS"

if [ "$VARIANT" != "openshift" ]; then
  wait_healthy "$DEFAULT_NAME" || fail "container did not become healthy on default ports"
  pass "default healthcheck"
fi

# 3. Custom ports, including the healthcheck following HTTP_PORT.
CUSTOM_NAME="nmt-smoke-$SUFFIX-custom"
# shellcheck disable=SC2086
start_container "$CUSTOM_NAME" $RUN_USER $HEALTH_ARGS -e HTTP_PORT=8080 -e HTTPS_PORT=8443 "$IMAGE"

wait_http "$CUSTOM_NAME" 8080 http || fail "custom HTTP 8080 did not answer"
wait_http "$CUSTOM_NAME" 8443 https || fail "custom HTTPS 8443 did not answer"
pass "custom ports 8080 and 8443"

if [ "$VARIANT" != "openshift" ]; then
  wait_healthy "$CUSTOM_NAME" || fail "healthcheck did not follow HTTP_PORT=8080"
  pass "healthcheck follows HTTP_PORT"
fi

# 4. Invalid port input must fail with a clear message.
BAD_NAME="nmt-smoke-$SUFFIX-bad"
start_container "$BAD_NAME" -e HTTP_PORT=notaport "$IMAGE"
wait_exit "$BAD_NAME" || fail "container with an invalid HTTP_PORT did not exit"
_bad_rc=$(docker inspect --format '{{.State.ExitCode}}' "$BAD_NAME")
[ "$_bad_rc" -ne 0 ] || fail "invalid HTTP_PORT exited zero"
docker logs "$BAD_NAME" 2>&1 | grep -q 'Invalid HTTP_PORT' || fail "no validation message for invalid HTTP_PORT"
pass "invalid HTTP_PORT rejected"

# 5. Equal ports must be rejected before nginx starts.
EQUAL_NAME="nmt-smoke-$SUFFIX-equal"
start_container "$EQUAL_NAME" -e HTTP_PORT=8080 -e HTTPS_PORT=8080 "$IMAGE"
wait_exit "$EQUAL_NAME" || fail "container with equal HTTP_PORT and HTTPS_PORT did not exit"
_equal_rc=$(docker inspect --format '{{.State.ExitCode}}' "$EQUAL_NAME")
[ "$_equal_rc" -ne 0 ] || fail "equal ports exited zero"
docker logs "$EQUAL_NAME" 2>&1 | grep -q 'must differ' || fail "no validation message for equal ports"
pass "equal ports rejected"

# 6. Restart must not rewrite the ports twice.
RESTART_NAME="nmt-smoke-$SUFFIX-restart"
# shellcheck disable=SC2086
start_container "$RESTART_NAME" $RUN_USER -e HTTP_PORT=8080 -e HTTPS_PORT=8443 "$IMAGE"
wait_http "$RESTART_NAME" 8080 http || fail "HTTP 8080 did not answer before restart"
docker restart "$RESTART_NAME" >/dev/null
wait_http "$RESTART_NAME" 8080 http || fail "HTTP 8080 did not answer after restart"
_got_http=$(docker exec "$RESTART_NAME" grep -cE '^[[:space:]]*listen[[:space:]]+8080;' /etc/nginx/nginx.conf || true)
_got_https=$(docker exec "$RESTART_NAME" grep -cE '^[[:space:]]*listen[[:space:]]+8443[[:space:]]+ssl;' /etc/nginx/nginx.conf || true)
[ "$_got_http" = "1" ] || fail "HTTP listen directive is not exactly once after restart (got $_got_http)"
[ "$_got_https" = "1" ] || fail "HTTPS listen directive is not exactly once after restart (got $_got_https)"
pass "restart is idempotent"

# 7. Mounted html must keep the container IP in the log line.
TMPDIR=$(mktemp -d)
printf 'mounted content\n' > "$TMPDIR/index.html"
_mount_out=$(docker run --rm --platform "$PLATFORM" -v "$TMPDIR:/usr/share/nginx/html" "$IMAGE" true 2>&1)
case "$_mount_out" in
  *"is a volume mount"*) ;;
  *) fail "mount branch was not detected" ;;
esac
printf '%s\n' "$_mount_out" | grep -Eq ' - [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ - ' \
  || fail "mounted-html log line has no container IP"
pass "mounted-html log keeps the container IP"

# 8. OpenShift runtime user and default ports.
if [ "$VARIANT" = "openshift" ]; then
  _who_out=$(docker run --rm --platform "$PLATFORM" --user 1234567890 "$IMAGE" sh -c 'id -u; whoami' 2>&1) \
    || fail "whoami failed for a random UID"
  _who_uid=$(printf '%s\n' "$_who_out" | grep -E '^[0-9]+$' | head -1)
  _who_name=$(printf '%s\n' "$_who_out" | tail -1)
  [ -n "$_who_uid" ] || fail "could not read the runtime UID"
  [ "$_who_name" = "okduser" ] || fail "whoami did not resolve the runtime user (got $_who_name)"
  [ "$_who_uid" != "0" ] || fail "openshift variant ran as root"
  _conf_out=$(docker run --rm --platform "$PLATFORM" --user 1234567890 "$IMAGE" \
    sh -c 'grep -E "^[[:space:]]*listen" /etc/nginx/nginx.conf' 2>&1) \
    || fail "could not read nginx.conf"
  printf '%s\n' "$_conf_out" | grep -qE '^[[:space:]]*listen[[:space:]]+1180;' \
    || fail "openshift nginx.conf does not listen on 1180"
  printf '%s\n' "$_conf_out" | grep -qE '^[[:space:]]*listen[[:space:]]+11443[[:space:]]+ssl;' \
    || fail "openshift nginx.conf does not listen on 11443"
  pass "openshift runtime user and ports"
fi

printf 'ALL CHECKS PASSED [%s] %s\n' "$VARIANT" "$IMAGE"
