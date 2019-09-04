#!/bin/sh

# see https://github.com/Neilpang/acme.sh for detail
# see https://github.com/Neilpang/acme.sh/wiki/How-to-issue-a-cert

# curl https://get.acme.sh | sh

# export CF_Key="GOT TOKEN FROM https://dash.cloudflare.com/profile"
# export CF_Email="admin@owent.net"

# In order to use the new token, the token currently needs access read access to Zone.Zone, and write access to Zone.DNS, across all Zones.
export CF_Token="GOT TOKEN FROM https://dash.cloudflare.com/profile"
export CF_Account_ID="b3b06592e853c937c79388e4bcb03ac7"

# Get CF_Account_ID by 
#   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
#     -H "Content-Type:application/json" \
#     -H "Authorization: Bearer $CF_Token"

     
DOMAIN_NAME=owent.net;
ADMIN_EMAIL=$CF_Email;
INSTALL_CERT_DIR=/home/website/ssl;

~/.acme.sh/acme.sh --issue \
  -d $DOMAIN_NAME          \
  -d "*.$DOMAIN_NAME"      \
  -d "*.api.$DOMAIN_NAME"  \
  -d "mogui.app"           \
  -d "*.mogui.app"         \
  -d "ouri.app"            \
  -d "*.ouri.app"          \
  --dns dns_cf             \
  --keylength ec-256   ; # 2048, 3072, 4096, 8192 or ec-256, ec-384

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

cp -f ~/.acme.sh/${DOMAIN_NAME}_*/* $INSTALL_CERT_DIR;
chown nginx:users -R $INSTALL_CERT_DIR;


# ~/.acme.sh/acme.sh --cron;
