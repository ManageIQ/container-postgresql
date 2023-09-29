#!/bin/bash

if [ ! -f /opt/app-root/src/certificates/server.key ]; then
  echo "Skipping SSL setup, key not found."
else
  echo "Copying SSL certificates to /etc/pki/ and fixing permissions"
  cp /opt/app-root/src/certificates/server.crt /etc/pki/tls/certs/server.crt
  cp /opt/app-root/src/certificates/server.key /etc/pki/tls/private/server.key

  # Postgresql server will reject key files with liberal permissions
  chmod og-rwx /etc/pki/tls/private/server.key
fi
