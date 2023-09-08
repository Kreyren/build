#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2023 Jacob Hrbek, kreyren@armbian.com
#
# This file is a part of the Armbian Build Framework
# https://github.com/armbian/build/

# FIXME-QA(Krey): This requires `fastboot` to be executable without priviledged permissions
function fastboot_flash_image_to_device_and_run_hooks() {
	case "$DANGER_ZONE" in
		*"fastboot"*) printf "DANGER_ZONE: %s\n" "EXPERIMENTAL FASTBOOT FLASHING, good luck screwing up your system!" ;;
		 *) exit_with_error "fastboot_flash_image_to_device_and_run_hooks was not verified to work and be reliable"
	esac

	# Check to make sure that the end-user set their fastboot to be usable as non-root
	[ "$FASTBOOT_NORMAL_USER_USABLE" = 1 ] || exit_with_error "Fastboot was not configured to run as a non-priviledged user, override with variable 'FASTBOOT_NORMAL_USER_USABLE' set to the value of '1'"

	[ -z "$1" ] || exit_with_error "Image file '$1' was not found"

	built_image_file="$1"

	# Verify that the FASTBOOT_SERIAL device is connected
	# FIXME-QA(Krey): This should have a better check
	for fastboot_device in $(${FASTBOOT:-fastboot} devices); do
		{ [ "$FASTBOOT_SERIAL" != "${fastboot_device//  */}" ] ;} || fastboot_device_verified=0
	done

	[ -n "$fastboot_device_verified" ] || exit_with_error "Fastboot device '$FASTBOOT_SERIAL' was not found among fastboot devices"

	# Perform the flash
	fastboot_flash_image_to_device "$built_image_file"

	# Hook: post_build_image_write
	call_extension_method "post_build_image_write" <<- 'POST_BUILD_IMAGE_WRITE'
		*custom post build hook*
		Called after the final .img file is ready, and possibly fastboot flashed to the fastboot device: '$FASTBOOT_SERIAL'
		The full path to the image is available in \`$built_image_file\`.
	POST_BUILD_IMAGE_WRITE
}
