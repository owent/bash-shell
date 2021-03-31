# 默认配置见 cfssl-ca-config.json 和 cfssl-csr.json

CERT_PROFILE_NAME=peer;
CERT_NAME=peer;
CERT_PROFILE_PATH=cfssl-ca-config.json;
CERT_CONF_PATH=cfssl-csr.json;

#CERT_RSA_CRYPTO_LEN=384; # 256,384,521 for ecdsa
#CERT_ECC_CURVE=ecdsa;    # ecdsa,rsa
CERT_CA_NAME=ca;

while getopts "c:f:hp:r:s:" OPTION; do
    case $OPTION in
        a)
            CERT_CA_NAME="$OPTARG";
        ;;
        c)
            CERT_NAME="$OPTARG";
        ;;
        f)
            CERT_CONF_PATH="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options]";
            echo "options:";
            echo "-a=[ca cert name]           set ca cert name(default=$CERT_CA_NAME).";
            echo "-c=[cert name]              set cert name(default=$CERT_NAME).";
            echo "-f=[configure file]         set configure file(default=$CERT_CONF_PATH).";
            echo "-h                          help message.";
            echo "-p=[profile name]           set cert profile name(default=$CERT_PROFILE_NAME).";
            echo "-r=[profiles file]          set configure file(default=$CERT_PROFILE_PATH).";
            echo "-s=[server cert name]       set server cert name(default=$CERT_SVR_NAME).";
            exit 0;
        ;;
        p)
            CERT_PROFILE_NAME="$OPTARG";
        ;;
        r)
            CERT_PROFILE_PATH="$OPTARG";
        ;;
        s)
            CERT_SVR_NAME="$OPTARG";
        ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

# 生成CA证书文件
if [[ -e $CERT_CA_NAME.key ]] && [[ -e $CERT_CA_NAME.crt ]]; then
    CERT_CA_KEY_PATH=$CERT_CA_NAME.key;
    CERT_CA_CERT_PATH=$CERT_CA_NAME.crt;
elif [[ -e $CERT_CA_NAME-key.pem ]] && [[ -e $CERT_CA_NAME.pem ]]; then
    CERT_CA_KEY_PATH=$CERT_CA_NAME-key.pem;
    CERT_CA_CERT_PATH=$CERT_CA_NAME.pem;
else
    echo "generate ca cert";
    cfssl genkey -config=$CERT_PROFILE_PATH -initca $CERT_CONF_PATH | cfssljson -bare $CERT_CA_NAME ;
    CERT_CA_KEY_PATH=$CERT_CA_NAME-key.pem;
    CERT_CA_CERT_PATH=$CERT_CA_NAME.pem;
fi

if [[ -e $CERT_NAME.key ]] && [[ -e $CERT_NAME.crt ]]; then
    echo "$CERT_NAME.key and $CERT_NAME.crt found, skip generate cert".
elif [[ -e $CERT_NAME-key.pem ]] && [[ -e $CERT_NAME.pem ]]; then
    echo "$CERT_NAME-key.pem and $CERT_NAME.pem found, skip generate cert".
else
    echo "Generate $CERT_NAME-key.pem and $CERT_NAME.pem with ca $CERT_CA_CERT_PATH and $CERT_CA_KEY_PATH;";
    cfssl gencert -config=$CERT_PROFILE_PATH -profile=$CERT_PROFILE_NAME -ca $CERT_CA_CERT_PATH -ca-key $CERT_CA_KEY_PATH cfssl-csr.json | cfssljson -bare $CERT_NAME
fi