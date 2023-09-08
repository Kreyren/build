#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2013-2023 Igor Pecovnik, igor@armbian.com
# Copyright (c) 2023 Jacob Hrbek, kreyren@armbian.com
#
# This file is a part of the Armbian Build Framework
# https://github.com/armbian/build/

# Flash the image through fastboot on the device
function fastboot_flash_image_to_device() {
	case "$DANGER_ZONE" in
		*"fastboot"*) printf "DANGER_ZONE: %s\n" "EXPERIMENTAL FASTBOOT FLASHING, good luck screwing up your system!" ;;
		 *) exit_with_error "fastboot_flash_image_to_device_and_run_hooks was not verified to work and be reliable"
	esac

	[ -z "$FASTBOOT_SERIAL" ] || exit_with_error "Variable 'FASTBOOT_SERIAL' needs to be set to allow fastboot flashing"

	# Inputs
	bootloader_image="$1"
	rootfs_archive="$2"

	# Sanity-check for inputs
	[ -z "$bootloader_image" ] || exit_with_error "Bootloader image has to be set to perform fastboot flashing"
	[ -z "$rootfs_archive" ] || exit_with_error "Rootfs archive has to be set to perform fastboot flashing"

	# Perform the flash
	case "$BOARD" in
		# Refer to https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/4_burn_image.html#Linux for details
		"sipeed-licheepi-4a")
			${FASTBOOT:-fastboot} -s "$FASTBOOT_SERIAL" flash rom "$bootloader_image"

			${FASTBOOT:-fastboot} -s "$FASTBOOT_SERIAL" reboot

			# FIXME-QA(Krey): Implement a check that runs once the device successfully reboots
			sleep 10

			${FASTBOOT:-fastboot} -s "$FASTBOOT_SERIAL" flash uboot "$bootloader_image"

			${FASTBOOT:-fastboot} -s "$FASTBOOT_SERIAL" flash rootfs "$rootfs_archive"
			;;
		*)
			exit_with_error "Board '$BOARD' is not implemented for fastboot flashing"
	esac
}


# @TODO: make usable as a separate tool as well
function write_image_to_device() {
	local image_file="${1}"
	local device="${2}"
	if [[ $(lsblk "${device}" 2> /dev/null) && -f "${image_file}" ]]; then

		if [[ "${SKIP_VERIFY}" != "yes" ]]; then
			# create sha256sum if it does not exist. we need it for comparison, later.
			local if_sha=""
			if [[ -f "${image_file}.img.sha" ]]; then
				# shellcheck disable=SC2002 # cat most definitely is useful. she purrs.
				if_sha=$(cat "${image_file}.sha" | awk '{print $1}')
			else
				if_sha=$(sha256sum -b "${image_file}" | awk '{print $1}')
			fi
		fi

		display_alert "Writing image" "${device} ${if_sha}" "info"

		# write to SD card
		pv -p -b -r -c -N "$(logging_echo_prefix_for_pv "write_device") dd" "${image_file}" | dd "of=${device}" bs=1M iflag=fullblock oflag=direct status=none

		call_extension_method "post_write_sdcard" <<- 'POST_WRITE_SDCARD'
			*run after writing img to sdcard*
			After the image is written to `${device}`, but before verifying it.
			You can still set SKIP_VERIFY=yes to skip verification.
		POST_WRITE_SDCARD

		if [[ "${SKIP_VERIFY}" != "yes" ]]; then
			# read and compare
			display_alert "Verifying. Please wait!"
			local of_sha=""
			of_sha=$(dd "if=${device}" "count=$(du -b "${image_file}" | cut -f1)" status=none iflag=count_bytes oflag=direct | sha256sum | awk '{print $1}')
			if [[ "$if_sha" == "$of_sha" ]]; then
				display_alert "Writing verified" "${image_file}" "info"
			else
				display_alert "Writing failed" "${image_file}" "err"
			fi
		fi
	elif armbian_is_running_in_container; then
		if [[ -n ${device} ]]; then
			# display warning when we want to write sd card under Docker
			display_alert "Can't write to ${device}" "Under Docker" "wrn"
		fi
	fi
}
