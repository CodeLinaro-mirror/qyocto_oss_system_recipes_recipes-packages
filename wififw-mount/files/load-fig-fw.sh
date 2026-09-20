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
#
# Bind-mount /lib/firmware/fig from the WIFIFW squashfs (if not already
# mounted) and load the fig_v2 (Congo/WCN8850) driver. Shared by
# init-wifi and wififw-mount, and callable directly from the command
# line to manually (re)load the Congo firmware/driver.
#
# Usage: load-fig-fw [-f|--force]
#   -f, --force   Load even if the no_congo cmdline parameter is set.
#
export PATH=$PATH:/sbin:/usr/sbin

force=0
case "$1" in
    -f|--force)
        force=1
        ;;
esac

if [ "$force" -ne 1 ] && grep -qw 'no_congo' /proc/cmdline 2>/dev/null; then
    echo "load-fig-fw: no_congo, skipping fw/driver load" > /dev/console 2>&1
    exit 0
fi

WIFI_FW_FIG=/lib/firmware/IPQ5424/WIFI_FW/fig

if ! mountpoint -q /lib/firmware/fig; then
    if [ -d "$WIFI_FW_FIG" ]; then
        mount --bind "$WIFI_FW_FIG" /lib/firmware/fig
        if [ $? -ne 0 ]; then
            echo "load-fig-fw: fig bind mount failed" > /dev/console 2>&1
            exit 1
        fi
    else
        echo "load-fig-fw: $WIFI_FW_FIG not found" > /dev/console 2>&1
        exit 1
    fi
fi

modprobe fig_v2
