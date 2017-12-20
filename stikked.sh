#!/bin/bash

notice() {
    echo "$*" 1>&2
}

die() {
    notice "$*"
    exit 1
}

check_conf_val() {
    if [[ -z "$2" || $2 =~ [[:cntrl:]]|[[:space:]] ]]; then
        die "Bad $1 read from '$CONFIG' file."
    fi
}

for CONFIG in /etc/stikked/stikkedrc ${HOME}/.stikked; do
    if [[ -s "$CONFIG" ]]; then
        BASEURL=$(awk -F '=' '$1 == "base_url" { print $2 }' $CONFIG)
        APIKEY=$(awk -F '=' '$1 == "api_key" { print $2 }' $CONFIG)
        EXPIRE=$(awk -F '=' '$1 == "expire" && $2 ~ /^[0-9]+$/ { print $2 }' $CONFIG)
        PRIVATE=$(awk -F '=' '$1 == "private" && $2 ~ /^[01]$/ { print $2 }' $CONFIG)
        STRIP=$(awk -F '=' '$1 == "strip_url" && $2 ~ /^[yn]$/ { print $2 }' $CONFIG)
        check_conf_val 'server url' "$BASEURL"
        if [[ "${BASEURL:${#BASEURL}-1}" != '/' ]]; then
            BASEURL="${BASEURL}/"
        fi
        APIURL="${BASEURL}api/create"
        if [[ -n "$APIKEY" ]]; then
            check_conf_val 'API key' "$APIKEY"
            APIURL="${APIURL}?apikey=${APIKEY}"
        fi
    fi
done

if [[ -z "$BASEURL" ]]; then
    die "Please create '${HOME}/.stikked' file with your settings."
fi

for TOOL in tr mktemp file perl curl python; do
    if [[ -z "$(which $TOOL)" ]]; then
        die "Please install '$TOOL' to make ${0##*/} work."
    fi
done

LNG=''
XCLIP=''
XCLIPMSG=''
DATA=''
DEXT=''

if [[ -n "$DISPLAY" ]]; then
    XCLIP=$(which xclip)
    if [[ -n "$XCLIP" ]]; then
        XCLIPMSG=" (copied to clipboard)"
    else
        XCLIPMSG=" (consider installing xclip to have links copied to clipboard)"
    fi
fi

while [[ $# -gt 0 ]]; do
    if [[ $1 =~ ^(-p|-f|--permanent|--forever)$ ]]; then
        EXPIRE=0
    elif [[ $1 == '--private' ]]; then
        PRIVATE='1'
    elif [[ $1 =~ ^(-l|--lang(uage)?)$ ]]; then
        LNG=$2
        shift
    elif [[ $1 =~ ^(-t|-e|--exp(ire)?)$ ]]; then
        if [[ $2 =~ ^[0-9]+$ ]]; then
            EXPIRE=$2
        else
            die "Bad expiration value: '$2'"
        fi
        shift
    elif [[ $1 == '--noclip' ]]; then
        XCLIP=''
        XCLIPMSG=''
    elif [[ $1 =~ ^- ]]; then
        die "Bad argument: $1"
    elif [[ -r "$1" ]]; then
        DATA="$1"
    elif [[ $1 == 'js' ]]; then
        LNG='javascript'
    else
        if grep -wq $1 <<< "$(curl -s ${APIURL/\/create/\/langs} | python -m json.tool | awk -F '"' '{ print $2 }')"; then
            LNG=$1
        else
            notice "Skipped invalid argument: $1"
        fi
    fi
    shift
done

if [[ -n "$DATA" ]]; then
    if [[ ${DATA##*/} =~ \. ]]; then
        DEXT=${DATA##*.}
    fi
else
    TMPF=$(mktemp)
    if [[ -z "$TMPF" || ! -w "$TMPF" ]]; then
        die "Failed to create temp file. Please make sure 'mktemp' works."
    fi
    trap "rm -f '$TMPF'" EXIT
    cat 1>"$TMPF"
    DATA="$TMPF"
fi

if [[ -n "$DEXT" ]]; then
    case "$DEXT" in
        (go|php|diff|sql|css|lua|c|cpp|xml|awk|ini|java|reg|vim|tcl|xpp) LNG="$DEXT";;
        (sh) LNG='bash';;
        (pl|pm) LNG='perl';;
        (js) LNG='javascript';;
        (py) LNG='python';;
        (nsi) LNG='nsis';;
        (pas|pp) LNG='pascal';;
        (cmd|bat) LNG='dos';;
        (htm|html|xhtml) LNG='html5';;
        (txt|log) LNG='text';;
        (patch) LNG='diff';;
        (h) LNG='c';;
        (hpp) LNG='cpp';;
    esac
fi

if [[ -z "$LNG" ]]; then
    CT=$(file -Lb --mime-type "$DATA")
    case "$CT" in
        (text/x-shellscript) LNG='bash';;
        (text/x-perl) LNG='perl';;
        (text/x-python) LNG='python';;
        (text/x-pascal) LNG='pascal';;
        (text/html) LNG='html5';;
        (text/plain) LNG='text';;
        (text/x-php) LNG='php';;
        (text/x-diff) LNG='diff';;
        (text/xml) LNG='xml';;
        (text/x-c++) LNG='cpp';;
        (text/x-objective-c) LNG='objc';;
        (text/x-c) LNG='c';;
        (text/x-lisp) LNG='lisp';;
        (text/x-ruby) LNG='ruby';;
        (text/x-lua) LNG='lua';;
        (text/x-tcl) LNG='tcl';;
        (text/x-asm) LNG='asm';;
        (text/x-makefile) LNG='make';;
        (text/x-msdos-batch) LNG='dos';;
    esac
fi

URL=$(tr -d "\r" 0<"$DATA" | perl -pe 'chomp if eof' | curl -s -d lang=${LNG:-text} -d private=${PRIVATE:-1} -d expire=${EXPIRE:-525600} --data-urlencode text@- "$APIURL")

if [[ ! $? -eq 0 ]]; then
    die "Failed to fetch URL."
elif [[ ! $URL =~ ^${BASEURL} ]]; then
    die "Fail: $URL"
fi

if [[ $STRIP =~ ^(y|yes)$ ]]; then
    URL=${URL/\/view/}
fi

if [[ -n "$XCLIP" ]]; then
     printf "%s" "$URL" | xclip -selection clipboard
fi

echo "${URL}${XCLIPMSG}"
