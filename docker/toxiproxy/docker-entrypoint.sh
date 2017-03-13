#!/bin/bash -xe

toxiproxy "-host=0.0.0.0" &
PID=$!
sleep 5
if [[ -n $PROXIES ]]; then
    IFS=','; for proxy in $PROXIES; do
        echo "creating proxy: $proxy"
        IFS=':' read -a proxyConfig <<< "$proxy"
        toxiproxy-cli create ${proxyConfig[0]} --listen "0.0.0.0:${proxyConfig[1]}" --upstream "${proxyConfig[2]}:${proxyConfig[3]}"
    done
fi

wait $PID

