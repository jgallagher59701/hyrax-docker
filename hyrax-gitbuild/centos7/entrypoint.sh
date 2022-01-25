#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## HYRAX ##################################" >&2
echo "Greetings, I am "`whoami`"." >&2
set -e
#set -x

bes_debug="${BES_DEBUG:- -d /dev/null,timing}"
echo "bes_debug: ${bes_debug}"
echo "CATALINA_HOME: ${CATALINA_HOME}"
export PATH=${CATALINA_HOME}/bin:$PATH

export prefix=${prefix:-}
echo "prefix: ${prefix}"

export PATH=$prefix/bin:$prefix/deps/bin:$PATH
echo "PATH: ${PATH}"

export DEPLOYMENT_CONTEXT="HYRAX_DEPLOYMENT_CONTEXT"
echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

# while true ; do sleep 1; done

################################################################################
# Inject one set of credentials into .netrc
# Only touch the .netrc file if all three environment variables are defined
#
ngap_netrc_file="${prefix}/etc/bes/ngap_netrc"
if [ -n "${HOST}" ]  &&  [ -n "${USERNAME}" ] &&  [ -n "${PASSWORD}" ]; then
    # machine is a domain name or a ip address, not a URL.
    echo "machine ${HOST}" | sed -e "s_https:__g"  -e "s_http:__g" -e "s+/++g" >> "${ngap_netrc_file}"
    echo "    login ${USERNAME}"    >> "${ngap_netrc_file}"
    echo "    password ${PASSWORD}" >> "${ngap_netrc_file}"
    chown bes:bes "${ngap_netrc_file}"
    chmod 400 "${ngap_netrc_file}"
    ls -l "${ngap_netrc_file}"  >&2
    cat "${ngap_netrc_file}" >&2
fi
################################################################################


################################################################################
# Inject user-access.xml document to define the servers relationship to
# EDL and the user access rules.
#
echo "CATALINA_HOME: ${CATALINA_HOME}" >&2
user_access_xml_file="/usr/share/tomcat/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/user-access.xml"
# Test if the user-access.xml env variable is set (by way of not unset) and not empty
if [ -n "${USER_ACCESS_XML}" ] ; then
    echo "${USER_ACCESS_XML}" > ${user_access_xml_file}
    echo "${user_access_xml_file} -" >&2
    cat ${user_access_xml_file} >&2
fi
################################################################################


################################################################################
# Inject BES configuration site.conf document to configure the BES to operate
# in the NGAP environment.
#
bes_site_conf_file="${prefix}/etc/bes/site.conf"
echo "bes_site_conf_file: ${bes_site_conf_file}" >&2
cat "${bes_site_conf_file}" >&2
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if [ -n "${BES_SITE_CONF}" ] ; then
    echo "Located environment variable BES_SITE_CONF. Value:" >&2
    echo "${BES_SITE_CONF}" >&2
    echo "${BES_SITE_CONF}" | sed -e "s+BES.LogName=stdout+BES.LogName=${prefix}/var/log/bes/bes.log+g" >> ${bes_site_conf_file}
    echo "Updated ${bes_site_conf_file}:" >&2
    cat ${bes_site_conf_file} >&2
fi
################################################################################


################################################################################
# Inject Tomcat's context.xml configuration document to configure the Tomcat to
# utilize Session Management in the NGAP environment.
#
tomcat_context_xml_file="/usr/share/tomcat/conf/context.xml"
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if [ -n "${TOMCAT_CONTEXT_XML}" ] ; then
    echo "${TOMCAT_CONTEXT_XML}" > ${tomcat_context_xml_file}
    echo "${tomcat_context_xml_file} - " >&2
    cat ${tomcat_context_xml_file} >&2
fi
################################################################################


################################################################################
# Inject an NGAP Cumulus Configuration
# Only amend the /etc/bes/site.conf file if all the necessary environment
# variables are defined
#
#if [ -n "${S3_DISTRIBUTION_ENDPOINT}" ] &&  \
#   [ -n "${S3_REFRESH_MARGIN}" ] && \
#   [ -n "${S3_AWS_REGION}" ] && \
#   [ -n "${S3_BASE_URL}" ]; then
#
#  echo "Amending BES ${bes_site_conf_file} file." >&2
#  {
#    echo "NGAP.S3.distribution.endpoint.url=${S3_DISTRIBUTION_ENDPOINT}"
#    echo "NGAP.S3.refresh.margin=${S3_REFRESH_MARGIN}"
#    echo "NGAP.S3.region=${S3_AWS_REGION}"
#    echo "NGAP.S3.url.base=${S3_BASE_URL}"
#  } | tee -a "${bes_site_conf_file}" >&2
#fi
################################################################################

if [ -n "${SERVER_HELP_EMAIL}" ] ; then
    echo "Found existing SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}" >&2
else
    SERVER_HELP_EMAIL="not_set"
     echo "SERVER_HELP_EMAIL is ${SERVER_HELP_EMAIL}" >&2
fi
if [ -n "${FOLLOW_SYMLINKS}" ] ; then
    echo "Found existing FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}" >&2
else
    FOLLOW_SYMLINKS="not_set";
     echo "FOLLOW_SYMLINKS is $FOLLOW_SYMLINKS" >&2
fi

if [ -n "${NCWMS_BASE}" ] ; then
    echo "Found existing NCWMS_BASE: ${NCWMS_BASE}" >&2
else
    NCWMS_BASE="https://localhost:8080"
    echo "Assigning default NCWMS_BASE: ${NCWMS_BASE}" >&2
fi
debug=false;

while getopts "de:sn:" opt; do
  echo "Processing command line opt: ${opt}" >&2
  case $opt in
    e)
      echo "Setting server admin contact email to: $OPTARG" >&2
      SERVER_HELP_EMAIL=$OPTARG
      ;;
    s)
      echo "Setting FollowSymLinks to: Yes" >&2
      FOLLOW_SYMLINKS="Yes"
      ;;
    n)
      echo "Setting ncWMS public facing service base to : $OPTARG" >&2
      NCWMS_BASE=$OPTARG
      ;;
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-e xxx] [-s] [-n yyy] [-d] "  >&2
      echo " -e xxx where xxx is the email address of the admin contact for the server."
      echo " -s When present causes the BES to follow symbolic links."
      echo " -n yyy where yyy is the protocol, server and port part "  >&2
      echo "    of the ncWMS service (for example http://foo.com:8090)."  >&2
      echo " -d Enables debugging output for this script."  >&2
      echo "EXITING NOW"  >&2
      exit 2;
      ;;
  esac
done

if [ $debug = true ];then
    echo "CATALINA_HOME: ${CATALINA_HOME}";  >&2
    ls -l "$CATALINA_HOME"  >&2
    ls -l "$CATALINA_HOME/bin/" >&2
    ls -l "$CATALINA_HOME/webapps/"  >&2
fi

if [ $debug = true ];then
    echo "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}"  >&2
    echo "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."  >&2
fi


# while true; do sleep 1; done

viewers_xml=$(find ${CATALINA_HOME}/webapps/ -name viewers.xml -print)
echo "viewers_xml: ${viewers_xml}"
if test -n "$viewers_xml"; then
  echo "NCWMS: Located viewers.xml here: ${viewers_xml}"
  sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${viewers_xml}
  if [ $debug = true ]; then
      echo "${viewers_xml}" >&2
      cat ${viewers_xml} >&2
  fi
else
  echo "NCWMS: Failed to locate viewers.xml in: ${CATALINA_HOME}/webapps Skipping."
fi

# modify bes.conf based on environment variables before startup.
#
if [ "${SERVER_HELP_EMAIL}" != "not_set" ]; then
    echo "Setting Admin Contact To: ${SERVER_HELP_EMAIL}"
    sed -i "s/admin.email.address@your.domain.name/${SERVER_HELP_EMAIL}/" ${prefix}/etc/bes/bes.conf
fi

if [ "${FOLLOW_SYMLINKS}" != "not_set" ]; then
    echo "Setting BES FollowSymLinks to YES."
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" ${prefix}/etc/bes/bes.conf
fi


# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c ${prefix}/etc/bes/bes.conf -r ${prefix}/var/run/bes.pid
besctl start ${bes_debug} >&2
status=$?
if [ $status -ne 0 ]; then
    echo "ERROR: Failed to start BES: $status" >&2
    exit $status
fi
besd_pid=`ps aux | grep besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "The BES is UP! pid: $besd_pid" >&2


# Start Tomcat process
/usr/libexec/tomcat/server start > /var/log/tomcat/console.log 2>&1 &
status=$?
tomcat_pid=$!
if [ $status -ne 0 ]; then
    echo "ERROR: Failed to start Tomcat: $status" >&2
    exit $status
fi
echo "Tomcat is UP! pid: $tomcat_pid" >&2

echo "Hyrax Has Arrived..." >&2

while /bin/true; do
    sleep 60
    besd_ps=`ps -f $besd_pid`;
    BESD_STATUS=$?

    tomcat_ps=`ps -f $tomcat_pid`;
    TOMCAT_STATUS=$?

    if [ $BESD_STATUS -ne 0 ]; then
        echo "ERROR: BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid" >&2
        echo "ERROR: The BES daemon appears to have died! Exiting." >&2
        exit 1;
    fi
    if [ $TOMCAT_STATUS -ne 0 ]; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
        echo "Tomcat appears to have died! Exiting." >&2
        echo "Tomcat Console Log [BEGIN]" >&2
        cat /usr/share/tomcat/logs/console.log >&2
        echo "Tomcat Console Log [END]" >&2
        exit 2
    fi

    if [ $debug = true ];then
        echo "-------------------------------------------------------------------"  >&2
        date >&2
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid" >&2
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
    fi

    tail -f /var/log/bes/bes.log | awk -f beslog2json.awk

done

