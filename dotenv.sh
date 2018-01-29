#!/bin/sh
set -e

log_verbose() {
	if [ "$VERBOSE" = 1 ]; then
		echo "[dotenv.sh] $1" >&2
	fi
}

is_set() {
	[ -n "$(eval "echo \$$1")" ]
}

is_comment() {
	case "$1" in
	\#*)
		log_verbose "Skip: $1"
		return 0
		;;
	esac
	return 1
}

is_blank() {
	case "$1" in
	'')
		log_verbose "Skip: _"
		return 0
		;;
	esac
	return 1
}

export_envs() {
	while IFS='=' read -r key temp || [ -n "$key" ]; do
		if is_comment "$key"; then
			continue
		fi

		if is_blank "$key"; then
			continue
		fi

		if is_set "$key"; then
			log_verbose "Existing: $key"
		else
			value=$(eval echo "$temp")
			log_verbose "Exporting: $key:$value"
			eval export "$key='$value'";
		fi
	done < $1
}

# inject .env configs into the shell
inject_dotenv() {
	if is_set "DOTENV_FILE"; then
		log_verbose "Using file: $DOTENV_FILE"
		if [ -f "$DOTENV_FILE" ]; then
			export_envs "$DOTENV_FILE"
			return 0
		else
			>&2 echo "'$DOTENV_FILE' is not a regular file."
			return 1
		fi
	fi

	log_verbose "Using file: .env"
	if [ -f ".env" ]; then
		export_envs ".env"
		return 0
	else
		>&2 echo ".env is not a regular file."
		return 1
	fi
}

# inject any defaults into the shell
inject_default_dotenv() {
	if is_set "DOTENV_DEFAULT"; then
		log_verbose "Setting defaults via $DOTENV_DEFAULT"
		if [ -f "$DOTENV_DEFAULT" ]; then
			export_envs "$DOTENV_DEFAULT"
			return 0
		else
			>&2 echo "$DOTENV_DEFAULT file not found"
			return 1
		fi
	fi

	log_verbose "Skip DOTENV_DEFAULT as it was not set"
}

main() {

	inject_dotenv || exit 1
	inject_default_dotenv || exit 1

	# then run whatever commands you like
	if [ $# -gt 0 ]; then
		exec "$@"
	fi
}

main "$@"

# vim:nolist noet
