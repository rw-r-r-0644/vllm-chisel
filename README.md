# vllm-chisel

vllm + chisel reverse-tunnel client in one container.
image: `ghcr.io/rw-r-r-0644/vllm-chisel`.

## env

required:
- `CHISEL_URL` — chisel server URL (`http://host:port` or `https://host:port`, path allowed)
- `CHISEL_FINGERPRINT` — server host-key fingerprint (SHA256, base64)
- `CHISEL_AUTH` — server credential `<user>:<pass>`
- `TUNNEL_HOST` — server-side address to bind the tunnel to
- `TUNNEL_PORT` — server-side port for the tunnel

optional:
- `VLLM_PORT` (default `8000`)
- `VLLM_CONFIG` — path to a mounted [vLLM YAML config file](https://docs.vllm.ai/en/latest/configuration/serve_args.html), passed to `vllm serve` as `--config`

## run

    docker run --gpus all --ipc=host \
      -e CHISEL_URL=http://server:8080 \
      -e CHISEL_FINGERPRINT=... \
      -e CHISEL_AUTH=... \
      -e TUNNEL_HOST=tunnel \
      -e TUNNEL_PORT=13000 \
      -e VLLM_CONFIG=/etc/vllm/config.yaml \
      -v "$PWD/config.yaml:/etc/vllm/config.yaml:ro" \
      ghcr.io/rw-r-r-0644/vllm-chisel

vllm runs in the foreground, chisel runs in the background and reconnects on disconnect.

## last update
20260910