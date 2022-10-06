#!/bin/sh
#
# Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
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

START=00
STOP=95

boot() {
	echo " Loading ath12k driver" > /dev/console 2>&1
	modprobe ath12k
	echo " Loading ath11k driver" > /dev/console 2>&1
	modprobe ath11k_ahb
}

stop() {
	echo "ath-autoload stop not implimented"
	return 0
}

#----------------------------------------------------------------------
# main entry
#----------------------------------------------------------------------

case "$1" in
	start)
		boot
		;;
	stop)
		stop
		;;
	*)
		echo "Usage: ath-autoload.sh [ start | stop ]" > /dev/console
		exit 3
		;;
esac

