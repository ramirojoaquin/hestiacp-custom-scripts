#!/bin/bash
# This script will check if an IP is present in any blacklist on the server, and proceed to unban.

IP=$1
if [ -z $1 ]; then
  echo "No IP entered"
  exit 1
fi

# Get fail2ban jails
FAIL2BAN_JAILS="$(fail2ban-client status | grep 'Jail list')"
FAIL2BAN_JAILS="${FAIL2BAN_JAILS:14}"
IFS=', ' read -a JAILS <<< "$FAIL2BAN_JAILS"

# Check if IP is present and proceed with unban
for JAIL in "${JAILS[@]}"
do
    BANNED=0
    if [[ "$(fail2ban-client status $JAIL | grep $IP)" != '' ]]; then
        echo "$JAIL: !!! Was BANNED"
        echo "fail2ban unban..."
        fail2ban-client set $JAIL unbanip $IP
        BANNED=1
    fi
done

# Check iptables and proceed to unban
IPTABLES_BANNED=0
IPTABLES_CHAINS="$(iptables -L -n --line-numbers | grep 'Chain')"
while read -r CHAIN; do
    CHAIN="$(echo $CHAIN | awk {'print $2'})"
    RULE="$(iptables -L $CHAIN -n --line-numbers | grep "$IP")"
    LINE_NUMBER="$(echo $RULE | awk {'print $1'})"

    if [[ $RULE != '' ]]; then
        echo "Iptables $CHAIN: !!! Was BANNED"
        echo "iptables unban..."
        iptables -D $CHAIN $LINE_NUMBER
        IPTABLES_BANNED=1
    fi
done <<< "$IPTABLES_CHAINS"

if [[ $BANNED == 0 ]] && [[ $IPTABLES_BANNED == 0 ]]; then
    echo "--- $IP is not BANNED ---"
fi