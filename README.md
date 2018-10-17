# certbot-docker

A container that runs `certbot` to help manage certificates. Docker volumes are used to share certificates and other files (e.g. challenges) across containers. This means multiple web server containers can take advantage of a single `certbot` container.  

### Sample usage
In your `docker-compose.yaml` file:

```bash
  nginx-web-server:
    environment:
      ...
      CERT_DIR: "${CERT_DIR}"
      CERT_DOMAIN: "${CERT_DOMAIN}"
      CHALLENGE_DIR: "${CHALLENGE_DIR}"
    volumes:
      ...
      # Directory for serving certbot challenge files
      - type: volume
        source: certbot-challenges
        target: ${CHALLENGE_DIR}
      # Directory for serving certificates
      - type: volume
        source: certbot-certs
        target: ${CERT_DIR}

  certbot:
    depends_on:
      - nginx-web-server
    environment:
      ADMIN_EMAIL: "${ADMIN_EMAIL}"
      CERT_DOMAIN: "${CERT_DOMAIN}"
    volumes:
      - type: volume
        source: certbot-challenges
        target: /challenges
      - type: volume
        source: certbot-certs
        target: /certs

volumes:
  certbot-challenges:
  certbot-certs:
```

Web server configuration. E.g. for `nginx.conf`:

```bash
server {
    listen ${HTTP_PORT};

    server_name _;

    location /.well-known/acme-challenge {
        root ${CHALLENGE_DIR};
        default_type "text/plain";
        try_files $uri =404;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
```