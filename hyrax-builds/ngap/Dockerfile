#!/usr/bin/env bash
###############################################################################################
# 
# Dockerfile for the NGAP deployment Hyrax container
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
FROM rockylinux:8

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

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION ${TOMCAT_VERSION:-"9.0.64"}
RUN echo "TOMCAT_VERSION: ${TOMCAT_VERSION}"
ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-${LIBDAP_VERSION}.el8.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} libdap-devel-* libdap-debuginfo-* /
RUN ls -l /libdap-*  >&2

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-${BES_VERSION}.static.el8.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} bes-devel-* bes-debuginfo-* /
RUN ls -l /bes-* >&2

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

LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi

################################################################
# Update and install the needful.
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && dnf update  -y
RUN set -e && dnf install -y make curl unzip which autoconf automake emacs vim
RUN set -e && dnf install -y diffutils
RUN set -e && dnf install -y procps
RUN set -e && dnf install -y python3 git bc valgrind gdb
# Temporary Hack to add Ant before we install Java-11 since it will install Java-8
#RUN set -e && dnf install -y ant
RUN set -e && dnf install -y java-11-openjdk
RUN set -e && dnf install -y java-11-openjdk-devel
# Temporary Hack to fix broken OpenJDK-11.0.20.0.8-2
RUN set -e && dnf install -y tzdata-java
# Temporary Hack to add missing Apache Portable Runtime library for Tomcat
RUN set -e && dnf install -y ant
RUN set -e && dnf install -y redhat-rpm-config
RUN set -e && dnf install -y apr-devel
RUN set -e && dnf install -y openssl-devel
#
RUN set -e && dnf clean all
#
RUN set -e && python3 -m pip install awscli

################################################################
# Install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the libdap rpm: ${LIBDAP_RPM}" >&2 \
    && ls -l ./libdap* \
    && dnf -y install ./libdap-*.rpm \
    && rm -f ./${LIBDAP_RPM}

RUN echo "libdap4 is installed."

################################################################
# Install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the latest BES rpm: ${BES_RPM}" >&2 \
    && ls -l ./bes* \
    && dnf -y install ./bes-*.rpm \
    && rm -f ./${BES_RPM}

RUN echo "besdaemon is here: "`which besdaemon`

################################################################
# Install and Setup Tomcat
#
# Make tomcat user and group
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e && useradd -m -U -d /home/tomcat -s /bin/false tomcat
#
# Install the Tomcat package that should have been copied into
# the root directory prior to this layer.
#
RUN set -e \
    && tar -xvf "/${TOMCAT_DISTRO}.tar.gz" -C /home/tomcat >&2 \
    && ln -s /home/tomcat/${TOMCAT_DISTRO} /usr/share/tomcat >&2 \
    && rm -rvf /usr/share/tomcat/webapps/* >&2 \
    && mkdir -p /var/log/tomcat \
    && chown -R tomcat:tomcat /var/log/tomcat /home/tomcat
COPY tomcat.service /etc/systemd/system/tomcat.service
RUN set -e && systemctl enable tomcat >&2
#RUN firewall-cmd --add-port 8080/tcp --permanent
#RUN firewall-cmd --reload

ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN set -e && echo "CATALINA_HOME: ${CATALINA_HOME}" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat9-server.xml /
RUN set -e \
    && mv /tomcat9-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml

RUN set -e \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/${TOMCAT_DISTRO}.tar.gz"  >&2

# Install the Tomcat Native-APR library.
#
RUN set -e \
    && export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which javac))))" >&2 \
    && echo $JAVA_HOME >&2 \
    && tar -xvf "/${CATALINA_HOME}/bin/tomcat-native.tar.gz" -C ${CATALINA_HOME}/bin >&2 \
    && cd ${CATALINA_HOME}/bin/tomcat-native-1.3.0-src/native >&2 \
    && ./configure >&2 \
    && make >&2 \
    && make install >&2 \
    && echo "SUCCESS: Tomcat Native-APR Library installed"

ENV CATALINA_OPTS "-Djava.library.path=/usr/local/apr/lib"

# Uninstall Java-1.8.0 installed by Ant
RUN set -e && yum remove -y java-1.8.0-openjdk >&2
RUN set -e && which java && java -version

################################################################
# Retrieve, verify, and install the NGAP/OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

# NGAP package uses the OLFS_VERSION number. jhrg 4/2/21
RUN set -e \
    && echo "Installing the latest NGAP distribution (${NGAP_DISTRO})." >&2 \
    && echo "working dir: "$(pwd)"    ROOT: ${ROOT}"  >&2 \
    && tar -C "${ROOT}" -xzvf /${NGAP_DISTRO}.tgz >&2 \
    && ls -l "${ROOT}" >&2 \
    && echo "Unpacking warfile..." >&2 \
    && unzip -o ${ROOT}/${NGAP_DISTRO}/${DEFAULT_NGAP_DEPLOYMENT_CONTEXT}.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up." >&2 \
    && rm -rf ${ROOT}/${NGAP_DISTRO} /${NGAP_DISTRO}.tgz

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs
################################################################

################################################################
# Install our modified tomcat.conf so that the server use the memory
# cached session state and not require sticky sessions to operate
# behind a load balancer.
#
COPY tomcat.conf /
RUN set -e \
    && mkdir -p /etc/tomcat \
    && mv /tomcat.conf /etc/tomcat/tomcat.conf \
    && chown -R tomcat:tomcat /etc/tomcat
#
# Install Memcached Session Manager jars into the Tomcat: ${CATALINA_HOME}/lib
RUN set -e \
    && echo "Installing Session Manager jar files. Cloning OLFS..." \
    && git clone --depth 1 https://github.com/OPENDAP/olfs \
    && echo "Copying elasticache client" \
    && cp olfs/resources/ngap/lib/elasticache-java-cluster-client-1.1.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-2.3.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager TC9" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-tc9-2.3.2.jar ${CATALINA_HOME}/lib \
    && chown -R tomcat:tomcat  ${CATALINA_HOME}/lib \
    && rm -rfv olfs

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

################################################################
# TEMPORARY
# Grab the cleanup files script for managing orphaned files
# from fileout_netcdf
COPY cleanup_files.sh /
RUN chmod +x /cleanup_files.sh
# TEMPORARY
################################################################

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

