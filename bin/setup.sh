#!/usr/bin/env sh

echo -e "******************************"
echo -e "** nginx server_name SETUP ***"
echo -e "******************************"

if [ ! -z "$ENVIRONMENT" ]; then
    echo -e "Setting server_name to ${PROJECT}-${ENVIRONMENT}.${SITE_URL} ${ENVIRONMENT}-${PROJECT}.${SITE_URL}"
    sed -i -e "s#server_name \"\";#server_name \"${PROJECT}-${ENVIRONMENT}.${SITE_URL} ${ENVIRONMENT}-${PROJECT}.${SITE_URL}\";#g" /etc/nginx/conf.d/default.conf
elif [ ! -z "$PROJECT" ]; then
    echo -e "Setting server_name to ${PROJECT}.${SITE_URL}"
    sed -i -e "s#server_name \"\";#server_name \"${PROJECT}.${SITE_URL}\";#g" /etc/nginx/conf.d/default.conf
fi


echo -e "******************************"
echo -e "******* POSTFIX SETUP ********"
echo -e "******************************"

# Set up a relay host, if needed
if [ ! -z "$RELAYHOST" ]; then
	echo -e "Forwarding all emails to $RELAYHOST"
	postconf -e "relayhost=$RELAYHOST"

	if [ -n "$RELAYHOST_USERNAME" ] && [ -n "$RELAYHOST_PASSWORD" ]; then
		echo -e "using username $RELAYHOST_USERNAME and password."
		echo "$RELAYHOST $RELAYHOST_USERNAME:$RELAYHOST_PASSWORD" >> /etc/postfix/sasl_passwd

		postmap hash:/etc/postfix/sasl_passwd
		postconf -e "smtp_sasl_auth_enable=yes"
		postconf -e "smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd"
		postconf -e "smtp_sasl_security_options=noanonymous"
	else
		echo -e "without any authentication. Make sure your server is configured to accept emails coming from this IP."
	fi
fi

# Activate TLS usage
if [ ! -z "$SMTP_USE_TLS" ]; then
	postconf -e "smtp_use_tls=yes"
	postconf -e "smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt"
fi


echo -e "******************************"
echo -e "******* PHP SETUP ************"
echo -e "******************************"

# Enable Xdebug
[[ -z "$XDEBUG_INSTALL" ]] && XDEBUG_INSTALL="$DEVELOPMENT_ENV"
[[ -z "$XDEBUG_REMOTE_HOST" ]] && XDEBUG_REMOTE_HOST="$VM_HOST_IP"
[[ -z "$XDEBUG_IDE_KEY" ]] && XDEBUG_IDE_KEY="mykey"
if [ ! -z "$XDEBUG_INSTALL" ] && [ ! -f /.deployed_xdebug ]; then
    if [ ! -f /etc/php7/conf.d/xdebug.ini ]; then
        echo -e "zend_extension=xdebug.so\nxdebug.remote_enable=on\nxdebug.remote_host=$XDEBUG_REMOTE_HOST\nxdebug.remote_port=9000\nxdebug.remote_autostart=0\nxdebug.max_nesting_level=500\n" > /etc/php7/conf.d/xdebug.ini
        echo -e "export export XDEBUG_CONFIG=\"idekey=$XDEBUG_IDE_KEY\"" >> /root/.bashrc
    fi
    apk --no-cache add php7-xdebug
    touch /.deployed_xdebug
fi

# Set "from" Email-Address
if [ ! -z "$MAILFROM" ]; then
    echo -e "using email-address $MAILFROM to send the emails"
    sed -i "s/^sendmail_path.*/sendmail_path = sendmail -t -i -f '${MAILFROM}'/g" /etc/php7/php.ini
    sed -i "s/^mail.force_extra_parameters.*/mail.force_extra_parameters = \"-f ${MAILFROM}\"/g" /etc/php7/php.ini
fi

# Bash prompt configuration
echo -e "export export PS1=\"\\w \\$ \"" >> /root/.bashrc
