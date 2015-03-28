#!/bin/bash

#default configuration
DOMAIN=""
FOLDER="<root-folder>"
PORT="80"

LANGUAGE=$1
shift
while [[ $# > 1 ]]
do
case "$1" in
    -d|--domain)
      DOMAIN="server_name $2;\n"
      #HAVE_DOMAIN=true
      shift
    ;;
    -p|--port)
      PORT="$2"
      #HAVE_DOMAIN=true
      shift
    ;;
    -f|--folder)
      FOLDER="$2"
      shift
    ;;
    -o|--output)
      OUTFILE="$2"
      shift
    ;;
esac
shift
done
#if [[ -z $OUTFILE && $HAVE_DOMAIN ]]; then
#  OUTFILE=$DOMAIN
#fi

case $LANGUAGE in
  python)
    template="server {\n
      listen $PORT;\n
      #listen 443 ssl;\n
      #ssl_certificate /etc/nginx/ssl/nginx.crt;\n
      #ssl_certificate_key /etc/nginx/ssl/nginx.key;\n
      \n
      $DOMAIN
      passenger_python $FOLDER/venv/bin/python;\n
      root $FOLDER/public;\n
      passenger_enabled on;\n
    }"
  ;;
  php)
    template="server {\n
       listen $PORT;\n
       #listen 443 ssl;\n
       #ssl_certificate /etc/nginx/ssl/nginx.crt;\n
       #ssl_certificate_key /etc/nginx/ssl/nginx.key;\n
       \n
       root $FOLDER;\n
       index index.php index.html index.htm;\n
       $DOMAIN
       \n
       location / {\n
        # First attempt to serve request as file, then\n
        # as directory, then fall back to displaying a 404.\n
        try_files \$uri \$uri/ /index.html;\n
        # Uncomment to enable naxsi on this location\n
        # include /etc/nginx/naxsi.rules\n
       }\n
       \n
       location ~ \.php\$ {\n
         try_files \$uri =404;\n
         fastcgi_pass unix:/var/run/php5-fpm.sock;\n
         fastcgi_index index.php;\n
         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n
         include fastcgi_params;\n
       }\n
     }"
  ;;
  node)
    template="server {\n
      listen $PORT;\n
      #listen 443 ssl;\n
      #ssl_certificate /etc/nginx/ssl/nginx.crt;\n
      #ssl_certificate_key /etc/nginx/ssl/nginx.key;\n
      \n
      $DOMAIN
      root $FOLDER/public;\n
      passenger_enabled on;\n
    }"
  ;;
  *)
    ERROR=true
  ;;
esac
if [[ -z $ERROR ]]; then
  if [[ $OUTFILE ]]; then
    echo "output file ->" $OUTFILE
    echo -e $template > $OUTFILE
  else
    echo -e $template
  fi
else
  echo -e "usage: python|php|node -f|--folder -d|--domain -o|--output"
fi
