#!/bin/sh

# see https://certbot.eff.org/ for detail

CERT_DIR=/etc/letsencrypt/live;
DOMAIN_NAME=owent.net;
ADMIN_EMAIL=admin@owent.net;

yum install epel-release;
yum install certbot;

certbot certonly -m $ADMIN_EMAIL --webroot \
    -w /home/website/owent_blog -d owent.net -d www.owent.net \
    -w /home/website/angel_blog -d gf.owent.net -d angel.owent.net \
    ;

cp -f $CERT_DIR/$DOMAIN_NAME/* /home/website/ssl/angel;

chown nginx:users -R /home/website/ssl/angel;
