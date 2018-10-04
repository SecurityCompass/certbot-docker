FROM certbot/certbot:v0.27.1

LABEL name="certbot"
LABEL version="latest"

RUN apk update && \
    apk add openssl curl && \
    rm -rf /var/cache/apk/*

COPY ./bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/run_certbot.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
