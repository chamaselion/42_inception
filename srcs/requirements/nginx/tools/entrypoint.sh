#!/bin/bash
set -e

NGINX_CONF_PATH="/etc/nginx/conf.d/default.conf"
DOMAIN_NAME="${DOMAIN_NAME:-bszikora.42.fr}"
NGINX_PORT="${NGINX_PORT:-443}"
WP_PHP_PORT="${WP_PHP_PORT:-9000}"

mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/cert.key \
	-out /etc/nginx/ssl/cert.crt \
	-subj "/C=DE/ST=BW/L=Heilbronn/O=42/CN=$DOMAIN_NAME"

if [ -f /etc/nginx/nginx.conf ]; then
	sed -i -E 's@^\s*ssl_protocols\s+.*;@\tssl_protocols TLSv1.2 TLSv1.3;@' /etc/nginx/nginx.conf || true
fi

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/http.d/default.conf
cat << EOF > "$NGINX_CONF_PATH"
server {
	listen $NGINX_PORT ssl;
	listen [::]:$NGINX_PORT ssl;
	server_name $DOMAIN_NAME www.$DOMAIN_NAME;

	ssl_certificate /etc/nginx/ssl/cert.crt;
	ssl_certificate_key /etc/nginx/ssl/cert.key;
	ssl_protocols TLSv1.2 TLSv1.3;
	
	root /var/www/html;
	index index.php index.html index.htm;

	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}
	
	location ~ \.php$ {
		try_files \$fastcgi_script_name =404;
		
		fastcgi_pass wordpress:$WP_PHP_PORT;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		#fastcgi_param PATH_INFO \$fastcgi_path_info;
		#fastcgi_split_path_info ^(.+\.php)(/.*)\$;
		include fastcgi_params;
	}
}
EOF

chmod 600 /etc/nginx/ssl/cert.key
chmod 644 /etc/nginx/ssl/cert.crt

chown -R nginx:nginx /var/www/html 2>/dev/null || true

exec nginx -g 'daemon off;'
