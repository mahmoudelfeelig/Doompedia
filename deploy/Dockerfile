FROM caddy:2-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648

RUN setcap -r /usr/bin/caddy \
    && test -z "$(getcap /usr/bin/caddy)"

COPY deploy/Caddyfile /etc/caddy/Caddyfile
