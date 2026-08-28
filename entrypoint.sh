#!/usr/bin/env bash
set -uo pipefail

: "${VLLM_PORT:?VLLM_PORT must be set}"
: "${CHISEL_URL:?CHISEL_URL must be set}"
: "${CHISEL_FINGERPRINT:?CHISEL_FINGERPRINT must be set (server key fingerprint)}"
: "${CHISEL_AUTH:?CHISEL_AUTH must be set (<user>:<pass>)}"
: "${TUNNEL_PORT:?TUNNEL_PORT must be set}"
: "${TUNNEL_HOST:?TUNNEL_HOST must be set}"

AUTH="${CHISEL_AUTH}" chisel client \
  --fingerprint "${CHISEL_FINGERPRINT}" \
  --keepalive 25s \
  "${CHISEL_URL}" \
  "R:${TUNNEL_HOST}:${TUNNEL_PORT}:127.0.0.1:${VLLM_PORT}" &
CHISEL_PID=$!

vllm serve --host 127.0.0.1 --port "${VLLM_PORT}" ${VLLM_CONFIG:+--config "$VLLM_CONFIG"} &
VLLM_PID=$!

shutdown() {
  trap - TERM INT
  kill -TERM "$VLLM_PID" "$CHISEL_PID" 2>/dev/null || true
  wait "$VLLM_PID" 2>/dev/null || true
  exit 0
}
trap shutdown TERM INT

wait "$VLLM_PID"
VLLM_RC=$?
kill -TERM "$CHISEL_PID" 2>/dev/null || true
exit "$VLLM_RC"