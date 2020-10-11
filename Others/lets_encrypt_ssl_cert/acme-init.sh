#!/bin/bash

# see https://github.com/Neilpang/acme.sh for detail
# see https://github.com/Neilpang/acme.sh/wiki/How-to-issue-a-cert

# curl https://get.acme.sh | sh

# export CF_Key="GOT TOKEN FROM https://dash.cloudflare.com/profile"
# export CF_Email="admin@owent.net"

# In order to use the new token, the token currently needs access read access to Zone.Zone, and write access to Zone.DNS, across all Zones.
export CF_Token="GOT TOKEN FROM https://dash.cloudflare.com/profile" ;
export CF_Account_ID="6896d432a993ce19d72862cc8450db09" ;

# Get CF_Account_ID using
#   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
#     -H "Content-Type:application/json"                     \
#     -H "Authorization: Bearer $CF_Token"
# Or add read access to Account.Account Settings and then using 
#    curl -X GET "https://api.cloudflare.com/client/v4/accounts" \
#      -H "Content-Type: application/json"                       \
#      -H "Authorization: Bearer $CF_Token"

     
DOMAIN_NAME=owent.net;
ADMIN_EMAIL=$CF_Email;
INSTALL_CERT_DIR=/home/website/ssl;

~/.acme.sh/acme.sh --issue \
  -d $DOMAIN_NAME          \
  -d "*.$DOMAIN_NAME"      \
  -d "atframe.work"        \
  -d "*.atframe.work"      \
  -d "r-ci.com"            \
  -d "*.r-ci.com"          \
  -d "w-oa.com"            \
  -d "*.w-oa.com"          \
  -d "f-ha.com"            \
  -d "*.f-ha.com"          \
  -d "x-ha.com"            \
  -d "*.x-ha.com"          \
  -d "g-ha.com"            \
  -d "*.g-ha.com"          \
  --dns dns_cf             \
  --keylength ec-256   ; # 2048, 3072, 4096, 8192 or ec-256, ec-384

cp -f ~/.acme.sh/${DOMAIN_NAME}_*/* $INSTALL_CERT_DIR;
chown nginx:users -R $INSTALL_CERT_DIR;


# ~/.acme.sh/acme.sh --cron;
