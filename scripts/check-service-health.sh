#!/usr/bin/env bash
# check-service-health.sh — HTTP or TCP health probe with clear exit codes.
# Exit: 0 = healthy, 1 = unhealthy/unreachable, 2 = usage error
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  check-service-health.sh --url <https://host/path> [--timeout <sec>] [--expect-code <n>]
  check-service-health.sh --host <hostname> --port <n> [--timeout <sec>]

Exit codes: 0 healthy | 1 unhealthy | 2 bad usage
USAGE
}

URL=""
HOST=""
PORT=""
TIMEOUT=5
EXPECT=200

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2 ;;
    --host) HOST="${2:-}"; shift 2 ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    --expect-code) EXPECT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -n "$URL" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required for HTTP probes" >&2
    exit 2
  fi
  set +e
  HTTP_CODE=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" -L "$URL" 2>/tmp/mbo-health-curl.err)
  CURL_RC=$?
  set -e
  if [[ $CURL_RC -ne 0 ]]; then
    echo "UNHEALTHY url=$URL reason=curl_exit_$CURL_RC detail=$(tr '\n' ' ' </tmp/mbo-health-curl.err 2>/dev/null || true)"
    rm -f /tmp/mbo-health-curl.err
    exit 1
  fi
  rm -f /tmp/mbo-health-curl.err
  if [[ "$HTTP_CODE" == "$EXPECT" ]]; then
    echo "HEALTHY url=$URL http=$HTTP_CODE expect=$EXPECT timeout=${TIMEOUT}s"
    exit 0
  fi
  echo "UNHEALTHY url=$URL http=$HTTP_CODE expect=$EXPECT"
  exit 1
fi

if [[ -n "$HOST" && -n "$PORT" ]]; then
  if command -v timeout >/dev/null 2>&1; then
    set +e
    timeout "$TIMEOUT" bash -c "echo >/dev/tcp/${HOST}/${PORT}" 2>/dev/null
    RC=$?
    set -e
  else
    set +e
    bash -c "echo >/dev/tcp/${HOST}/${PORT}" 2>/dev/null
    RC=$?
    set -e
  fi
  if [[ $RC -eq 0 ]]; then
    echo "HEALTHY host=$HOST port=$PORT timeout=${TIMEOUT}s"
    exit 0
  fi
  echo "UNHEALTHY host=$HOST port=$PORT"
  exit 1
fi

usage
exit 2
