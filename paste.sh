#!/bin/bash

if [[ -s "${HOME}/.stikked" ]]; then
  APIKEY=$(awk -F '=' '$1 == "apikey" { print $2 }' ${HOME}/.stikked)
  if [[ -z "$APIKEY" || $APIKEY =~ [[:cntrl:]]|[[:space:]] ]]; then
    echo "Bad API key read from '${HOME}/.stikked' file. Please note that no spaces, '=' or control characters are allowed."
    echo "Format: apikey=your_key"
    exit 1
  fi
else
  echo "Please put your API key into '${HOME}/.stikked' file."
  echo "Format: apikey=your_key"
  exit 1
fi

for TOOL in tr mktemp file perl curl; do
  if [[ -z "$(which $TOOL)" ]]; then
    echo "Please install '$TOOL' to make ${0##*/} work."
    exit 1
  fi
done

LNG=''
EXPIRE=$((($(date -d '1 year' +%s) - $(date +%s)) / 60))

XCLIP=''
XCLIPMSG=''
if [[ -n "$DISPLAY" ]]; then
  XCLIP=$(which xclip)
  if [[ -n "$XCLIP" ]]; then
    XCLIPMSG=" (copied to clipboard)"
  else
    XCLIPMSG=" (consider installing xclip to have links copied to clipboard)"
  fi
fi

DATA=''
DEXT=''

if [[ -n "$1" ]]; then
  if [[ -r "$1" ]]; then
    DATA="$1"
  else
    LNG=$1
  fi
fi

if [[ -n "$DATA" ]]; then
  if [[ ${DATA##*/} =~ "." ]]; then
    DEXT=${DATA##*.}
  fi
else
  TMPF=$(mktemp)
  if [[ -z "$TMPF" || ! -w "$TMPF" ]]; then
    echo "Failed to create temp file. Please make sure 'mktemp' works."
    exit 1
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
  CT=$(file -L -b --mime-type "$DATA")
  case "$CT" in
    (text/x-shellscript) LNG='bash';;
    (text/x-perl) LNG='perl';;
    (text/x-python) LNG='python';;
    (text/html) LNG='html5';;
    (text/plain) LNG='text';;
    (text/x-php) LNG='php';;
    (text/x-diff) LNG='diff';;
    (text/x-c) LNG='c';;
  esac
fi

URL=$(tr -d "\r" 0<"$DATA" | perl -pe 'chomp if eof' | curl -s -d lang=${LNG:-text} -d private=1 -d expire=$EXPIRE --data-urlencode text@- "https://pbin.cf/api/create?apikey=$(<${HOME}/.stikked)" | sed 's#/view##')
if [[ -n "$XCLIP" ]]; then
   printf "%s" "$URL" | xclip -selection clipboard
fi
echo "${URL}${XCLIPMSG}"
