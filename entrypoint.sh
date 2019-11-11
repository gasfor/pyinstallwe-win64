#!/bin/bash

# Fail on errors.
set -e

# Allow the workdir to be set using an env var.
# Useful for CI pipelines which use docker for their build steps
# and don't allow that much flexibility to mount volumes
WORKDIR=${SRCDIR:-/src}

#set user name\password and root password
function __get_password ()
{
	local -r password_length="${1:-16}"

	local password="$(
		head -n 4096 /dev/urandom \
		| tr -cd '[:alnum:]' \
		| cut -c1-"${password_length}"
	)"

	printf -- '%s' "${password}"
}

function __is_valid_ssh_user ()
{
	local -r safe_user='^[a-z_][a-z0-9_-]{0,29}[$a-z0-9_]?$'
	local -r user="${1}"

	if [[ ${user} =~ ${safe_user} ]]
	then
		return 0
	fi

	return 1
}

function __get_ssh_user ()
{
	local -r default_value="${1:-app-admin}"

	local value="${SSH_USER}"

	if ! __is_valid_ssh_user "${value}"
	then
		value="${default_value}"
	fi

	printf -- '%s' "${value}"
}

function __get_ssh_user ()
{
	local -r default_value="${1:-app-admin}"

	local value="${SSH_USER}"

	if ! __is_valid_ssh_user "${value}"
	then
		value="${default_value}"
	fi

	printf -- '%s' "${value}"
}

function main ()
{
	local -r password_length="16"
	ssh_user_password="${SSH_USER_PASSWORD:-"$(
		__get_password "${password_length}"
	)"}"
	ssh_user="$(__get_ssh_user)"
	ssh_root_password="$(__get_password "${password_length}")"
	if [[ ${ssh_user} != root ]]; then
            if id -u $ssh_user >/dev/null 2>&1; then
	    	echo "user name is exist, only output password"
	    else
                echo "user name is not exist, add user"
                echo "user home path:${WORKDIR}"
		useradd -m \
                        -d "${WORKDIR}" \
                        -g buildgroup \
                        -s /bin/bash \
			"${ssh_user}"
                chown -R "${ssh_user}":buildgroup ${WORKDIR}
		printf -- \
					'%s:%s\n' \
					"${ssh_user}" \
					"${ssh_user_password}" \
				| chpasswd
		echo -e "user name:${ssh_user} \n"
             fi
		echo -e "user password:${ssh_user_password} \n"
	fi
	printf -- \
			'%s:%s\n' \
			"root" \
			"${ssh_root_password}" \
			| chpasswd
	echo -e "root password:${ssh_root_password}"
	#import docker environment to ssh
	chsh -s /bin/bash root
	export $(sudo cat /proc/1/environ |tr '\0' '\n' | xargs)
}

# Make sure .bashrc is sourced
. /root/.bashrc

#
# In case the user specified a custom URL for PYPI, then use
# that one, instead of the default one.
#
if [[ "$PYPI_URL" != "https://pypi.python.org/" ]] || \
   [[ "$PYPI_INDEX_URL" != "https://pypi.python.org/simple" ]]; then
    # the funky looking regexp just extracts the hostname, excluding port
    # to be used as a trusted-host.
    mkdir -p /wine/drive_c/users/root/pip
    echo "[global]" > /wine/drive_c/users/root/pip/pip.ini
    echo "index = $PYPI_URL" >> /wine/drive_c/users/root/pip/pip.ini
    echo "index-url = $PYPI_INDEX_URL" >> /wine/drive_c/users/root/pip/pip.ini
    echo "trusted-host = $(echo $PYPI_URL | perl -pe 's|^.*?://(.*?)(:.*?)?/.*$|$1|')" >> /wine/drive_c/users/root/pip/pip.ini

    echo "Using custom pip.ini: "
    cat /wine/drive_c/users/root/pip/pip.ini
fi

cd $WORKDIR

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi # [ -f requirements.txt ]

echo "$@"

if [[ "$@" != "" ]]; then
   sh -c "$@"
elif [[ -f *.spec ]]; then
   pyinstaller --clean -y --dist ./dist/windows --workpath /tmp *.spec
   chown -R --reference=. ./dist/windows
else 
   echo `pyinstaller --version`
fi

main "${@}"

exec /usr/sbin/sshd -D
