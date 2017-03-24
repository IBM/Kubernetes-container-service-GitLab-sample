FROM alpine:3.5

ENV LANG en_US.utf8

COPY install.sh entrypoint.sh /
RUN adduser -D -s /bin/sh -g 'Gitlab' git && sh /install.sh && rm /install.sh

ENTRYPOINT ["/entrypoint.sh"]
