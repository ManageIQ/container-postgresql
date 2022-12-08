#!/bin/bash

psql --command "ALTER ROLE \"${POSTGRESQL_USER}\" SUPERUSER;"

if [ -f /etc/pki/tls/private/server.key ]; then
  sed -i 's/host\(\b.*\)/hostssl\1/g' /var/lib/pgsql/data/userdata/pg_hba.conf

  sed -i 's/.*ssl = off.*/ssl = on/g' /var/lib/pgsql/data/userdata/postgresql.conf
  sed -i 's/.*ssl_cert_file.*/ssl_cert_file = \/etc\/pki\/tls\/certs\/server.crt/g' /var/lib/pgsql/data/userdata/postgresql.conf
  sed -i 's/.*ssl_key_file.*/ssl_key_file = \/etc\/pki\/tls\/private\/server.key/g' /var/lib/pgsql/data/userdata/postgresql.conf
fi
