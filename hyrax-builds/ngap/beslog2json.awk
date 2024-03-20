#
# Translates OPeNDAP bes.logs into JSON
#
BEGIN {

    FS="\\|&\\|";

    if(debug!="true"){
         debug="false";
    }

    if(pretty!="true"){
        pretty="false";
    }

    if(pretty=="true"){
        n="\n";
        indent="    ";
    }

# 1601642669|&|2122|&|timing|&|TimingFields
# 1601642669|&|2122|&|verbose|&|MessageField
# 1601642679|&|2122|&|info|&|MessageField
# 1601642679|&|2122|&|error|&|MessageField
# 1601642679|&|2122|&|request|&|RequestFields



    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Log line base.

    # The time that the log message was written.
    log_line_base[1]="hyrax-time";

    # The PID of the beslistener that wrote the log entry.
    log_line_base[2]="hyrax-pid";

    # The message associate with the log entry
    log_line_base[3]="hyrax-log_name";



    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Request Log Fields

# 1601646255|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E|&|-|&|1601646255543|&|10|&|HTTP-GET|&|/opendap/hyrax/data/nc/nc4_strings.nc.dds|&|-|&|BES|&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/nc4_strings.nc
# 1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E|&|-|&|1601646465304|&|18|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES|&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u

    # OLFS Tag.
    request_log_fields[4]="hyrax-OLFS";

    # ip-address of requesting client's system.
    request_log_fields[5]="hyrax-client_ip";

    # The value of the User-Agent request header sent from the client.
    request_log_fields[6]="hyrax-user_agent";

    # The session id, if present.
    request_log_fields[7]="hyrax-session_id";

    # The user's user id, if a user is logged in.
    request_log_fields[8]="hyrax-user_id";

    # The time the the request was received.
    request_log_fields[9]="hyrax-start_time";

    # We are not so sure what this number is...
    request_log_fields[10]="hyrax-duration";

    # The HTTP verb of the request (GET, POST, etc)
    request_log_fields[11]="hyrax-http_verb";

    # The path component of the requested resource.
    request_log_fields[12]="hyrax-url_path";

    # The query string, if any, submitted with the request.
    request_log_fields[13]="hyrax-query_string";

    # Field 13 is a field that indicates the following fields orginated
    # in the BES, it is not semantically important to NGAP
    request_log_fields[14]="hyrax-bes";

    # The type of BES action/request/command invoked by the request
    request_log_fields[15]="hyrax-bes_request";

    # The DAP protocl
    request_log_fields[16]="hyrax-dap_version";

    # The local file path to the resource.
    request_log_fields[17]="hyrax-local_path";

    # Field 18 is a duplicate of field 13 and if the query string is absent
    # then field 18 will be missing entirely.
    request_log_fields[18]="hyrax-constraint_expression";

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Error/Verbose/Info Fields

    # The message associate with the log entry
    msg_fields[4]="hyrax-message";

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Start Timing Fields
    # 1601642669|&|2122|&|timing|&|start_us|&|1601642669943035|&|ReqId|&|TIMER_NAME

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Stop Timing Fields
    # 1601642669|&|2122|&|timing|&|stop_us|&|1601642669944587|&|elapsed_us|&|1552|&ReqId|&|TIMER_NAME
    #     1          2      3         4            5               6           7     8        9


}
{
    # First, escape all of the double quotes in the values of the log fields.
    gsub(/\"/, "\\\"");

    if(debug=="true"){
        print "------------------------------------------------";
        print $0;
    }

    ltime=$1;
    pid=$2;
    log_name=$3;
    printf("{%s", n);
    printf("%s\"hyrax-time\": %s, %s", indent, ltime, n);
    printf("%s\"hyrax-pid\": \"%s\", %s", indent, pid, n);
    printf("%s\"hyrax-type\": \"%s\"", indent, log_name);

    if(log_name=="request"){
        for(i=4; i<=NF  ; i++){
            if(i!=4 && i!=14 && i!=18){
                printf(", %s",n);
                if(i==9 || i==10){
                    printf("%s\"%s\": %s",indent,request_log_fields[i],$i);
                }
                else {
                    printf("%s\"%s\": \"%s\"",indent,request_log_fields[i],$i);
                }
             }
        }
    }
    else if(log_name=="info" || log_name=="error" || log_name=="verbose" ){
        printf(", %s",n);
        printf("%s\"%s\": \"%s\"", indent, msg_fields[4], $4);
    }
    else if(log_name == "timing"){

        time_type = $4;

        if(time_type=="start_us"){
            # 1601642669|&|2122|&|timing|&|start_us|&|1601642669945133|&|-|&|TIMER_NAME
            #      1         2      3        4             5             6      7
            printf(", %s%s\"%s\": %s", n, indent, "hyrax-start_time_us", $5);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "hyrax-req_id", $6);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "hyrax-name:", $7);
        }
        else if(time_type=="elapsed_us"){
            #1601653546|&|7096|&|timing|&|elapsed_us|&|2169|&|start_us|&|1601653546269617|&|stop_us|&|1601653546271786|&|ReqId|&|TIMER_NAME
            #     1          2      3         4          5        6            7                8           9              10       11
            printf(", %s%s\"%s\": %s", n, indent, "hyrax-elapsed_time_us", $5);
            printf(", %s%s\"%s\": %s", n, indent, "hyrax-start_time_us", $7);
            printf(", %s%s\"%s\": %s", n, indent, "hyrax-stop_time_us", $9);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "hyrax-req_id", $10);
            printf(", %s%s\"%s\": \"%s\"", n, indent,  "hyrax-name:", $11);

        }
        else {
            printf(", %s%s\"LOG_ERROR\": \"FAILED to process: %s\"", n , indent, $0);
        }

    }
    else {
        # old way
        if (NF > 3){
            for(i=1; i<=NF  ; i++){
                if(i!=3 && i!=13 && i!=17){
                    if(i>1)
                        printf(", %s",n);
                    printf("%s\"%s\": \"%s\"",indent,request_log_fields[i],$i);
                }
            }
        }
        else {
            for(i=1; i<=NF ; i++){
                if(i>1) {
                    printf(", %s",n);
                }
                printf("%s\"%s\": \"%s\"",indent,msg_fields[i],$i);
            }
       }

    }

    printf("%s}\n", n);

}
