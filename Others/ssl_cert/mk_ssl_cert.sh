#!/usr/bin/env bash

# 多域名适配见 openssl.cnf: [ alt_names ]
# 默认配置见 openssl.cnf: [ req_distinguished_name ]
# Common Name 必须在DNS.x中出现
# 这个配置文件修改的地方有
#   1. 弱化CA签证检查（policy_match.stateOrProvinceName 和 policy_match.organizationName）
#   2. 开启v3_req扩展（req.req_extensions）
#   3. 修改了证书信息默认值
#   4. 增加了别名区（v3_req.subjectAltName）
#   5. 别名DNS配置（[ alt_names ]）

# 注意: CA/serial 内放置了证书序列号，CA证书签证的每一个证书序号必须唯一，所以如果误删了CA目录或serial，需要人工保证序号唯一
#      如果签证失败，请尝试先记下CA/serial内的内容，然后移除CA文件夹，再使用 $0 -n [CA/serial的内容重试]

CERT_SVR_NAME=server;
CERT_CLI_NAME=;
CERT_CONF_PATH=openssl.cnf;

CERT_CRYPTO_LEN=2048;
CERT_CA_SERIAL=00;
CERT_CA_TIME=3650;

while getopts "c:f:hl:n:s:t:" OPTION; do
    case $OPTION in
        c)
            CERT_CLI_NAME="OPTARG";
        ;;
        f)
            CERT_CONF_PATH="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options]";
            echo "options:";
            echo "-c=[client cert name]       set client cert name.";
            echo "-f=[configure file]         set configure file(default=$CERT_CONF_PATH).";
            echo "-h                          help message.";
            echo "-l=[cert crypto lengtn]     set cert crypto lengtn(default=$CERT_CRYPTO_LEN).";
            echo "-n=[ca serial]              serial if init ca work dir(default=$CERT_CA_SERIAL).";
            echo "-s=[server cert name]       set server cert name(default=$CERT_SVR_NAME).";
            echo "-t=[ca expire time]         set new ca cert expire time in day(default=$CERT_CA_TIME).";
            exit 0;
        ;;
        l)
            CERT_CRYPTO_LEN=$OPTARG;
        ;;
        n)
            CERT_CA_SERIAL="$OPTARG";
        ;;
        s)
            CERT_SVR_NAME="$OPTARG";
        ;;
        t)
            CERT_CA_TIME=$OPTARG;
        ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

# 需要的目录和文件
if [ ! -e CA ]; then
    echo "mkdir CA";
    mkdir -p CA/{certs,crl,newcerts,private};
    touch CA/index.txt;
    echo $CERT_CA_SERIAL > CA/serial;
fi

if [ ! -e ca.key ] || [ ! -e ca.crt ]; then
    echo "generate ca cert";
    openssl req -new -x509 -days $CERT_CA_TIME -keyout ca.key -out ca.crt -config $CERT_CONF_PATH;
fi

# 生成证书文件
function mk_cert() {
    CERT_NAME=$1;
    openssl genrsa -out $CERT_NAME.key $CERT_CRYPTO_LEN;
    openssl req -new -key $CERT_NAME.key -out $CERT_NAME.csr -config $CERT_CONF_PATH;
    openssl req -text -noout -in $CERT_NAME.csr;
}

# 服务器证书 
if [ ! -z "$CERT_SVR_NAME" ]; then
    # 服务器证书
    mk_cert $CERT_SVR_NAME;
    # 签证
    openssl ca -in $CERT_SVR_NAME.csr -out $CERT_SVR_NAME.crt -cert ca.crt -keyfile ca.key -extensions v3_req -config $CERT_CONF_PATH;
fi

# 用于客户端验证的个人证书
if [ ! -z "$CERT_CLI_NAME" ]; then
    mk_cert $CERT_CLI_NAME;
    openssl  pkcs12 -export -inkey $CERT_CLI_NAME.key -in $CERT_CLI_NAME.crt -out $CERT_CLI_NAME.p12;
fi