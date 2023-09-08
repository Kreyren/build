#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2013-2023 Igor Pecovnik, igor@armbian.com
#
# This file is a part of the Armbian Build Framework
# https://github.com/armbian/build/

function cli_flash_pre_run() {
	display_alert "cli_distccd_pre_run" "func cli_distccd_run :: ${ARMBIAN_COMMAND}" "warn"

	# "gimme root on a Linux machine"
	cli_standard_relaunch_docker_or_sudo
}

function cli_flash_run() {
	if [ -n "$BOARD" ]; then
		use_board="yes" prep_conf_main_minimal_ni < /dev/null # no stdin for this, so it bombs if tries to be interactive.
	else
		use_board="no" prep_conf_main_minimal_ni < /dev/null # no stdin for this, so it bombs if tries to be interactive.
	fi

	# the full build. It has its own logging sections.
	do_with_default_build cli_flash
}

# Flash the IMAGE to SDCARD and/or FASTBOOT_SENSOR device
function cli_flash() {
	image_file="$IMAGE"

	[ -n "$image_file" ] || {
		display_alert "cli_flash" "No image file specified. Using latest built image file found: ${image_file}" "info"

		# FIXME-QA(Krey): This is disgusting..
		# shellcheck disable=SC2012 # FIXME(Krey): Rationale
		image_file="$(ls -1t "$SRC/output/images"/*"${BOARD^}_$RELEASE_$BRANCH"*.img | head -1)"

		# FIXME(Krey): Decypher the standard naming scheme
		#image_file="Armbian_$VERSION_$BOARD_$RELEASE_$BRANCH_$CONFIG.img"
	}

	# Make sure that the image_file is a sane file
	[ -f "$image_file" ] || exit_with_error "No image file to flash!"

	image_file_basename="$(basename "$image_file")"

	[ -z "$SDCARD" ] || {
		display_alert "cli_flash" "Flashing image file on sdcard '$SDCARD': ${image_file_basename}" "info"
		countdown_and_continue_if_not_aborted 3

		write_image_to_device_and_run_hooks "$image_file"
	}

	[ -z "$FASTBOOT_SERIAL" ] || {
		display_alert "cli_flash" "Flashing image file on fastboot device '$FASTBOOT_UUID': ${image_file_basename}" "info"
		countdown_and_continue_if_not_aborted 3

		fastboot_flash_image_to_device_and_run_hooks "$image_file"
	}
}
