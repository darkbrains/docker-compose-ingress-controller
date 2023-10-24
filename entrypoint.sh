#!/bin/sh
nginx -g "daemon off;" &
/app/script.sh
exec "$@"
