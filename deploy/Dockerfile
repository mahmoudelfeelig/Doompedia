FROM caddy:2-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648

RUN setcap -r /usr/bin/caddy \
    && test -z "$(getcap /usr/bin/caddy)" \
    && addgroup -S -g 10001 doompedia \
    && adduser -S -D -H -u 10001 -G doompedia doompedia

COPY deploy/Caddyfile /etc/caddy/Caddyfile

USER doompedia
