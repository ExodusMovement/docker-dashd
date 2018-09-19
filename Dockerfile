FROM alpine:3.8 AS builder

ENV BUILD_TAG=0.12.3.2

RUN apk add --no-cache \
  autoconf \
  automake \
  boost-dev \
  build-base \
  openssl-dev \
  libevent-dev \
  libtool \
  zeromq-dev

RUN wget -O- https://github.com/dashpay/dash/archive/v$BUILD_TAG.tar.gz | tar xz && mv /dash-$BUILD_TAG /dash
WORKDIR /dash

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --disable-wallet \
  --disable-tests \
  --disable-bench \
  --with-utils \
  --without-libs \
  --without-gui
RUN make -j$(nproc)
RUN strip src/dashd src/dash-cli


FROM alpine:3.8

RUN apk add --no-cache \
  boost \
  boost-program_options \
  openssl \
  libevent \
  zeromq

COPY --from=builder /dash/src/dashd /dash/src/dash-cli /usr/local/bin/

RUN addgroup -g 1000 dashd \
  && adduser -u 1000 -G dashd -s /bin/sh -D dashd

USER dashd

# P2P & RPC
EXPOSE 9999 9998

ENV \
  DASHD_DBCACHE=300 \
  DASHD_PAR=0 \
  DASHD_PORT=9999 \
  DASHD_RPC_PORT=9998 \
  DASHD_RPC_THREADS=4 \
  DASHD_ARGUMENTS=""

CMD exec dashd \
  -dbcache=$DASHD_DBCACHE \
  -par=$DASHD_PAR \
  -port=$DASHD_PORT \
  -rpcport=$DASHD_RPC_PORT \
  -rpcthreads=$DASHD_RPC_THREADS \
  $DASHD_ARGUMENTS
