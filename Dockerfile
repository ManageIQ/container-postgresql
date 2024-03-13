FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS manifest

COPY .git /tmp/.git

RUN cd /tmp && \
    sha=$(cat .git/HEAD | cut -d " " -f 2) && \
    if [[ "$(cat .git/HEAD)" == "ref:"* ]]; then sha=$(cat .git/$sha); fi && \
    echo "$(date +"%Y%m%d%H%M%S")-$sha" > /tmp/BUILD

################################################################################

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS postgresql_container_source

RUN microdnf -y --setopt=tsflags=nodocs install git
RUN git clone --depth 1 https://github.com/sclorg/postgresql-container /postgresql-container

################################################################################

FROM registry.access.redhat.com/ubi9/s2i-core AS base

# PostgreSQL image for OpenShift.
# Volumes:
#  * /var/lib/pgsql/data   - Database cluster for PostgreSQL
# Environment:
#  * $POSTGRESQL_USER     - Database user name
#  * $POSTGRESQL_PASSWORD - User's password
#  * $POSTGRESQL_DATABASE - Name of the database to create
#  * $POSTGRESQL_ADMIN_PASSWORD (Optional) - Password for the 'postgres'
#                           PostgreSQL administrative account

ENV POSTGRESQL_VERSION=13 \
    POSTGRESQL_PREV_VERSION=12 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres \
    APP_DATA=/opt/app-root

ENV SUMMARY="PostgreSQL is an advanced Object-Relational database management system" \
    DESCRIPTION="PostgreSQL is an advanced Object-Relational database management system (DBMS). \
The image contains the client and server programs that you'll need to \
create, run, maintain and access a PostgreSQL DBMS server."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="PostgreSQL 13" \
      io.openshift.expose-services="5432:postgresql" \
      io.openshift.tags="database,postgresql,postgresql13,postgresql-13" \
      io.openshift.s2i.assemble-user="26" \
      name="rhel9/postgresql-13" \
      com.redhat.component="postgresql-13-container" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#rhel" \
      usage="podman run -d --name postgresql_database -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db -p 5432:5432 rhel9/postgresql-13" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

EXPOSE 5432

COPY --from=postgresql_container_source /postgresql-container/13/root/usr/libexec/fix-permissions /usr/libexec/fix-permissions

# This image must forever use UID 26 for postgres user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.
RUN (dnf info postgresql-server); \
    if [ $? == 1 ]; then \
      ARCH=$(uname -m) && \
      dnf -y --setopt=protected_packages= remove redhat-release && \
      dnf -y remove *subscription-manager* && \
      dnf -y install \
        http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-release-9.0-24.el9.noarch.rpm \
        http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
        http://mirror.stream.centos.org/9-stream/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm && \
      dnf clean all && \
      rm -rf /var/cache/dnf; \
    fi && \
    { yum -y module enable postgresql:13 || :; } && \
    INSTALL_PKGS="rsync tar gettext bind-utils nss_wrapper postgresql-server postgresql-contrib" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    postgres -V | grep -qe "$POSTGRESQL_VERSION\." && echo "Found VERSION $POSTGRESQL_VERSION" && \
    (yum -y reinstall tzdata || yum -y update tzdata ) && \
    yum -y clean all --enablerepo='*' && \
    localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    chmod -R g+w /etc/pki/tls && \
    test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)" && \
    mkdir -p /var/lib/pgsql/data && \
    /usr/libexec/fix-permissions /var/lib/pgsql /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql \
    ENABLED_COLLECTIONS=

COPY --from=postgresql_container_source /postgresql-container/13/root /
COPY --from=postgresql_container_source /postgresql-container/13/s2i/bin/ $STI_SCRIPTS_PATH

# Not using VOLUME statement since it's not working in OpenShift Online:
# https://github.com/sclorg/httpd-container/issues/30
# VOLUME ["/var/lib/pgsql/data"]

# S2I permission fixes
# --------------------
# 1. unless specified otherwise (or - equivalently - we are in OpenShift), s2i
#    build process would be executed as 'uid=26(postgres) gid=26(postgres)'.
#    Such process wouldn't be able to execute the default 'assemble' script
#    correctly (it transitively executes 'fix-permissions' script).  So let's
#    add the 'postgres' user into 'root' group here
#
# 2. we call fix-permissions on $APP_DATA here directly (UID=0 during build
#    anyways) to assure that s2i process is actually able to _read_ the
#    user-specified scripting.
RUN usermod -a -G root postgres && \
    /usr/libexec/fix-permissions --read-only "$APP_DATA"

USER 26

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]

################################################################################

FROM base

MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

LABEL name="PostgreSQL" \
      summary="PostgreSQL Image" \
      vendor="ManageIQ" \
      description="PostgreSQL is a powerful, open source object-relational database system"

# Switch USER to root to add required repo and packages
USER root

RUN yum -y update postgresql-* && \
    yum clean all

ADD container-assets/container-scripts /opt/manageiq/container-scripts/
ADD container-assets/miq-run-postgresql /usr/bin/
ADD container-assets/on-start.sh ${APP_DATA}/src/postgresql-start/
ADD container-assets/pre-start.sh ${APP_DATA}/src/postgresql-pre-start/

# Loosen permission bits to avoid problems running container with arbitrary UID
RUN /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

RUN mkdir -p /opt/manageiq/manifest
COPY --from=manifest /tmp/BUILD /opt/manageiq/manifest

# Switch USER back to postgres
USER 26

CMD ["miq-run-postgresql"]
