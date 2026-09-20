#!/bin/sh
#
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
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

export PATH=$PATH:/sbin:/usr/sbin

#
# Early boot logger
#
log_time()
{
    if [ -c /dev/kmsg ]; then
        echo "<6>[init-wifi] $*" > /dev/kmsg
    else
        echo "[init-wifi] $*"
    fi
}

#
# Mount proc
#
if [ ! -r /proc/modules ]; then
    mount -t proc proc /proc
fi

#
# Mount sysfs
#
if [ ! -d /sys/module ]; then
    mount -t sysfs sysfs /sys
fi

#
# Check for no_congo cmdline parameter
#
if grep -qw 'no_congo' /proc/cmdline 2>/dev/null; then
    log_time "no_congo: skipping fw/driver load"
    exec /sbin/init
fi

#
# Detect WIFI_FW storage
#
WIFIFW_DEV=

#
# eMMC path
#
for uevent in /sys/class/block/mmcblk0p*/uevent; do

    [ -f "$uevent" ] || continue

    if grep -q 'PARTNAME=0:WIFIFW' "$uevent" 2>/dev/null; then

        dev=$(sed -n 's/^DEVNAME=//p' "$uevent")

        WIFIFW_DEV="/dev/$dev"

        break
    fi
done

#
# NAND path
#
if [ -z "$WIFIFW_DEV" ]; then

    mtdline=$(grep '"wifi_fw"' /proc/mtd 2>/dev/null)

    if [ -n "$mtdline" ]; then

        mtdnum=$(echo "$mtdline" | awk -F: '{print $1}' | sed 's/mtd//')

        WIFIFW_DEV="/dev/mtdblock${mtdnum}"
    fi
fi

#
# Mount firmware squashfs
#
mount -t squashfs \
    "$WIFIFW_DEV" \
    /lib/firmware/IPQ5424/WIFI_FW
if [ $? -ne 0 ]; then
    log_time "WIFI_FW mount failed dev=$WIFIFW_DEV"
fi

#
# Bind-mount FIG firmware and load the driver
#
load-fig-fw &

exec /sbin/init
