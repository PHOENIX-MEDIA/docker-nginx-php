#!/usr/bin/env sh

sh /setup.sh
exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisord.conf