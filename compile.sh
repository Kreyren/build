#!/usr/bin/env bash
#
# Copyright (c) 2013-2021 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the Armbian build script
# https://github.com/armbian/build/  

# DO NOT EDIT THIS FILE
# use configuration files like config-default.conf to set the build configuration
# check Armbian documentation https://docs.armbian.com/ for more info

#set -o pipefail  # trace ERR through pipes - will be enabled "soon"
#set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable - one day will be enabled
set -e
set -o errtrace # trace ERR through - enabled
set -o errexit  ## set -e : exit the script if any statement returns a non-true return value - enabled
# Important, go read http://mywiki.wooledge.org/BashFAQ/105 NOW!

SRC="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd "${SRC}" || exit

# check for whitespace in ${SRC} and exit for safety reasons
grep -q "[[:space:]]" <<< "${SRC}" && {
	echo "\"${SRC}\" contains whitespace. Not supported. Aborting." >&2
	exit 1
}

# Sanity check.
if [[ ! -f "${SRC}"/lib/single.sh ]]; then
	echo "Error: missing build directory structure"
	echo "Please clone the full repository https://github.com/armbian/build/"
	exit 255
fi

# shellcheck source=lib/single.sh
source "${SRC}"/lib/single.sh

# initialize logging variables. (this does not consider parameters at this point, only environment variables)
logging_init

# initialize the traps
traps_init

# make sure git considers our build system dir as a safe dir (only if actually building)
[[ "${CONFIG_DEFS_ONLY}" != "yes" ]] && git_ensure_safe_directory "${SRC}"

# Execute the main CLI entrypoint.
cli_entrypoint "$@"

# Log the last statement of this script for debugging purposes.
display_alert "Armbian build script exiting" "very last thing" "cleanup"
