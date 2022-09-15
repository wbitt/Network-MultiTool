FROM golang:1.19-alpine AS builder-usql

ARG INSTALL_EXTRAS=false

RUN if [ "${INSTALL_EXTRAS}" == "true" ] ; then \
        apk add --no-cache \
            gcc \
            musl-dev \
            && \
        go install -tags most github.com/xo/usql@latest \
        ; \
    else \
        touch /go/bin/usql \
        ; \
    fi

FROM alpine:3.16 AS release

ARG INSTALL_EXTRAS=false
ARG INSTALL_ADDITIONAL_SHELL="bash"

RUN apk update --no-cache && \
    # Base Utils
    apk add --no-cache \
        bind-tools \
        busybox-extras \
        curl \
        iproute2 \
        iputils \
        jq \
        mtr \
        net-tools \
        openssl \
        perl-net-telnet \
        procps \
        tcpdump \
        tcptraceroute \
        wget \
        && \
    # Extras
    if [ "${INSTALL_EXTRAS}" == "true" ] ; then \
        apk add --no-cache \
            apache2-utils \
            dasel \
            ethtool \
            git \
            iperf3 \
            lftp \
            mtr \
            netcat-openbsd \
            nmap \
            nmap-scripts \
            openssh-client \
            redis \
            rsync \
            socat \
            tshark \
            && \
        apk add --no-cache \
            ${INSTALL_ADDITIONAL_SHELL} \
            ; \
    fi

COPY --from=builder-usql /go/bin/usql /usr/bin/usql

CMD ["sleep", "infinity"]
