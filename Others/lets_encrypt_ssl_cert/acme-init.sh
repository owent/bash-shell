#!/bin/sh

# see https://github.com/Neilpang/acme.sh for detail
# see https://github.com/Neilpang/acme.sh/wiki/How-to-issue-a-cert

# curl https://get.acme.sh | sh

DOMAIN_NAME=owent.net;
ADMIN_EMAIL=admin@owent.net;
INSTALL_CERT_DIR=/home/website/ssl;

~/.acme.sh/acme.sh --issue \
  -d owent.net -w /home/website/owent_blog \
  -d www.owent.net -w /home/website/owent_blog \
  -d angel.owent.net -w /home/website/angel_blog \
  --keylength ec-256 ; # 2048, 3072, 4096, 8192 or ec-256, ec-384

# using a custom port
# ACME_SH_HTTP_PROT=88;
# firewall-cmd --add-port=tcp/$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;
# 
# ~/.acme.sh/acme.sh --issue \
#   -d owent.net -w /home/website/owent_blog --standalone --httpport $ACME_SH_HTTP_PROT \
#   -d www.owent.net -w /home/website/owent_blog --standalone --httpport $ACME_SH_HTTP_PROT \
#   -d angel.owent.net -w /home/website/angel_blog --tls --standalone --httpport $ACME_SH_HTTP_PROT \
#   --keylength ec-256 ; # 2048, 3072, 4096, 8192 or ec-256, ec-384
# firewall-cmd --add-port=$ACME_SH_HTTP_PROT/tcp;
# firewall-cmd --reload;

# using a custom tls port
# ACME_SH_TLS_PROT=8443;
# firewall-cmd --add-port=tcp/$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;
# 
# ~/.acme.sh/acme.sh --issue \
#   -d owent.net -w /home/website/owent_blog --tls --tlsport $ACME_SH_TLS_PROT \
#   -d www.owent.net -w /home/website/owent_blog --tls --tlsport $ACME_SH_TLS_PROT \
#   -d angel.owent.net -w /home/website/angel_blog --tls --tlsport $ACME_SH_TLS_PROT \
#   --keylength ec-256 ; # 2048, 3072, 4096, 8192 or ec-256, ec-384
# 
# firewall-cmd --add-port=$ACME_SH_TLS_PROT/tcp;
# firewall-cmd --reload;

cp ~/.acme.sh/${DOMAIN_NAME}_*/* $INSTALL_CERT_DIR;
chown nginx:users -R $INSTALL_CERT_DIR;


# ~/.acme.sh/acme.sh --cron;
