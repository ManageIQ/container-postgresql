FROM centos/postgresql-10-centos7:latest

MAINTAINER ManageIQ https://github.com/ManageIQ/manageiq-appliance-build

ENV CONTAINER_SCRIPTS_ROOT=/opt/manageiq/container-scripts/ \
    START_HOOKS_DIR=/opt/app-root/src/postgresql-start/

# Switch USER to root to add required repo and packages
USER root

RUN yum -y update rh-postgresql10-* && \
    yum clean all

ADD container-assets/container-scripts ${CONTAINER_SCRIPTS_ROOT}
ADD container-assets/on-start.sh ${START_HOOKS_DIR}

# Loosen permission bits to avoid problems running container with arbitrary UID
RUN /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

# Switch USER back to postgres
USER 26
