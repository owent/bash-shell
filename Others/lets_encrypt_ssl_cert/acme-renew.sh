#!/bin/bash

# see https://github.com/Neilpang/acme.sh for detail
# see https://github.com/Neilpang/acme.sh/wiki/How-to-issue-a-cert

# curl https://get.acme.sh | sh

DOMAIN_NAME=owent.net;
INSTALL_CERT_DIR=/home/website/ssl;

# using a custom port
# ACME_SH_HTTP_PROT=88;
# firewall-cmd --add-port=tcp/$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;

# using a custom tls port
# ACME_SH_TLS_PROT=8443;
# firewall-cmd --add-port=tcp/$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;

~/.acme.sh/acme.sh --renew-all --ecc ;

cp -f ~/.acme.sh/${DOMAIN_NAME}_*/* $INSTALL_CERT_DIR;
chown nginx:users -R $INSTALL_CERT_DIR;

systemctl reload nginx;

# using a custom port
# firewall-cmd --add-port=$ACME_SH_HTTP_PROT/tcp;
# firewall-cmd --reload;

# using a custom tls port
# firewall-cmd --add-port=$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;
