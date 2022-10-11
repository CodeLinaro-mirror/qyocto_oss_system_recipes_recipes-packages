#!/bin/sh
#
# Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
#
# Copyright (c) 2017-2022 The Linux Foundation. All rights reserved.
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

. /lib/functions/boot.sh
. /lib/read_caldata_to_fs.sh

START=00
STOP=95

create_soft_link()
{
        if [ -e /sys/firmware/devicetree/base/AUTO_MOUNT ]; then
                cp -f $*
        elif [ ! -e /sys/firmware/devicetree/base/AUTO_MOUNT ]; then
                ln -sf $*
        fi
}

mount_wifi_fw (){
        local emmc_part=""
        local nand_part=""
        local nor_part=""
        local primaryboot=""
        local part_name="0:WIFIFW"
        local ubi_part_name="rootfs"
        local arch=""
        local wifi_on_rootfs=""
        local hw=""
        local board_name
        local fwfolder="/lib/firmware"

        [ -f /tmp/sysinfo/board_name ] && {
                board_name=ap$(cat /tmp/sysinfo/board_name | awk -F 'ap' '{print$2}')
        }

        [ -e /sys/firmware/devicetree/base/AUTO_MOUNT ] && {
                case $board_name in
                        ap-mp*)
                                fwfolder="/lib/firmware/wifi"
                                mkdir -p $fwfolder
                        ;;
                esac
        }

        if mount | grep -q WIFI_FW; then
                return 0
        fi

        arch=$1
        case "$arch" in
                "IPQ8074")
                        hw="hw2.0"
        ;;
                "IPQ6018")
                        hw="hw1.0"
        ;;
                *)
                        hw="hw1.0"
        ;;
        esac

        primaryboot=$(cat /proc/boot_info/$part_name/primaryboot)
        if [ $primaryboot -eq 1 ]; then
                part_name="0:WIFIFW_1"
        fi
        if [[ "$arch" == "IPQ9574" ]]; then
                wifi_on_rootfs="1"
        fi

        emmc_part=$(find_mmc_part $part_name 2> /dev/null)
        nor_part=$(cat /proc/mtd | grep -w "WIFIFW" | awk '{print $1}' | sed 's/:$//')
        local nor_flash=`find /sys/bus/spi/devices/*/mtd -name ${nor_part} 2>/dev/null`
        if [ -n "$wifi_on_rootfs" ]; then
                nand_part=$(find_mtd_part $ubi_part_name 2> /dev/null)
                if [ -n "$nand_part" ]; then
                        emmc_part=""
                fi
        else
                nand_part=$(find_mtd_part $part_name 2> /dev/null)
        fi

        mkdir -p /lib/firmware/$arch/WIFI_FW

        if [ -n "$emmc_part" ]; then
                /bin/mount -t squashfs $emmc_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                [ -f /rom/lib/firmware/$arch/WIFI_FW/q6_fw.mdt ] && cp /rom/lib/firmware/$arch/WIFI_FW/*.* /lib/firmware/$arch/WIFI_FW/
        elif [ -n "$nor_flash" ]; then
                local nor_mtd_part=$(find_mtd_part $part_name 2> /dev/null)
                if [ -n "$nor_mtd_part" ]; then
                        /bin/mount -t squashfs $nor_mtd_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                fi
        elif [ -n "$nand_part" ]; then
                if [ -n "$wifi_on_rootfs" ]; then
                       local PART=$(grep -w  "rootfs" /proc/mtd | awk -F: '{print $1}')
                else
                       local PART=$(grep -w  "WIFIFW" /proc/mtd | awk -F: '{print $1}')
                fi
                ubiattach -p /dev/$PART
                sync
                local ubi_part=$(find_mtd_part wifi_fw 2> /dev/null)
                if [ -n "$ubi_part" ]; then
                        /bin/mount -t squashfs $ubi_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                        if [ ! -f /lib/firmware/$arch/WIFI_FW/q6_fw.mdt ]; then
                                echo "WIFI FW mount failed, retry after 1 sec" > /dev/console 2>&1
                                sleep 1
                                /bin/mount -t squashfs $ubi_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                        fi
                fi
        fi
        if [ -f /lib/firmware/$arch/WIFI_FW/q6_fw.mdt ]; then
                echo " WIFI FW mount is successful" > /dev/console 2>&1
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9000 ]; then
                cd  $fwfolder && mkdir -p qcn9000 && mkdir -p /vendor/firmware/qcn9000
                cd qcn9000 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/*.* .
                cd /vendor/firmware/qcn9000 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/Data.msc .
                mkdir -p /lib/firmware/qcn9000 && cd /lib/firmware/qcn9000 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9224 ]; then
                cd  $fwfolder && mkdir -p qcn9224 && mkdir -p /vendor/firmware/qcn9224
                cd qcn9224 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9224/*.* .
                cd /vendor/firmware/qcn9224 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9224/Data.msc .
                mkdir -p /lib/firmware/qcn9224 && cd /lib/firmware/qcn9224 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                cd $fwfolder && mkdir -p qcn9100 && mkdir -p /vendor/firmware/qcn9100
                cd qcn9100 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/*.* . && ln -sf /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn9100 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/Data.msc .
                mkdir -p /lib/firmware/qcn9100 && cd /lib/firmware/qcn9100 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9100/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn6122 ]; then
                cd $fwfolder && mkdir -p qcn6122 && mkdir -p /vendor/firmware/qcn6122
                cd qcn6122 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn6122/*.* . && ln -sf /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn6122 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn6122/Data.msc .
                mkdir -p /lib/firmware/qcn6122 && cd /lib/firmware/qcn6122 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn6122/qdss* .
        elif [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                cd $fwfolder && mkdir -p qcn6122 && mkdir -p /vendor/firmware/qcn6122
                cd qcn6122 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/*.* . && ln -sf /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn6122 && ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/Data.msc .
                mkdir -p /lib/firmware/qcn6122 && cd /lib/firmware/qcn6122 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9100/qdss* .
        fi

        mkdir -p $fwfolder/$arch
        cd  $fwfolder/$arch && ln -sf /lib/firmware/$arch/WIFI_FW/*.* .
        cd  /lib/firmware/$arch && create_soft_link /lib/firmware/$arch/WIFI_FW/qdss* .
        if [ -e /sys/firmware/devicetree/base/MP_512 ] || [ -e /sys/firmware/devicetree/base/MP_256 ]; then
                if [ -f /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature_512P.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature_512P.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature_512P.ini .
                fi
        else
                if [ -f /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature.ini .
                fi
        fi

        do_load_ipq_board_bin

        if [ -e /lib/firmware/$arch/WIFI_FW/board-2.bin ]; then
                mkdir -p /lib/firmware/ath11k/$arch/$hw
                cd /lib/firmware/ath11k/$arch/$hw/
                ln -sf /lib/firmware/$arch/WIFI_FW/board-2.bin .
                ln -sf /tmp/$arch/caldata.bin .
                ln -sf /lib/firmware/$arch/qdss_trace_config.bin .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9000 ]; then
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn9000/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath11k/QCN9074/hw1.0/
                        cd /lib/firmware/ath11k/QCN9074/hw1.0/
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/board-2.bin .
                        ln -sf /tmp/qcn9000/caldata*.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/m3.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/amss.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9000/qdss_trace_config.bin .
                fi
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn9100/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath11k/qcn9100/hw1.0/
                        cd /lib/firmware/ath11k/qcn9100/hw1.0/
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/board-2.bin .
                        ln -sf /lib/firmware/qcn9100/caldata*.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/qdss_trace_config.bin .
                fi
        fi
        if [ -d /lib/firmware/$arch/WIFI_FW/qcn6122 ]; then
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn6122/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath11k/qcn6122/hw1.0/
                        cd /lib/firmware/ath11k/qcn6122/hw1.0/
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn6122/board-2.bin .
                        ln -sf /lib/firmware/qcn6122/caldata*.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn6122/qdss_trace_config.bin .
                fi
        elif [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn9100/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath11k/qcn6122/hw1.0/
                        cd /lib/firmware/ath11k/qcn6122/hw1.0/
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/board-2.bin .
                        ln -sf /lib/firmware/qcn9100/caldata*.bin .
                        ln -sf /lib/firmware/$arch/WIFI_FW/qcn9100/qdss_trace_config.bin .
                fi
        fi

        mkdir -p /vendor/firmware/$arch
        cd /vendor/firmware/$arch && ln -sf /lib/firmware/$arch/WIFI_FW/Data.msc .
}

boot() {
 # . /lib/functions/system.sh
        local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $1}')
        local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $2}')
        if [ "$platform" == "IPQ9574" ]; then
                mount_wifi_fw "IPQ9574"
        else
                echo "\nInvalid Target"
        fi
}

stop_wifi_fw() {
        local emmc_part=""
        local nand_part=""
        local nor_part=""
        local primaryboot=""
        local part_name="0:WIFIFW"
        local wifi_on_rootfs=""
        local nor_flash=""
        arch=$1

        if [[ "$arch" == "IPQ6018" ]] || [[ "$arch" == "IPQ5018" ]] || [[ "$arch" == "IPQ9574" ]]; then
                part_name="rootfs"
                wifi_on_rootfs="1"
        fi

        primaryboot=$(cat /proc/boot_info/$part_name/primaryboot)
        if [ $primaryboot -eq 1 ]; then
                part_name="${part_name}_1"
        fi

        emmc_part=$(find_mmc_part $part_name 2> /dev/null)
        nor_part=$(cat /proc/mtd | grep -w "WIFIFW" | awk '{print $1}' | sed 's/:$//')
        if [ -n "$nor_part" ]; then
                nor_flash=`find /sys/bus/spi/devices/*/mtd -name ${nor_part}`
        fi
        nand_part=$(find_mtd_part $part_name 2> /dev/null)
        if [ -n "$emmc_part" ]; then
                umount /lib/firmware/$arch/WIFI_FW
        elif [ -n "$nor_flash" ]; then
                local nor_mtd_part=$(find_mtd_part $part_name 2> /dev/null)
                umount /lib/firmware/$arch/WIFI_FW
        elif [ -n "$nand_part" ]; then
                umount /lib/firmware/$arch/WIFI_FW
                if [ -z "$wifi_on_rootfs" ]; then
                        local PART=$(grep -w  "WIFIFW" /proc/mtd | awk -F: '{print $1}')
                        ubidetach -f -p  /dev/$PART
                        sync
                fi
        fi
}


stop() {
        local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $1}')
        local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $2}')

        if [ "$platform" == "IPQ9574" ]; then
                stop_wifi_fw "IPQ9574"
        else
                echo "\nInvalid Target"
                return 0
        fi
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
        echo "Usage: wifi_fw_mount.sh [ start | stop ]" > /dev/console
        exit 3
        ;;
esac

