FROM alpine:3.5

ENV MEMCACHED_VERSION 1.4.35
ENV MEMCACHED_SHA1 787991c0df75defbb91518c9796f8244852a018a

RUN set -x \
	&& apk add --no-cache --virtual .build-deps \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		libc-dev \
		libevent-dev \
		linux-headers \
		make \
		perl \
		tar \
        && apk --no-cache add cyrus-sasl-dev \
	&& wget -O memcached.tar.gz "http://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached \
	&& ./configure --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" --enable-sasl \
	&& make -j "$(nproc)" \
	&& make install \
	&& cd / && rm -rf /usr/src/memcached \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .memcached-rundeps $runDeps \
	&& apk del .build-deps

RUN apk --no-cache add cyrus-sasl
RUN adduser -D memcached
USER root
RUN echo -n "pass" | saslpasswd2 -c -u example.com -a memcached -p user
RUN chown memcached:memcached /etc/sasldb2
USER memcached
EXPOSE 11211
CMD ["memcached", "-S"]
