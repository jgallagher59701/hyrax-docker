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

# 1601642669|&|2122|&|timing|&|more stuff...
#1601642669|&|2122|&|verbose|&|Message Stuff
#1601642679|&|2122|&|info|&|Message stuff
#1601642679|&|2122|&|error|&|Error stuff
#1601642679|&|2122|&|request|&|Error stuff



    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Log line base.

    # The time that the log message was written.
    log_line_base[1]="time";

    # The PID of the beslistener that wrote the log entry.
    log_line_base[2]="pid";

    # The message associate with the log entry
    log_line_base[3]="log_name";



    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Request Log Fields

# 1601646255|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E|&|-|&|1601646255543|&|10|&|HTTP-GET|&|/opendap/hyrax/data/nc/nc4_strings.nc.dds|&|-|&|BES|&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/nc4_strings.nc
# 1601646465|&|2122|&|request|&|OLFS|&|0:0:0:0:0:0:0:1|&|USER_AGENT|&|92F3C71F959B56515C98A09088CA2A8E|&|-|&|1601646465304|&|18|&|HTTP-GET|&|/opendap/hyrax/data/nc/fnoc1.nc.dds|&|u|&|BES|&|get.dds|&|dap2|&|/Users/ndp/OPeNDAP/hyrax/build/share/hyrax/data/nc/fnoc1.nc|&|u

    # OLFS Tag.
    request_log_fields[4]="OLFS";

    # ip-address of requesting client's system.
    request_log_fields[5]="client_ip";

    # The value of the User-Agent request header sent from the client.
    request_log_fields[6]="user_agent";

    # The session id, if present.
    request_log_fields[7]="session_id";

    # The user's user id, if a user is logged in.
    request_log_fields[8]="user_id";

    # The time the the request was received.
    request_log_fields[9]="start_time";

    # We are not so sure what this number is...
    request_log_fields[10]="duration";

    # The HTTP verb of the request (GET, POST, etc)
    request_log_fields[11]="http_verb";

    # The path component of the requested resource.
    request_log_fields[12]="url_path";

    # The query string, if any, submitted with the request.
    request_log_fields[13]="query_string";

    # Field 13 is a field that indicates the following fields orginated
    # in the BES, it is not semantically important to NGAP
    request_log_fields[14]="bes";

    # The type of BES action/request/command invoked by the request
    request_log_fields[15]="bes_request";

    # The DAP protocl
    request_log_fields[16]="dap_version";

    # The local file path to the resource.
    request_log_fields[17]="local_path";

    # Field 18 is a duplicate of field 13 and if the query string is absent
    # then field 18 will be missing entirely.
    request_log_fields[18]="constraint_expression";

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Error/Verbose/Info Fields

    # The message associate with the log entry
    msg_fields[4]="message";


    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Start Timing Fields
    # 1601642669|&|2122|&|timing|&|start_us|&|1601642669943035|&|ReqId|&|TIMER_NAME

    # The message associate with the log entry
    start_time_fields[4]="start_us";

    # The message associate with the log entry
    start_time_fields[5]="start_time_us";

    # The message associate with the log entry
    start_time_fields[6]="ReqId";

    # The message associate with the log entry
    start_time_fields[7]="Name";

    # -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    # Stop Timing Fields
    # 1601642669|&|2122|&|timing|&|stop_us|&|1601642669944587|&|elapsed_us|&|1552|&ReqId|&|TIMER_NAME
    #     1          2      3         4            5               6           7     8        9
    # The message associate with the log entry
    stop_time_fields[4]="stop_us";

    # The message associate with the log entry
    stop_time_fields[5]="stop_time_us";

    # The message associate with the log entry
    stop_time_fields[6]="elapsed_us";

    # The message associate with the log entry
    stop_time_fields[6]="elapsed_time_us";

    # The message associate with the log entry
    stop_time_fields[7]="ReqId";

    # The message associate with the log entry
    stop_time_fields[4]="Name";


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
    printf("%s\"time\": %s, %s", indent, ltime, n);
    printf("%s\"pid\": \"%s\", %s", indent, pid, n);
    printf("%s\"type\": \"%s\"", indent, log_name);

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
            printf(", %s%s\"%s\": %s", n, indent, "start_time_us", $5);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "req_id", $6);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "name:", $7);
        }
        else if(time_type=="elapsed_us"){
            #1601653546|&|7096|&|timing|&|elapsed_us|&|2169|&|start_us|&|1601653546269617|&|stop_us|&|1601653546271786|&|ReqId|&|TIMER_NAME
            #     1          2      3         4          5        6            7                8           9              10       11
            printf(", %s%s\"%s\": %s", n, indent, "elapsed_time_us", $5);
            printf(", %s%s\"%s\": %s", n, indent, "start_time_us", $7);
            printf(", %s%s\"%s\": %s", n, indent, "stop_time_us", $9);
            printf(", %s%s\"%s\": \"%s\"", n, indent, "req_id", $10);
            printf(", %s%s\"%s\": \"%s\"", n, indent,  "name:", $11);

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
