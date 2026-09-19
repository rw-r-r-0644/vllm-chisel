ARG CHISEL_VERSION=1.12.0-rc3

FROM alpine:3 AS chisel-dl
ARG CHISEL_VERSION
ARG TARGETARCH

# sha256 of chisel_<CHISEL_VERSION>_linux_<arch>.gz, from the release checksums file
ARG CHISEL_AMD64_SHA256=82528cad31e968db9a6fdc4612df8c339684dc5b7b8c77925a887129baacf32e
ARG CHISEL_ARM64_SHA256=47e46167acc2a55525c08ea418fe7c2fea731f2e1fb6d02f5332822caf17464d

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) sha="${CHISEL_AMD64_SHA256}" ;; \
        arm64) sha="${CHISEL_ARM64_SHA256}" ;; \
        *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    apk add --no-cache ca-certificates curl; \
    curl -fsSL "https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${TARGETARCH}.gz" -o chisel.gz; \
    echo "${sha}  chisel.gz" | sha256sum -c -; \
    gunzip chisel.gz; \
    chmod +x chisel

FROM vllm/vllm-openai@sha256:43f13b4c624ab9e9e6753d0eeb5953268bff334f2a826239e6f4a2197d47bb96

COPY flash-next-vllm.patch /tmp/
COPY flash-next-decode-01-ple-host-gather.patch /tmp/
COPY flash-next-decode-02-model-state-hook.patch /tmp/
COPY flash-next-mtp-01-enable.patch /tmp/
COPY flash-next-mtp-02-prefix-cache.patch /tmp/
RUN cd /usr/local/lib/python3.12/dist-packages \
    && patch -p1 --batch --forward < /tmp/flash-next-vllm.patch \
    && patch -p1 --batch --forward < /tmp/flash-next-decode-01-ple-host-gather.patch \
    && patch -p1 --batch --forward < /tmp/flash-next-decode-02-model-state-hook.patch \
    && patch -p1 --batch --forward < /tmp/flash-next-mtp-01-enable.patch \
    && patch -p1 --batch --forward < /tmp/flash-next-mtp-02-prefix-cache.patch \
    && rm /tmp/flash-next-vllm.patch \
          /tmp/flash-next-decode-01-ple-host-gather.patch \
          /tmp/flash-next-decode-02-model-state-hook.patch \
          /tmp/flash-next-mtp-01-enable.patch \
          /tmp/flash-next-mtp-02-prefix-cache.patch \
    && python3 -m py_compile \
        vllm/models/qwen4_exp/nvidia/model.py \
        vllm/models/qwen4_exp/nvidia/hyperconnection.py \
        vllm/models/qwen4_exp/nvidia/ngram_embedding.py \
        vllm/models/qwen4_exp/nvidia/model_state.py \
        vllm/models/qwen4_exp/nvidia/mtp.py \
        vllm/models/qwen4_exp/nvidia/qsa.py \
        vllm/models/qwen4_exp/nvidia/ops/qsa.py \
        vllm/model_executor/models/config.py \
        vllm/v1/core/kv_cache_utils.py \
        vllm/platforms/interface.py

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=chisel-dl /chisel /usr/local/bin/chisel
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && /usr/local/bin/chisel --help >/dev/null

ENV VLLM_PORT=8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
