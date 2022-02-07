#!/usr/bin/env bash
###############################################################################################
# 
# Dockerfile for single container Hyrax
#
#
# Some shell state reference:
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
#
# In general use "set -e" when running commands that matter and don't use
# it for debugging stuff.
#
# Set one or more individual labels
FROM centos:7

# ENV DEPLOYMENT_CONTEXT="ROOT"
ENV DEFAULT_NGAP_DEPLOYMENT_CONTEXT="ngap"

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT ${DEPLOYMENT_CONTEXT:-"ROOT"}
RUN echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

RUN export NOW=`date +%s`

#
# Hyrax Components Version Negotiation
#
ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"${NOW}"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-${LIBDAP_VERSION}.el7.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} /${LIBDAP_RPM}

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-${BES_VERSION}.static.el7.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} /${BES_RPM}

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"unknown"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

ARG NGAP_DISTRO
ENV NGAP_DISTRO=${NGAP_DISTRO:-"ngap-${OLFS_VERSION}-webapp"}
RUN echo "NGAP_DISTRO: ${NGAP_DISTRO}"
COPY ${NGAP_DISTRO}.tgz /${NGAP_DISTRO}.tgz
RUN tar -tf /${NGAP_DISTRO}.tgz

ARG TOMCAT_CONNECTION_TIMEOUT_MS
ENV TOMCAT_CONNECTION_TIMEOUT_MS=${TOMCAT_CONNECTION_TIMEOUT_MS:-"1000000"}
RUN echo "TOMCAT_CONNECTION_TIMEOUT_MS: ${TOMCAT_CONNECTION_TIMEOUT_MS}"

LABEL vendor="OPeNDAP Inc."
LABEL org.opendap.hyrax.version=snapshot
LABEL org.opendap.hyrax.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED" >&2 ; else echo "DEVELOPER_MODE: DISABLED" >&2 ; fi

# Update and install the needful.
RUN yum -y install tomcat unzip which awscli autoconf automake git bc emacs vim
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# howerver, to be run, so install them as part of this Dockerfile.
RUN yum -y update


################################################################
# Tomcat environment (Tomcat installed above by via yum)
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV CATALINA_HOME /usr/share/tomcat
ENV PATH ${CATALINA_HOME}/bin:${PATH}
RUN echo "CATALINA_HOME: ${CATALINA_HOME}" >&2


################################################################
# Retrieve and install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the latest libdap snapshot. rpm: ${LIBDAP_RPM}" \
    && ls -l ./libdap* \
    && yum -y install ./${LIBDAP_RPM} \
    && rm -f ./${LIBDAP_RPM}

################################################################
# Retrieve and install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, and installing the latest besd snapshot. rpm: $BES_RPM" \
    && ls -l ./bes* \
    && yum -y install ./${BES_RPM} \
    && rm -f ./${BES_RPM}

RUN echo "besdaemon is here: "`which besdaemon`

################################################################
# Retrieve, verify, and install the NGAP/OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

# NGAP package uses the OLFS_VERSION number. jhrg 4/2/21
RUN set -e \
    && echo "Installing the latest NGAP distribution (${NGAP_DISTRO})." \
    && echo "working dir: "$(pwd)"    ROOT: ${ROOT}" \
    && tar -C "${ROOT}" -xzvf /${NGAP_DISTRO}.tgz \
    && ls -l "${ROOT}" \
    && echo "Unpacking warfile..." \
    && unzip -o ${ROOT}/${NGAP_DISTRO}/${DEFAULT_NGAP_DEPLOYMENT_CONTEXT}.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up." \
    && rm -rf ${ROOT}/${NGAP_DISTRO} ./${NGAP_DISTRO}.tgz

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs



# Install our modified server.xml so that the server compresses responses and
# sets the connectionTimeout to 1000 seconds
COPY tomcat7-server.xml /
RUN set -e \
    && mv /tomcat7-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml

# Install our modified tomcat.conf so that the server use the memory.
COPY tomcat.conf /
RUN set -e \
    && mv /tomcat.conf /etc/tomcat/tomcat.conf \
    && chown -R tomcat:tomcat /etc/tomcat/tomcat.conf

# Install Session Manager jars into the Tomcat: ${CATALINA_HOME}/lib
RUN set -e \
    && echo "Installing Session Manager jar files. Cloning OLFS..." \
    && git clone --depth 1 https://github.com/OPENDAP/olfs \
    && echo "Copying elasticache client" \
    && cp olfs/resources/ngap/lib/elasticache-java-cluster-client-1.1.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-2.3.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager TC7" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-tc7-2.3.2.jar ${CATALINA_HOME}/lib \
    && chown -R tomcat:tomcat  ${CATALINA_HOME}/lib \
    && rm -rfv olfs

RUN yum clean all

################################################################
#
# Retrieve, verify, and install the hyrax_regression_tests
# project
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV TEST_INSTALL_DIR="/hyrax_regression_tests"
RUN set -e \
    && echo "Retrieving, and building hyrax regression tests." \
    && echo "h_r_t will be in: ${TEST_INSTALL_DIR}" \
    && mkdir -p ${TEST_INSTALL_DIR} \
    && git clone -v https://github.com/opendap/hyrax_regression_tests ${TEST_INSTALL_DIR} \
    && cd ${TEST_INSTALL_DIR} \
    && git status \
    && autoreconf -vif \
    && ./configure


# In order to get the executable "testsuite" to build we have to run
# "make check" But that will fail at build time so the "make check" call
# ends up pretty tortured to avoid a build error.
RUN set -e \
    && cd ${TEST_INSTALL_DIR} \
    && make testsuite > mk.log 2>&1 \
    && echo "SUCCESS: hyrax_regression_tests ready!"

COPY beslog2json.awk /
RUN  set -e && chmod +x beslog2json.awk
COPY entrypoint.sh /
RUN  set -e && chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN  set -e && chown -R bes /etc/bes
USER root

CMD ["-"]

