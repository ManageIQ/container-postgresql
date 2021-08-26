#!/bin/bash

if [ ! -f /opt/app-root/src/certificates/server.key ]; then
  echo "Skipping SSL setup, key not found."
else
  cp /opt/app-root/src/certificates/server.crt /var/lib/pgsql/data/userdata/server.crt
  cp /opt/app-root/src/certificates/server.key /var/lib/pgsql/data/userdata/server.key

  # Postgresql server will reject key files with liberal permissions
  chmod og-rwx /var/lib/pgsql/data/userdata/server.key
fi
