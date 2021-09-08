#!/bin/bash

function check_configuration() {
        if ! [ -v "$1" ] ; then
                target=$(eval "$2")
		eval "export $1=${target}"
		echo -e "-e $1=\"${target}\" \\"
        fi
}
function check_process() {
	while sleep 60; do
		for p in ${@}
		do
			ps aux |grep ${p} |grep -q -v grep
			PROCESS_STATUS=$?
			if [ ${PROCESS_STATUS} -ne 0 ]; then
				echo "${p} has already exited."
			fi
		done
	done
}

echo 'Generating environment variables...'
check_configuration "UUID" "/usr/local/bin/v2ctl uuid"
check_configuration "WSPATH" "tr -dc a-z </dev/urandom | head -c 6" 
check_configuration "mtgsni" "echo www.bilibili.com"
check_configuration "mtgsecret" "/usr/local/bin/mtg generate-secret --hex ${mtgsni}"
check_configuration "password" "tr -dc A-Za-z0-9 </dev/urandom | head -c 16"
echo 'Done'

export UNIX_DOMAIN_SOCKET_FILE="/var/run/v2ray.sock"
if [ -S "${UNIX_DOMAIN_SOCKET_FILE}" ]; then
	rm -f "${UNIX_DOMAIN_SOCKET_FILE}"*
fi

for f in /root/setup-configuration/*.sh; do
  bash "${f}"
done

/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json &
/usr/local/bin/mtg run /usr/local/etc/mtg/config.toml &
/usr/sbin/haproxy -f /usr/local/etc/haproxy/haproxy.cfg &
/usr/local/bin/ssserver --config /usr/local/etc/shadowsocks-rust/config.json & 

check_process "v2ray" "mtg" "haproxy" "ssserver"
