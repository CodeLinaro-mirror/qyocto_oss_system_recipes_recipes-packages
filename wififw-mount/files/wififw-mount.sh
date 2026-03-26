#!/bin/sh
#
# Copyright (c) 2022,2024 Qualcomm Innovation Center, Inc. All rights reserved.
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

if [ -e /lib/read_caldata_to_fs.sh ]
then
. /lib/read_caldata_to_fs.sh
fi

START=00
STOP=95

create_soft_link()
{
        if [ -e /sys/firmware/devicetree/base/AUTO_MOUNT ]; then
                cp -f $*
        elif [ ! -e /sys/firmware/devicetree/base/AUTO_MOUNT ]; then
                ln -s $*
        fi
}

get_partname() {
	local part_name=""
	local parse_value=4
	local mtdpart=$(grep "\"0:BOOTCONFIG\"" /proc/mtd | awk -F: '{print $1}')
	local trymode_inprogress=$(cat /sys/devices/platform/firmware:scm/trymode_inprogress)
	if [ ! -z $mtdpart ]; then
		dd if=/dev/${mtdpart} of=/tmp/bootconfig.bin
		dumpimage -b $parse_value &> /dev/null
		if [[ "$?" == 1 ]];then
			echo "Unable to read bootconfig"
			return 1
		fi
	fi

	if [ ! -e /tmp/bootconfig_members.txt ]; then
		echo " Parsed bootconfig info not available "
		return 1
	fi

	local boot_set=$(grep "Boot-set" /tmp/bootconfig_members.txt | awk -F: '{print $2}')
	local image_status=$(grep "Image-set-status" /tmp/bootconfig_members.txt | awk -F: '{print $2}')

	if [ "$boot_set" -eq 0 ] && [ "$image_status" -eq 1 ]; then
		part_name="1"
	elif [ "$boot_set" -eq 1 ] && [ "$image_status" -ne 2 ]; then
		part_name="1"
	fi

	if [ "$trymode_inprogress" -eq 1 ]; then
		if [ "$part_name" -eq "1" ]; then
			part_name=""
		else
			part_name="1"
		fi
	fi
	if [ -z $mtdpart ] && [  $trymode_inprogress -eq 1 ]; then
		[ "$part_name" == "1" ] && part_name="" || part_name="1"
	fi
	echo $part_name
}

get_partname_legacy() {
	local part_name=$1
	local age0=$(cat /proc/boot_info/bootconfig0/age)
	local age1=$(cat /proc/boot_info/bootconfig1/age)
	local bootname="bootconfig1"

	#Try mode
	if [ -e /proc/upgrade_info/trybit ]; then
		if [ -e /proc/upgrade_info/trymode_inprogress ]; then
			if [ $age0 -le $age1 ]; then
				bootname="bootconfig0"
			else
				bootname="bootconfig1"
			fi
		else
			if [ $age1 -ge $age0 ]; then
				bootname="bootconfig1"
			else
				bootname="bootconfig0"
			fi
		fi
	fi

	primaryboot=$(cat /proc/boot_info/$bootname/$part_name/primaryboot)
	if [ $primaryboot -eq 1 ]; then
		part_name="0:WIFIFW_1"
	fi

	echo $part_name
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
		if [ "$board_name" == "ap" ]; then
			board_name=$(cat /tmp/sysinfo/board_name | awk -F, '{print$2}')
		fi

		case $board_name in
                        *rdp*)
                        board_name=$(echo $board_name | cut -f2 -d-)
                        ;;
                esac

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

	if [ "$arch" == "IPQ5424" ]; then
		local index=$(get_partname $part_name $arch)
		if [ "$index" == "1" ]; then
			part_name=${part_name}_${index}
			ubi_part_name=${ubi_part_name}_${index}
		fi
	else
		part_name=$(get_partname_legacy $part_name)
	fi

        if [[ "$arch" == "IPQ9574" ]] || [[ "$arch" == "IPQ5332" ]] || [[ "$arch" == "IPQ5424" ]]; then
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
                if [ $? -eq 0 ]; then
                        cp /rom/lib/firmware/$arch/WIFI_FW/*.* /lib/firmware/$arch/WIFI_FW/
                fi
        elif [ -n "$nor_flash" ]; then
                local nor_mtd_part=$(find_mtd_part $part_name 2> /dev/null)
                if [ -n "$nor_mtd_part" ]; then
                        /bin/mount -t squashfs $nor_mtd_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                fi
        elif [ -n "$nand_part" ]; then
                if [ -n "$wifi_on_rootfs" ]; then
                       local PART=$(grep -w  "$ubi_part_name" /proc/mtd | awk -F: '{print $1}')
                else
                       local PART=$(grep -w  "$part_name" /proc/mtd | awk -F: '{print $1}')
                fi
                ubiattach -p /dev/$PART
                sync
                local ubi_part=$(find_mtd_part wifi_fw 2> /dev/null)
                if [ -n "$ubi_part" ]; then
                        /bin/mount -t squashfs $ubi_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                        if [ $? -ne 0 ]; then
                                echo "WIFI FW mount failed, retry after 1 sec" > /dev/console 2>&1
                                sleep 1
                                /bin/mount -t squashfs $ubi_part /lib/firmware/$arch/WIFI_FW > /dev/console 2>&1
                                if [ $? -ne 0 ]; then
                                        echo "CRITICAL:WIFI FW mount failed, after 1 sec retry" > /dev/console 2>&1
                                        echo $(cat /proc/mtd) > /dev/console 2>&1
                                        return -1
                                fi
                        fi
                fi
        fi
        if [ -f /lib/firmware/$arch/WIFI_FW/q6_fw.mdt ] || ([ -f /lib/firmware/$arch/WIFI_FW/q6_fw0.mdt ] && [ -f /lib/firmware/$arch/WIFI_FW/q6_fw1.mdt ]); then
                echo " WIFI FW mount is successful" > /dev/console 2>&1
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9000 ]; then
                cd  $fwfolder && mkdir -p qcn9000 && mkdir -p /vendor/firmware/qcn9000
                cd qcn9000 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9000/*.* .
                cd /vendor/firmware/qcn9000 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9000/Data.msc .
                mkdir -p /lib/firmware/qcn9000 && cd /lib/firmware/qcn9000 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9224 ]; then
                cd  $fwfolder && mkdir -p qcn9224 && mkdir -p /vendor/firmware/qcn9224
                cd qcn9224 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/*.* .
                cd /vendor/firmware/qcn9224 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/Data.msc .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/Data_dualmac.msc .
                mkdir -p /lib/firmware/qcn9224 && cd /lib/firmware/qcn9224 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                cd $fwfolder && mkdir -p qcn9100 && mkdir -p /vendor/firmware/qcn9100
                cd qcn9100 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9100/*.* . && ln -s /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn9100 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9100/Data.msc .
                mkdir -p /lib/firmware/qcn9100 && cd /lib/firmware/qcn9100 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9100/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn6122 ]; then
                cd $fwfolder && mkdir -p qcn6122 && mkdir -p /vendor/firmware/qcn6122
                cd qcn6122 && ln -s /lib/firmware/$arch/WIFI_FW/qcn6122/*.* . && ln -s /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn6122 && ln -s /lib/firmware/$arch/WIFI_FW/qcn6122/Data.msc .
                mkdir -p /lib/firmware/qcn6122 && cd /lib/firmware/qcn6122 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn6122/qdss* .
        elif [ -d /lib/firmware/$arch/WIFI_FW/qcn9100 ]; then
                cd $fwfolder && mkdir -p qcn6122 && mkdir -p /vendor/firmware/qcn6122
                cd qcn6122 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9100/*.* . && ln -s /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn6122 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9100/Data.msc .
                mkdir -p /lib/firmware/qcn6122 && cd /lib/firmware/qcn6122 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9100/qdss* .
        fi

        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9160 ]; then
                cd $fwfolder && mkdir -p qcn9160 && mkdir -p /vendor/firmware/qcn9160
                cd qcn9160 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9160/*.* . && ln -s /lib/firmware/$arch/WIFI_FW/q6_fw.* .
                cd /vendor/firmware/qcn9160 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9160/Data.msc .
                mkdir -p /lib/firmware/qcn9160 && cd /lib/firmware/qcn9160 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9160/qdss* .
        fi

	if [ -d /lib/firmware/$arch/WIFI_FW/qcn6432 ]; then
		cd $fwfolder && mkdir -p qcn6432 && mkdir -p /vendor/firmware/qcn6432
		cd qcn6432 && ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/*.* . && ln -s /lib/firmware/$arch/WIFI_FW/q6_fw.* .
		cd /vendor/firmware/qcn6432 && ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/Data.msc .
		mkdir -p /lib/firmware/qcn6432 && cd /lib/firmware/qcn6432 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn6432/qdss* .
	fi

        mkdir -p $fwfolder/$arch
        cd  $fwfolder/$arch && ln -s /lib/firmware/$arch/WIFI_FW/*.* .
        cd  /lib/firmware/$arch && create_soft_link /lib/firmware/$arch/WIFI_FW/qdss* .
        if [ -e /sys/firmware/devicetree/base/MP_512 ] || [ -e /sys/firmware/devicetree/base/MP_256 ]; then
                #qcn9224 INI file would have all QCN9224 RDP's info, so first priority for qcn9224 file if it exists
                if [ -f /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature_512P.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature_512P.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature_512P.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature_512P.ini .
                fi
        else
                #qcn9224 INI file would have all QCN9224 RDP's info, so first priority for qcn9224 file if it exists
                if [ -f /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9224/firmware_rdp_feature.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/firmware_rdp_feature.ini .
                elif [ -f /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature.ini ]; then
                        cd /lib/firmware
                        create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9000/firmware_rdp_feature.ini .
                fi
        fi

        do_load_ipq4019_board_bin

        if [ -e /lib/firmware/$arch/WIFI_FW/board-2.bin ]; then

                case "$arch" in
                        IPQ5332 | \
                        IPQ5424)
                                mkdir -p /lib/firmware/ath12k/$arch/$hw
                                cd /lib/firmware/ath12k/$arch/$hw/
                                ;;
                        *)
                                mkdir -p /lib/firmware/ath11k/$arch/$hw
                                cd /lib/firmware/ath11k/$arch/$hw/
                                ;;
                esac
                ln -sf /lib/firmware/$arch/WIFI_FW/board-2.bin .
                ln -sf /tmp/$arch/caldata.bin .
                ln -sf /lib/firmware/$arch/qdss_trace_config.bin .
                ln -sf /lib/firmware/$arch/WIFI_FW/q6_fw*  .
                ln -sf /lib/firmware/$arch/WIFI_FW/iu_fw*  .

                case $board_name in
                        ap-mi01.3|ap-mi01.3-c3|ap-mi01.3-c2|ap-mi04.1|ap-mi04.1-c2|ap-mi01.2|ap-mi01.2-c2|ap-mi01.6|ap-mi01.12|ap-mi01.14|ap-mi04.3|ap-mi04.5|ap-mi01.3-c5)
                                #caldata.bin --> ahb 2GHz
                                if [ -e /lib/firmware/IPQ5332/caldata.bin ]; then
                                        ln -sf /lib/firmware/IPQ5332/caldata.bin cal-ahb-c000000.wifi.bin
                                fi
                        ;;
                        *)
                                #No sym links
                        ;;
                esac

                case $board_name in
                        rdp466* |\
                        rdp487* |\
                        rdp464* |\
                        rdp485* |\
                        rdp496)
                                #caldata.bin --> ahb 2GHz
                                if [ -e /lib/firmware/IPQ5424/caldata.bin ]; then
                                        ln -sf /lib/firmware/IPQ5424/caldata.bin cal-ahb-c000000.wifi.bin
                                fi
                        ;;
                        *)

                                #No sym links
                        ;;
                esac

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
	elif [ -d /lib/firmware/$arch/WIFI_FW/qcn9224 ]; then
                if [  -e /lib/firmware/$arch/WIFI_FW/qcn9224/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath12k/QCN92XX/hw1.0/
                        cd /lib/firmware/ath12k/QCN92XX/hw1.0/
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/m3.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/amss.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/amss_dualmac.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/board-2.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/regdb.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/qdss_trace_config.bin .
                fi
        fi
	if [ -d /lib/firmware/$arch/WIFI_FW ]; then
                if [  -e /lib/firmware/$arch/WIFI_FW/board-2.bin ]; then
                        mkdir -p /lib/firmware/ath12k/IPQ5332/hw1.0/
                        cd /lib/firmware/ath12k/IPQ5332/hw1.0/
                        ln -s /lib/firmware/$arch/WIFI_FW/board-2.bin .
                        ln -s /lib/firmware/$arch/WIFI_FW/qdss_trace_config.bin .
                fi
        fi
        mkdir -p /vendor/firmware/$arch
        cd /vendor/firmware/$arch && ln -sf /lib/firmware/$arch/WIFI_FW/Data.msc .
}

boot() {
 # . /lib/functions/system.sh

	echo "ini" >  /sys/module/firmware_class/parameters/path

        if grep -q "IPQ5424" /proc/device-tree/model; then
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $2}')
        else
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $2}')
        fi
        if [ "$platform" == "IPQ9574" ]; then
                mount_wifi_fw "IPQ9574"
        elif [ "$platform" == "IPQ5332" ]; then
                mount_wifi_fw "IPQ5332"
        elif [ "$platform" == "IPQ8074" ]; then
                mount_wifi_fw "IPQ8074"
        elif [ "$platform" == "IPQ5424" ]; then
                mount_wifi_fw "IPQ5424"
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

        if [[ "$arch" == "IPQ6018" ]] || [[ "$arch" == "IPQ5018" ]] || [[ "$arch" == "IPQ9574" ]] || [[ "$arch" == "IPQ5332" ]] || [[ "$arch" == "IPQ5424" ]]; then
                part_name="rootfs"
                wifi_on_rootfs="1"
        fi

	if [ "$arch" == "IPQ5424" ]; then
                local index=$(get_partname $part_name $arch)
                if [ "$index" == "1" ]; then
                        part_name=${part_name}_${index}
                        ubi_part_name=${part_name}_${index}
                fi
        else
                part_name=$(get_partname_legacy $part_name)        
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
        if grep -q "IPQ5424" /proc/device-tree/model; then
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $2}')
        else
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $2}')
        fi

        if [ "$platform" == "IPQ9574" ]; then
                stop_wifi_fw "IPQ9574"
        elif [ "$platform" == "IPQ5332" ]; then
                stop_wifi_fw "IPQ5332"
        elif [ "$platform" == "IPQ8074" ]; then
                stop_wifi_fw "IPQ8074"
        elif [ "$platform" == "IPQ5424" ]; then
                stop_wifi_fw "IPQ5424"
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
        [ ! -e /tmp/sysinfo/board_name  ] && {
               . /lib/ipq.sh
               ipq_board_detect
        }
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

