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
		name="qcom,ipq8074-ap-hk01-c1"
		;;
	*"AP-HK01-C2")
		name="qcom,ipq8074-ap-hk01-c2"
		;;
	*"AP-HK01-C3")
		name="qcom,ipq8074-ap-hk01-c3"
		;;
	*"AP-HK01-C4")
		name="qcom,ipq8074-ap-hk01-c4"
		;;
	*"AP-HK01-C5")
		name="qcom,ipq8074-ap-hk01-c5"
		;;
	*"AP-HK01-C6")
		name="qcom,ipq8074-ap-hk01-c6"
		;;
	*"AP-HK02")
		name="qcom,ipq8074-ap-hk02"
		;;
	*"AP-HK05")
		name="qcom,ipq8074-ap-hk05"
		;;
	*"AP-HK06")
		name="qcom,ipq8074-ap-hk06"
		;;
	*"AP-HK07")
		name="qcom,ipq8074-ap-hk07"
		;;
	*"AP-HK08")
		name="qcom,ipq8074-ap-hk08"
		;;
	*"AP-HK09")
		name="qcom,ipq8074-ap-hk09"
		;;
	*"AP-HK10")
		name="qcom,ipq8074-ap-hk10"
		;;
	*"AP-HK10-C1")
		name="qcom,ipq8074-ap-hk10-c1"
		;;
	*"AP-HK10-C2")
		name="qcom,ipq8074-ap-hk10-c2"
		;;
	*"AP-HK14")
		name="qcom,ipq8074-ap-hk14"
		;;
	*"AP-AC01.1")
		name="ap-ac01.1"
		;;
	*"AP-AC01.2")
		name="ap-ac01.2"
		;;
	*"DB.HK01")
		name="qcom,ipq8074-db-hk01"
		;;
	*"DB.HK02")
		name="qcom,ipq8074-db-hk02"
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
	*"AP-AL02-C8")
		name="qcom,ipq9574-ap-al02-c8"
		;;
	*"AP-AL02-C9")
		name="qcom,ipq9574-ap-al02-c9"
		;;
	*"AP-AL02-C10")
		name="qcom,ipq9574-ap-al02-c10"
		;;
	*"AP-AL02-C11")
		name="qcom,ipq9574-ap-al02-c11"
		;;
	*"AP-AL02-C12")
		name="qcom,ipq9574-ap-al02-c12"
		;;
	*"AP-AL02-C13")
		name="qcom,ipq9574-ap-al02-c13"
		;;
	*"AP-AL02-C14")
		name="qcom,ipq9574-ap-al02-c14"
		;;
	*"AP-AL02-C15")
		name="qcom,ipq9574-ap-al02-c15"
		;;
	*"AP-AL02-C16")
		name="qcom,ipq9574-ap-al02-c16"
		;;
	*"AP-AL02-C17")
		name="qcom,ipq9574-ap-al02-c17"
		;;
	*"AP-AL02-C18")
		name="qcom,ipq9574-ap-al02-c18"
		;;
	*"AP-AL02-C19")
		name="qcom,ipq9574-ap-al02-c19"
		;;
	*"AP-AL05")
		name="qcom,ipq9574-ap-al05"
		;;
	*"AP-AL06")
		name="qcom,ipq9574-ap-al06"
		;;
	*"AP-MI01.1")
		name="qcom,ipq5332-ap-mi01.1"
		;;
	*"AP-MI01.2")
		name="qcom,ipq5332-ap-mi01.2"
		;;
	*"AP-MI01.2-C2")
		name="qcom,ipq5332-ap-mi01.2-c2"
		;;
	*"AP-MI01.3")
		name="qcom,ipq5332-ap-mi01.3"
		;;
	*"AP-MI01.3-C2")
		name="qcom,ipq5332-ap-mi01.3-c2"
		;;
	*"AP-MI01.4")
		name="qcom,ipq5332-ap-mi01.4"
		;;
	*"AP-MI01.6")
		name="qcom,ipq5332-ap-mi01.6"
		;;
	*"AP-MI01.7")
		name="qcom,ipq5332-ap-mi01.7"
		;;
	*"AP-MI04.1")
		name="qcom,ipq5332-ap-mi04.1"
		;;
	*"AP-MI04.1-C2")
		name="qcom,ipq5332-ap-mi04.1-c2"
		;;
	*"AP-MI01.13")
		name="qcom,ipq5332-ap-mi01.13"
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
