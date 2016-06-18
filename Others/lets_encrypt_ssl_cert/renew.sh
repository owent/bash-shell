#!/bin/sh

CERT_DIR=/etc/letsencrypt/live;
DOMAIN_NAME=owent.net;

certbot renew --quiet;

cp $CERT_DIR/$DOMAIN_NAME/* /home/website/ssl/angel;

chown nginx:users -R /home/website/ssl/angel;

systemctl reload nginx;
