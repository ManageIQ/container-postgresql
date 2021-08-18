FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS manifest

COPY .git /tmp/.git

RUN cd /tmp && \
    sha=$(cat .git/HEAD | cut -d " " -f 2) && \
    if [[ "$(cat .git/HEAD)" == "ref:"* ]]; then sha=$(cat .git/$sha); fi && \
    echo "$(date +"%Y%m%d%H%M%S")-$sha" > /tmp/BUILD

FROM centos/postgresql-10-centos8:latest

MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

LABEL name="PostgreSQL" \
      summary="PostgreSQL Image" \
      vendor="ManageIQ" \
      description="PostgreSQL is a powerful, open source object-relational database system"

ENV CONTAINER_SCRIPTS_ROOT=/opt/manageiq/container-scripts/ \
    START_HOOKS_DIR=/opt/app-root/src/postgresql-start/

# Switch USER to root to add required repo and packages
USER root

RUN yum -y update postgresql-* && \
    yum clean all

ADD container-assets/container-scripts ${CONTAINER_SCRIPTS_ROOT}
ADD container-assets/on-start.sh ${START_HOOKS_DIR}
ADD container-assets/pre-start.sh ${APP_DATA}/src/postgresql-pre-start/

# Loosen permission bits to avoid problems running container with arbitrary UID
RUN /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

RUN mkdir -p /opt/manageiq/manifest
COPY --from=manifest /tmp/BUILD /opt/manageiq/manifest

# Switch USER back to postgres
USER 26
