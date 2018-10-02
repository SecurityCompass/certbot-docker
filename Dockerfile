FROM certbot/certbot:v0.27.1

LABEL name="certbot"
LABEL version="latest"

RUN apk update && \
    apk add openssl curl && \
    rm -rf /var/cache/apk/*

VOLUME /certs
VOLUME /challenges

COPY ./bin/ /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
