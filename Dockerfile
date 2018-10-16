FROM certbot/certbot:v0.27.1

LABEL name="certbot"
LABEL version="latest"

RUN apk --no-cache add openssl curl

COPY ./bin/ /usr/local/bin/
RUN chmod +x /usr/local/bin/run_certbot.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
