#!/bin/bash

psql --command "ALTER ROLE \"${POSTGRESQL_USER}\" SUPERUSER;"

if [ -f /opt/app-root/src/certificates/server.key ]; then
  sed -i 's/host\(\b.*\)/hostssl\1/g' /var/lib/pgsql/data/userdata/pg_hba.conf
fi
