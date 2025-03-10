#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Common Functions.
red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
error() { echo -n "$INDENT" >&2; red '#' "$@" >&2; echo >&2; }
success() { echo -n "$INDENT" >&2; green '#' "$@" >&2; echo >&2; }
chapter() { echo -n "$INDENT" >&2; yellow '#' "$@" >&2; echo >&2; }
title() { echo -n "$INDENT" >&2; blue '#' "$@" >&2; echo >&2; }
code() { echo -n "$INDENT" >&2; magenta "$@" >&2; echo >&2; }
x() { echo >&2; exit 1; }
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.3'
}
printHelp() {
    title RCM Obfuscate Proxy
    _ 'Variation '; yellow SSH Server Run.; _.
    _ 'Version '; yellow `printVersion`; _.
    cat << 'EOF'
Usage: rcm-obfuscate-proxy-ssh-server-run [options]

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Dependency:
   systemctl
   netstat
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-obfuscate-proxy-ssh-server-run
____

ArraySearch() {
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}

INDENT+="    " \
rcm-obfuscate-proxy-autoinstaller $isfast --root-sure \
    ; [ ! $? -eq 0 ] && x

found=1
user=obfs4-ssh
user_home=/var/lib/obfs4proxy-ssh/
user_gecos="obfs4proxy for ssh"
# todo, buat juga untuk VPN
chapter Mengecek PHP-FPM User.
code id -u '"'$user'"'
if id "$user" >/dev/null 2>&1; then
	__ User '`'$user'`' found.
else
	__ User '`'$user'`' not found.;
	found=
fi
____

if [ -z "$found" ];then
    chapter Membuat Unix user.
	code adduser --system --group --shell '"'/usr/sbin/nologin'"' \
		--home '"'$user_home'"' \
		--gecos '"'$user_gecos'"' \
		$user
	adduser --system --group --shell "/usr/sbin/nologin" \
		--home "$user_home" \
		--gecos "$user_gecos" \
		$user
    ____
fi

chapter Mendeteksi command yang menggunakan port 2222.
code 'lsof -i :2222'
lsof -i :2222

_commands_of_port=()
while IFS= read -r line; do
	if [ -n "$line" ];then
		_command=$(ps -p $line -o comm -h)
		if ! ArraySearch "$_command" _commands_of_port[@];then
			_commands_of_port+=("$_command")
		fi
	fi
done <<< `lsof -i :2222 -t`
____

if [ "${#_commands_of_port[@]}" -gt 0 ];then
	for each in "${_commands_of_port[@]}"; do
		e "$each"
	done

	chapter Memaksa mematikan proses yang me-listen port 2222.
	code 'kill $(lsof -i :2222 -t)'
	while IFS= read -r line; do
		if [ -n "$line" ];then
			kill -9 $line
		fi
	done <<< `lsof -i :2222 -t`
	____
fi

sudo -u obfs4-ssh \
env TOR_PT_MANAGED_TRANSPORT_VER="1" \
    TOR_PT_STATE_LOCATION="/var/lib/obfs4proxy-ssh/" \
    TOR_PT_SERVER_TRANSPORTS="obfs4" \
    TOR_PT_SERVER_BINDADDR="obfs4-0.0.0.0:2222" \
    TOR_PT_ORPORT="127.0.0.1:22" \
obfs4proxy -enableLogging -logLevel DEBUG &

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# )
# VALUE=(
# --source-interface
# --source-port
# --destination-interface
# --destination-port
# --user
# )
# FLAG_VALUE=(
# )
# EOF
# clear
