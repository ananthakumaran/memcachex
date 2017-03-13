FROM buildpack-deps:jessie-curl

RUN curl --silent -L https://github.com/Shopify/toxiproxy/releases/download/v2.0.0/toxiproxy-server-linux-amd64 -o /usr/bin/toxiproxy
RUN chmod +x /usr/bin/toxiproxy
RUN curl --silent -L https://github.com/Shopify/toxiproxy/releases/download/v2.0.0/toxiproxy-cli-linux-amd64 -o /usr/bin/toxiproxy-cli
RUN chmod +x /usr/bin/toxiproxy-cli

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
