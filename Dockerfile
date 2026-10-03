# Stage 1: Build MinIO binary from source
FROM golang:1.26-alpine AS builder

ARG TARGETARCH
ARG RELEASE
ARG COMMIT_ID
ARG COMMIT_TIME

ENV GOPATH=/go \
    CGO_ENABLED=0

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache ca-certificates git bash curl

# Copy repository source code
COPY . .

# Build minio binary with version metadata
RUN export MINIO_RELEASE="RELEASE" && \
    if [ -n "${COMMIT_ID}" ]; then export MINIO_COMMIT_ID="${COMMIT_ID}"; fi && \
    if [ -n "${COMMIT_TIME}" ]; then export MINIO_COMMIT_TIME="${COMMIT_TIME}"; fi && \
    if [ -n "${RELEASE}" ]; then export MINIO_RELEASE="${RELEASE}"; fi && \
    LDFLAGS=$(go run buildscripts/gen-ldflags.go) && \
    ARCH="${TARGETARCH:-amd64}" && \
    GOARCH="${ARCH}" go build -tags kqueue -trimpath --ldflags "${LDFLAGS}" -o /go/bin/minio .

# Build minio client (mc)
RUN ARCH="${TARGETARCH:-amd64}" && \
    GOARCH="${ARCH}" go install github.com/lgcorzo/mc@master

# Stage 2: Final runtime image (MicroK8s MinIO Operator & Tenant compatible)
FROM alpine:3.21

ARG RELEASE

LABEL name="MinIO" \
      vendor="MinIO Inc <dev@min.io>" \
      maintainer="MinIO Inc <dev@min.io>" \
      version="${RELEASE}" \
      summary="MinIO High Performance Object Storage compatible with Amazon S3 API."

ENV PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    MINIO_UPDATE=off \
    MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_CONFIG_ENV_FILE=config.env \
    MC_CONFIG_DIR=/tmp/.mc

RUN apk add --no-cache ca-certificates curl bash && \
    mkdir -p /opt/bin /data /licenses /usr/bin /tmp/.mc && \
    chmod -R 777 /opt/bin /data /tmp/.mc

COPY --from=builder /go/bin/minio /opt/bin/minio
COPY --from=builder /go/bin/mc /opt/bin/mc

# Provide backward-compatibility symlinks in /usr/bin
RUN ln -sf /opt/bin/minio /usr/bin/minio && \
    ln -sf /opt/bin/mc /usr/bin/mc

COPY CREDITS /licenses/CREDITS
COPY LICENSE /licenses/LICENSE
COPY dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

EXPOSE 9000 9443
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
