#!/bin/bash -l

# This script will perform DNS, HTTP response code, and SSL cert vality checks in all websites hosted in this server and will alert by email in case of error
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Load time limit in seconds
LOAD_TIME_THRESHOLD=5

# -------- Start scripting ---------

# Get server ips
SERVER_IPS=$(hostname -I | tr " " "\n")

# Set bad domains array, we will store domains with errors here
BAD_DOMAINS=()

# Reset counters
ERROR_COUNT=0
DNS_NO_DELEGATION_COUNT=0
DNS_EXTERNAL_COUNT=0
HTTP_REDIRECT_COUNT=0
HTTP_ERROR_COUNT=0
HTTP_ERROR_NO_HTTPS_COUNT=0
HTTP_OK_NO_HTTPS_COUNT=0
LOAD_TIME_COUNT=0
SSL_NOT_VALID_COUNT=0
SSL_EXPIRED_COUNT=0
DOMAINS_COUNT=0

while read USER ; do
    USERS+=($USER)
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

# Iterate all users and grab their domains if the user is not suspended
while read USER ; do
    if [[ ! $(v-list-user $USER | grep "SUSPENDED" | grep "yes") ]] && [[ $USER != "admin" ]]; then        
        while read DOMAIN ; do
            # Perform checks only if domain is not suspended
            if [[ ! $(v-list-web-domain $USER $DOMAIN | grep "SUSPENDED" | grep "yes") ]]; then

                echo "- Comprobando $DOMAIN ($USER)..."
		        echo "DNS..."
                DOMAIN_DESCRIPTION="<b>$DOMAIN ($USER):</b><br>";

                # By default there is no error
                ERROR=0
                # By default all test are performed
                NO_TEST=0

                # Start cheking
                TIME_DNS_START=`date +%s%6N`
                RES="$(dig $DOMAIN +noquestion +nostat +noauthority +noadditional +tries=2 +time=5)"
                DNS_RES=${RES##*ANSWER: }
                DNS_RES="${DNS_RES%%,*}"
                IP="$(echo $RES | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"
                IPS="$(echo $IP | tr '\n' ' ')"

                # Get response time DNS
                TIME_DNS_END=`date +%s%6N`
                RESPONSE_TIME_DNS=$(echo "scale=3;$((TIME_DNS_END-TIME_DNS_START))/1000000" | bc -l | awk '{printf "%.*f", 3, $0}')
                
                # Checking if there is error in DNS delegation
                if [ $DNS_RES = "0" ]; then
                    ERROR=1
                    DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! DNS: Sin delegación</b><br>"
                    # No other test will be performed
                    NO_TEST=1
                    ((DNS_NO_DELEGATION_COUNT++))
                else
                    # If the domain is pointing to this server ips proceed with the other tests
                    if [[ $SERVER_IPS == *"$IP"* ]]; then
                        DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}DNS: OK<br>"
                        
                        # Performing HTTP response code check
                        echo "HTTP..."
			TIME_WEB_START=`date +%s%6N`
                        STATUS="$(curl -ILs --max-time 20 $DOMAIN)"
                        HTTP_CODE="$(printf %s "$STATUS" | grep -m1 '^HTTP.*' | awk {'print $2'})"
                        HTTP_FINAL_CODE="$(printf %s "$STATUS" | tac | grep -m1 '^HTTP.*' | awk {'print $2'})"
                        LOCATION="$(printf %s "$STATUS" | tac | grep -m1 '^Location.*' | awk {'print $2'})"
                        
                        # Get web response time
                        TIME_WEB_END=`date +%s%6N`
                        RESPONSE_TIME_WEB=$(echo "scale=3;$((TIME_WEB_END-TIME_WEB_START))/1000000" | bc -l | awk '{printf "%.*f", 3, $0}')
                        
                        # Check for redirections
                        if [[ $HTTP_CODE = "301" ]]; then
                            if [[ $LOCATION = *"$DOMAIN/"* ]]; then
                                if [[ $HTTP_FINAL_CODE != "200" ]]; then
                                    ERROR=1
                                    ((HTTP_ERROR_COUNT++))
                                    DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! HTTP: $HTTP_FINAL_CODE</b><br>"
                                else
                                    DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}HTTP: $HTTP_FINAL_CODE OK<br>"
                                fi
                            else
                                ERROR=1
                                ((HTTP_REDIRECT_COUNT++))
                                DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! HTTP: redirección 301 a $LOCATION</b><br>"
                            fi
                        else
                            ERROR=1
                            if [[ $HTTP_FINAL_CODE != "200" ]]; then
                                ((HTTP_ERROR_NO_HTTPS_COUNT++))
                                DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! HTTP: $HTTP_FINAL_CODE SIN redirección HTTPS</b><br>"
                            else
                                ((HTTP_OK_NO_HTTPS_COUNT++))
                                DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! HTTP: $HTTP_FINAL_CODE OK pero SIN redirección HTTPS</b><br>"
                            fi
                        fi

                        # Load time alert if taking more than threashold
                        if [ $(echo "$RESPONSE_TIME_WEB > $LOAD_TIME_THRESHOLD" | bc) -ne 0 ]; then
                            ERROR=1
                            ((LOAD_TIME_COUNT++))
                            DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! TIEMPO DE RESPUESTA: ${RESPONSE_TIME_WEB}s (más de ${LOAD_TIME_THRESHOLD}s)</b><br>"
                        else
                            DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}TIEMPO DE RESPUESTA: ${RESPONSE_TIME_WEB}s<br>"
                        fi
                        
                        # Performing SSL check
			echo "SSL..."
                        SSL_INFO="$(true | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null)"
                        SSL_CHECK="$(printf %s "$SSL_INFO" | openssl x509 -noout -checkend 0)"
                        # Get cert valid domains
                        SSL_DOMAINS="$(printf %s "$SSL_INFO" | openssl x509 -noout -text | grep -oP '(?<=DNS:|IP Address:)[^,]+'|sort -uV)"
                        # By default the cert is not valid
                        SSL_VALID=0
                        # Compare cert domains with the given domain and validate
                        while IFS= read -r line; do
                            if [[ $line == "$DOMAIN" ]]; then
                                SSL_VALID=1
                            fi
                        done <<< "$SSL_DOMAINS"
                        # If has valid domain check expiration
                        if [[ $SSL_VALID = "1" ]]; then
                            if [[ $SSL_CHECK == "Certificate will not expire" ]]; then
                                DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}SSL: Certificado válido<br>"
                            else
                                ERROR=1
                                ((SSL_EXPIRED_COUNT++))
                                DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! SSL: Certificado expirado</b><br>"
                            fi
                        else
                            ERROR=1
                            ((SSL_NOT_VALID_COUNT++))
                            DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! SSL: Certificado NO válido</b><br>"
                        fi
                    else
                        ERROR=1
                        DOMAIN_DESCRIPTION="${DOMAIN_DESCRIPTION}<b style='color: #f00'>!!! DNS: El registro A apunta a $IP</b><br>"
                        # No other test will be performed
                        NO_TEST=1
                        ((DNS_EXTERNAL_COUNT++))
                    fi
                fi
                
                # if there is at least one test failed, add domain to bad domains list
                if [[ $ERROR == "1" ]]; then
                    ((ERROR_COUNT++))
                    html2text -utf8 <<< $DOMAIN_DESCRIPTION
                    BAD_DOMAINS+=("$DOMAIN_DESCRIPTION")
                fi

                ((DOMAINS_COUNT++))

            fi
        done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}') # for each domain
    fi
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

# Build emails array
IFS=',' read -a EMAILS_ARRAY <<< "$HOST_ALERTS_EMAILS"

echo -e "\n"

# Check if there are domains with errors
if [ ${#BAD_DOMAINS[@]} -eq 0 ]; then
    echo "----- Todo OK en $DOMAINS_COUNT sitios."
else
    # Errors found, sending alerts
    echo "!!!!! Errores encontrados en $ERROR_COUNT de $DOMAINS_COUNT dominios"
    echo -e "\n"
    echo "Resumen:"
    echo "$DNS_NO_DELEGATION_COUNT sitios sin delegación DNS."
    echo "$DNS_EXTERNAL_COUNT con registro A apuntando a otro server."
    echo "$HTTP_REDIRECT_COUNT sitios redireccionando a otro dominio."
    echo "$HTTP_ERROR_COUNT sitios con errores HTTP."
    echo "$HTTP_ERROR_NO_HTTPS_COUNT sitios con errores HTTP y sin redirección HTTPS."
    echo "$HTTP_OK_NO_HTTPS_COUNT sitios con HTTP OK, pero sin redirección HTTPS."
    echo "$LOAD_TIME_COUNT sitios con problemas de tiempo de respuesta."
    echo "$SSL_NOT_VALID_COUNT sitios con SSL no válido."
    echo "$SSL_EXPIRED_COUNT sitios con SSL vencido."
    echo -e "\n"
    echo "Enviando alertas a:"

    # Building email body
    BODY="<p><b>RESUMEN:</b><br><br>$DNS_NO_DELEGATION_COUNT sitios sin delegación DNS.<br>$DNS_EXTERNAL_COUNT con registro A apuntando a otro server.<br>$HTTP_REDIRECT_COUNT sitios redireccionando a otro dominio.<br>$HTTP_ERROR_COUNT sitios con errores HTTP.<br>$HTTP_ERROR_NO_HTTPS_COUNT sitios con errores HTTP y sin redirección HTTPS.<br>$HTTP_OK_NO_HTTPS_COUNT sitios con HTTP OK, pero sin redirección HTTPS.<br>$LOAD_TIME_COUNT sitios con problemas de tiempo de respuesta.<br>$SSL_NOT_VALID_COUNT sitios con SSL no válido.<br>$SSL_EXPIRED_COUNT sitios con SSL vencido.<br><br><b>DETALLE POR SITIO:</b><br><br>"
    for LINE in "${BAD_DOMAINS[@]}"
    do
        BODY="${BODY}$LINE<br>"
    done
    BODY="${BODY}</p>"

    # Send alerts to each email
    for EMAIL in "${EMAILS_ARRAY[@]}"
    do
        echo $EMAIL
        echo -e $BODY | mail -s "URGENTE! Hay problemas en $ERROR_COUNT de $DOMAINS_COUNT sitios!" -a "Content-Type: text/html; charset=UTF-8" $EMAIL
    done
fi

exit
