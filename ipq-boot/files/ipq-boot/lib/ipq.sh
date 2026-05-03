#!/bin/sh
#
# Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

IPQ_BOARD_NAME=
IPQ_MODEL=

ipq_board_detect() {
	local machine
	local name
	local pon_dp
	local pon_support

	machine=$(cat /proc/device-tree/model)

	name=$(strings /proc/device-tree/compatible | head -n 1)

	[ -z "$name" ] && name="unknown"

	[ -z "$IPQ_BOARD_NAME" ] && IPQ_BOARD_NAME="$name"
	[ -z "$IPQ_MODEL" ] && IPQ_MODEL="$machine"

	[ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"

	echo "$IPQ_BOARD_NAME" > /tmp/sysinfo/board_name
	echo "$IPQ_MODEL" > /tmp/sysinfo/model

	if grep -Eq 'ap-al05|ap-al06|ap-mi01.2-c2|rdp485|rdp496' /tmp/sysinfo/board_name; then
		touch /tmp/fontanaenabled
	fi

	if grep -Eq 'ipq5210' /tmp/sysinfo/board_name; then
		pon_dp=$(ls /proc/device-tree/soc@0 | grep '^dp[0-9][0-9]*$' | sort | tail -n 1)
		pon_support=$(ls -la /proc/device-tree/soc@0/${pon_dp} | grep gem_port)
		if [ ! -z "$pon_support" ]; then
			touch /tmp/fontanaenabled
		fi
	fi
}

ipq_board_name() {
	local name

	[ ! -f /tmp/sysinfo/board_name ] && ipq_board_detect
	[ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}
