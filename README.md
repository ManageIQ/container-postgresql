# container-postgresql

Container with PostgreSQL and built on ubi9, for ManageIQ.

## Usage

Environment Variables:

* Volumes
  * /var/lib/pgsql/data - Database cluster for PostgreSQL
* Environment
  * POSTGRESQL_USER           - Database user name
  * POSTGRESQL_PASSWORD       - User's password
  * POSTGRESQL_DATABASE       - Name of the database to create
  * POSTGRESQL_ADMIN_PASSWORD - (optional) Password for the 'postgres' administrative account
* Options
  * POSTGRESQL_MAX_CONNECTIONS           - (optional, default: 100)
  * POSTGRESQL_MAX_PREPARED_TRANSACTIONS - (optional, default: 0)
  * POSTGRESQL_SHARED_BUFFERS            - (optional, default: 32MB)
* Migration
  * POSTGRESQL_MIGRATION_REMOTE_HOST    - Hostname or IP address
  * POSTGRESQL_MIGRATION_ADMIN_PASSWORD - Password of remote 'postgres' user
  * POSTGRESQL_MIGRATION_IGNORE_ERRORS  - (yes/no, optional, default: no)

Example:

```sh
docker run -p 5432:5432 \
  -v /tmp/vol:/var/lib/pgsql/data \
  -e POSTGRESQL_USER=root \
  -e POSTGRESQL_PASSWORD=smartvm \
  -e POSTGRESQL_DATABASE=vmdb_production \
  docker.io/manageiq/postgresql:13
```

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

This project contains a copy of the [upstream sclorg/postgresql-container image](https://github.com/sclorg/postgresql-container/blob/642cde251f7f9518b3765b0ff56ef0d5f807e8af/13/Dockerfile.rhel9),
which was then modified for multi-arch support. That original source is licensed under the terms of the Apache 2.0 License.
