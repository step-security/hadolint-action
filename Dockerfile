FROM ghcr.io/hadolint/hadolint:v2.15.1-alpine@sha256:a1d49ae1a4e83c1dbad26b8c1ad7588c8bd1e04f4866b34ad3cac50335198552

# hadolint ignore=DL3018
RUN apk add --no-cache --upgrade bash ca-certificates coreutils curl jq \
    libcrypto3=3.5.9-r0 libssl3=3.5.9-r0 musl=1.2.6-r3 musl-utils=1.2.6-r3 zlib=1.4-r0

COPY LICENSE README.md problem-matcher.json /
COPY hadolint.sh /usr/local/bin/hadolint.sh

ENTRYPOINT [ "/usr/local/bin/hadolint.sh" ]
