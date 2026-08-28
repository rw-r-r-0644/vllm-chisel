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

FROM vllm/vllm-openai:latest

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=chisel-dl /chisel /usr/local/bin/chisel
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && /usr/local/bin/chisel --help >/dev/null

ENV VLLM_PORT=8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []