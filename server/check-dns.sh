#!/bin/bash -l
# This script will check DNS delegations and A records on all web domains

# Obtenemos las IPs del servidor
SERVER_IPS=$(hostname -I | tr " " "\n")

# Seteamos arrays
declare -A DNS_LOCAL

# Creamos tambien un array por ip
for SERVER_IP in $SERVER_IPS
do
   IP_NAME="$(echo $SERVER_IP | sed 's/\./_/g')"
   declare -a DNS_LOCAL_$IP_NAME
done
DNS_ERROR=()
DNS_EXTERNAL=()

# Listamos usuarios y dominios por usuario
while read USER ; do
  while read DOMAIN ; do
    echo "Checking DNS on $DOMAIN"
    RES="$(dig $DOMAIN +noquestion +nostat +noauthority +noadditional +tries=1 +time=5)"
    DNS_RES=${RES##*ANSWER: }
    DNS_RES="${DNS_RES%%,*}"
    IP="$(echo $RES | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"
    IPS="$(echo $IP | tr '\n' ' ')"
    if [ $DNS_RES = "0" ]; then
      DNS_ERROR+=("$USER - $DOMAIN")
    else
      if [[ $SERVER_IPS == *"$IP"* ]]; then
        DNS_LOCAL["$USER - $DOMAIN"]="$IP"
        IP_NAME="$(echo $IP | sed 's/\./_/g')"
        eval DNS_LOCAL_$IP_NAME'+=("'$USER - $DOMAIN'")'
      else
        DNS_EXTERNAL+=("$USER - $DOMAIN >>> $IPS")
      fi
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

printf '\n'
echo "-----------------------------------"
echo "${#DNS_LOCAL[@]} domains pointing to this server:"
echo "-----------------------------------"
for SERVER_IP in $SERVER_IPS
do
  IP_NAME="$(echo $SERVER_IP | sed 's/\./_/g')"
  printf '\n'
  echo "-----------------------------------"
  ARRAY_COUNT="$(eval echo '${#'DNS_LOCAL_$IP_NAME'[@]}')"
  echo "$ARRAY_COUNT en la IP $SERVER_IP:"
  echo "-----------------------------------"
  #eval for LINE in \"\$\{DNS_LOCAL_$IP_NAME\[\@\]\}\" \; do echo $LINE \; done
  eval printf \'\%\s\\n\' '"${'DNS_LOCAL_$IP_NAME'[@]}"'
done
#printf '%s\n' "${DNS_LOCAL[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#DNS_ERROR[@]} domains without DNS delegation:"
echo "-----------------------------------"
printf '%s\n' "${DNS_ERROR[@]}"
printf '\n'
echo "-----------------------------------"
echo "${#DNS_EXTERNAL[@]} domains pointing to another server:"
echo "-----------------------------------"
printf '%s\n' "${DNS_EXTERNAL[@]}"
printf '\n'
echo "-----------------------------------"
