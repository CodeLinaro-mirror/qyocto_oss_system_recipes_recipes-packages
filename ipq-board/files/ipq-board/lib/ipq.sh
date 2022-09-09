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

	machine=$(cat /proc/device-tree/model)

	case "$machine" in
	*"AP-DK01.1-C1")
		name="ap-dk01.1-c1"
		;;
	*"AP-DK01.1-C2")
		name="ap-dk01.1-c2"
		;;
	*"AP-DK04.1-C1")
		name="ap-dk04.1-c1"
		;;
	*"AP-DK04.1-C2")
		name="ap-dk04.1-c2"
		;;
	*"AP-DK04.1-C3")
		name="ap-dk04.1-c3"
		;;
	*"AP-DK04.1-C4")
		name="ap-dk04.1-c4"
		;;
	*"AP-DK04.1-C5")
		name="ap-dk04.1-c5"
		;;
	*"AP-DK05.1-C1")
		name="ap-dk05.1-c1"
		;;
	*"AP-DK06.1-C1")
		name="ap-dk06.1-c1"
		;;
	*"AP-DK07.1-C1")
		name="ap-dk07.1-c1"
		;;
	*"AP-DK07.1-C2")
		name="ap-dk07.1-c2"
		;;
	*"AP-HK01-C1")
		name="ap-hk01-c1"
		;;
	*"AP-HK01-C2")
		name="ap-hk01-c2"
		;;
	*"AP-HK01-C3")
		name="ap-hk01-c3"
		;;
	*"AP-HK01-C4")
		name="ap-hk01-c4"
		;;
	*"AP-HK02")
		name="ap-hk02"
		;;
	*"AP-HK05")
		name="ap-hk05"
		;;
	*"AP-HK06")
		name="ap-hk06"
		;;
	*"AP-HK07")
		name="ap-hk07"
		;;
	*"AP-HK08")
		name="ap-hk08"
		;;
	*"AP-HK09")
		name="ap-hk09"
		;;
	*"AP-AC01.1")
		name="ap-ac01.1"
		;;
	*"AP-AC01.2")
		name="ap-ac01.2"
		;;
	*"DB.HK01")
		name="db-hk01"
		;;
	*"DB.HK02")
		name="db-hk02"
		;;
	*"AP-AL01-C1")
		name="qcom,ipq9574-ap-al01-c1"
		;;
	*"AP-AL02-C1")
		name="qcom,ipq9574-ap-al02-c1"
		;;
	*"AP-AL02-C2")
		name="qcom,ipq9574-ap-al02-c2"
		;;
	*"AP-AL02-C3")
		name="qcom,ipq9574-ap-al02-c3"
		;;
	*"AP-AL02-C4")
		name="qcom,ipq9574-ap-al02-c4"
		;;
	*"AP-AL02-C5")
		name="qcom,ipq9574-ap-al02-c5"
		;;
	*"AP-AL02-C6")
		name="qcom,ipq9574-ap-al02-c6"
		;;
	*"AP-AL02-C7")
		name="qcom,ipq9574-ap-al02-c7"
		;;
	*"AP-AL02-C10")
		name="qcom,ipq9574-ap-al02-c10"
		;;
	esac

	[ -z "$name" ] && name="unknown"

	[ -z "$IPQ_BOARD_NAME" ] && IPQ_BOARD_NAME="$name"
	[ -z "$IPQ_MODEL" ] && IPQ_MODEL="$machine"

	[ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"

	echo "$IPQ_BOARD_NAME" > /tmp/sysinfo/board_name
	echo "$IPQ_MODEL" > /tmp/sysinfo/model
}

ipq_board_name() {
	local name

	[ ! -f /tmp/sysinfo/board_name ] && ipq_board_detect
	[ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}
