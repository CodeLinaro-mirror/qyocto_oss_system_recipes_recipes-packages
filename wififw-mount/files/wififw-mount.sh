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

update_ath12k_module_parameters()
{
        # $1 = arch (e.g. IPQ9650, IPQ5332, …)
        local arch="$1"

        # modprobe reads options from /etc/modprobe.d/ - this is what systemd-modules-load uses
        ath12k_modprobe_conf="/etc/modprobe.d/ath12k.conf"
        [ ! -e "$ath12k_modprobe_conf" ] && {
                echo "Error: ath12k modprobe conf not found at $ath12k_modprobe_conf" > /dev/console
                return
        }

        boot_arguments=$(cat /proc/cmdline)

        # Read the existing options line (or start a fresh one)
        existing_line=$(grep "^options ath12k" "$ath12k_modprobe_conf")
        if [ -z "$existing_line" ]; then
                options_line="options ath12k dyndbg=+p debug_mask=0xffffffff"
        else
                options_line="$existing_line"
        fi

        # ----------------------------------------------------------------
        # IPQ9650-specific: parse ath12k_<param>=<val> from /proc/cmdline
        # and append any new ones to the options line.
        # ----------------------------------------------------------------
        if [ "$arch" = "IPQ9650" ]; then
                for argument in $boot_arguments; do
                        case "$argument" in
                                ath12k_*=*)
                                        param="${argument#ath12k_}"
                                        param_name="${param%%=*}"
                                        if ! echo "$options_line" | grep -qw "$param_name"; then
                                                options_line="$options_line $param"
                                        fi
                                        ;;
                        esac
                done
        fi

        # ----------------------------------------------------------------
        # Universal: sync ftm_mode in modprobe conf with wifi_ftm_mode
        # bootarg for ALL IPQ chipsets.
        #   wifi_ftm_mode present  -> add ftm_mode=1 if not already there
        #   wifi_ftm_mode absent   -> strip any previously written ftm_mode=*
        # ----------------------------------------------------------------
        if echo "$boot_arguments" | grep -qw "wifi_ftm_mode"; then
                if ! echo "$options_line" | grep -qw "ftm_mode"; then
                        options_line="$options_line ftm_mode=1"
                fi
                echo "ath12k: wifi_ftm_mode in cmdline, setting ftm_mode=1" > /dev/console
        else
                # Remove any ftm_mode=<val> token left by a previous FTM boot
                options_line=$(echo "$options_line" | sed 's/[[:space:]]*ftm_mode=[^[:space:]]*//')
        fi

        # Replace the 'options ath12k' line in the modprobe conf, preserving any other lines
        grep -v "^options ath12k" "$ath12k_modprobe_conf" > /tmp/ath12k_modprobe_rest
        {
                echo "$options_line"
                cat /tmp/ath12k_modprobe_rest
        } > "$ath12k_modprobe_conf"
        rm -f /tmp/ath12k_modprobe_rest

        echo "ath12k: updated $ath12k_modprobe_conf:" > /dev/console
        cat "$ath12k_modprobe_conf" > /dev/console
}

#Extended version of caldata_symlink_creation and picks up directory as well from ftm.conf
caldata_symlink_creation_mr(){
	var=0
	while read -r line
	do
		board=$(echo $line | cut -f1 -d',')
		if [[ "$board" == "$1" ]]; then
			var=$((var+1))
			#$2 passed as an argument should be ftm.conf line index within the ftm.conf for a given board/RDP
			if [[ $var == $2 ]]; then
				local brdid=$(echo $line | cut -f2 -d',')
				local art_slot=$(echo $line | cut -f3 -d',')
				local pciid=$(echo $line | cut -f6 -d',')
				local dir_lib=$(echo $line | cut -f7 -d',')
				break
			fi
		fi
	done < /lib/firmware/ftm.conf

	if [ -e "/lib/firmware/${dir_lib}/caldata_${art_slot}.b${brdid}" ]; then
		ln -sf "/lib/firmware/${dir_lib}/caldata_${art_slot}.b${brdid}" \
			"cal-pci-000${pciid}:01:00.0.bin"
	fi
}

caldata_symlink_creation(){
    var=0
    local brdid=""
    local art_slot=""
    local pciid=""

    while read -r line
    do
        board=$(echo $line | cut -f1 -d',')
        if [[ "$board" == "$1" ]]; then
            var=$((var+1))
            #$2 passed as an argument should be ftm.conf line index within the ftm.conf for a given board/RDP
            if [[ $var == $2 ]]; then
                local brdid=$(echo $line | cut -f2 -d',')
                local art_slot=$(echo $line | cut -f3 -d',')
                local pciid=$(echo $line | cut -f6 -d',')
                break
            fi
        fi
    done < /lib/firmware/ftm.conf

    if [ -z "$brdid" ] || [ -z "$art_slot" ] || [ -z "$pciid" ]; then
        echo "caldata_symlink_creation: no entry found for board=$1 index=$2" > /dev/console
        return 1
    fi

    if [ -e "/lib/firmware/qcn9224/caldata_${art_slot}.b${brdid}" ]; then
        ln -sf "/lib/firmware/qcn9224/caldata_${art_slot}.b${brdid}" \
            "cal-pci-000${pciid}:01:00.0.bin"
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

	if [ "$arch" == "IPQ5424" ] || [ "$arch" == "IPQ5210" ] || [ "$arch" == "IPQ9650" ]; then
		local index=$(get_partname $part_name $arch)
		if [ "$index" == "1" ]; then
			part_name=${part_name}_${index}
			ubi_part_name=${ubi_part_name}_${index}
		fi
	else
		part_name=$(get_partname_legacy $part_name)
	fi

        if [[ "$arch" == "IPQ9574" ]] || [[ "$arch" == "IPQ5332" ]] || [[ "$arch" == "IPQ5424" ]] || [[ "$arch" == "IPQ5210" ]] || [[ "$arch" == "devsoc" ]] || [[ "$arch" == "IPQ9650" ]]; then
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

    if [ -d /lib/firmware/$arch/WIFI_FW/qcn9625 ]; then
        cd  $fwfolder && mkdir -p qcn9625 && mkdir -p /vendor/firmware/qcn9625
        cd qcn9625 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/*.* .
        cd /vendor/firmware/qcn9625 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9625/Data.msc .
        create_soft_link Data.msc Data_dualmac.msc
        mkdir -p /lib/firmware/qcn9625 && cd /lib/firmware/qcn9625 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9625/qdss* .
    fi

    if [ -d /lib/firmware/$arch/WIFI_FW/qcn9589 ]; then
        cd  $fwfolder && mkdir -p qcn9589 && mkdir -p /vendor/firmware/qcn9589
        cd qcn9589 && ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/*.* .
        cd /vendor/firmware/qcn9589 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9589/Data.msc .
        create_soft_link Data.msc Data_dualmac.msc
        mkdir -p /lib/firmware/qcn9589 && cd /lib/firmware/qcn9589 && create_soft_link /lib/firmware/$arch/WIFI_FW/qcn9589/qdss* .
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

        # Update ath12k module parameters for this chipset.
        # ftm_mode=1 propagation is universal; ath12k_* cmdline params are
        # only parsed for IPQ9650 (original behaviour preserved).
        update_ath12k_module_parameters "$arch"

        do_load_ipq4019_board_bin

        if [ -e /lib/firmware/$arch/WIFI_FW/board-2.bin ]; then

                case "$arch" in
                        IPQ5332 | \
                        IPQ5424)
                                mkdir -p /lib/firmware/ath12k/$arch/$hw
                                cd /lib/firmware/ath12k/$arch/$hw/
                                ;;
			IPQ5210 |\
			IPQ9650)
				:   # no operation
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

    if [ -d /lib/firmware/$arch/WIFI_FW/qcn6432 ]; then
        if [ -e /lib/firmware/$arch/WIFI_FW/qcn6432/board-2.bin ]; then
            mkdir -p /lib/firmware/ath12k/QCN6432/hw1.0/
            cd /lib/firmware/ath12k/QCN6432/hw1.0/
            ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/board-2.bin .
            if [ -e /lib/firmware/$arch/WIFI_FW/qcn6432/fw_ini_cfg.bin ]; then
                ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/fw_ini_cfg.bin .
            fi
            ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/qdss_trace_config.bin .
            ln -s /lib/firmware/$arch/WIFI_FW/qcn6432/iu_fw* .
            ln -s /lib/firmware/$arch/WIFI_FW/q6_fw* .

            case $board_name in
                ap-mi01.3)
                    #caldata_1.b0060 --> ahb 5GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0060 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0060 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi

                    #caldata_2.b00b0 --> ahb 6GHz
                    if [ -e /lib/firmware/qcn6432/caldata_2.b00b0 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_2.b00b0 cal-ahb-soc@0:wifi2@c0000000.bin
                    fi
                ;;
                ap-mi01.3-c3)
                    #caldata_1.b0070 --> ahb 5GHz/6GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0070 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0070 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi
                ;;
                ap-mi01.3-c5)
                    #caldata_1.b0062 --> ahb 5GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0062 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0062 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi

                    #caldata_2.b00b2 --> ahb 6GHz
                    if [ -e /lib/firmware/qcn6432/caldata_2.b00b2 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_2.b00b2 cal-ahb-soc@0:wifi2@c0000000.bin
                    fi
                ;;
                ap-mi04.1)
                    #caldata_1.b0052 --> ahb 5GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0052 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0052 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi

                    #caldata_2.b0091 --> ahb 6GHz
                    if [ -e /lib/firmware/qcn6432/caldata_2.b0091 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_2.b0091 cal-ahb-soc@0:wifi2@c0000000.bin
                    fi
                ;;
                ap-mi01.12)
                    if [ -e /lib/firmware/qcn6432/caldata_1.b00b0 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b00b0 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi
                ;;
                ap-mi01.14|ap-mi01.3-c2)
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0060 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0060 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi
                ;;
                ap-mi04.1-c2)
                    #caldata_1.b0053 --> ahb 5GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0053 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0053 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi
                ;;
                ap-mi04.3)
                    #caldata_1.b0054 --> ahb 5GHz
                    if [ -e /lib/firmware/qcn6432/caldata_1.b0054 ]; then
                        ln -sf /lib/firmware/qcn6432/caldata_1.b0054 cal-ahb-soc@0:wifi1@c0000000.bin
                    fi
                ;;
                ap-mi04.5)
                                        #caldata_2.b0052 --> ahb 5GHz
                                        if [ -e /lib/firmware/qcn6432/caldata_2.b0052 ]; then
                                                ln -sf /lib/firmware/qcn6432/caldata_2.b0052 cal-ahb-soc@0:wifi1@c0000000.bin
                                        fi
                                ;;
                *)
                    #No sym links
                ;;
            esac
        fi
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
                        ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/qdss_trace_config.bin .
                fi
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn9224/fw_ini_cfg.bin ]; then
                    ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/fw_ini_cfg.bin .
                fi
                if [ -e /lib/firmware/$arch/WIFI_FW/qcn9224/regdb.bin ]; then
                    ln -s /lib/firmware/$arch/WIFI_FW/qcn9224/regdb.bin .
                fi

            case $board_name in
                ap-al02-c4 |\
                ap-al05)
                    caldata_symlink_creation "$board_name" "1"
                    caldata_symlink_creation "$board_name" "2"
                    caldata_symlink_creation "$board_name" "3"
                ;;
                ap-al02-c6 |\
                ap-al06 |\
                ap-mi01.2 |\
                ap-mi01.2-c2)
                    caldata_symlink_creation "$board_name" "2"
                    caldata_symlink_creation "$board_name" "3"
                ;;
                ap-al02-c9 |\
                ap-mi01.9)
                    caldata_symlink_creation "$board_name" "1"
                    caldata_symlink_creation "$board_name" "2"

                ;;
                ap-mi01.6)
                    caldata_symlink_creation "$board_name" "2"
                ;;
                ap-mi01.12 |\
                ap-mi01.14)
                    caldata_symlink_creation "$board_name" "3"
                ;;
                ap-al02-c20)
                    caldata_symlink_creation "$board_name" "1"
                    caldata_symlink_creation "$board_name" "2"
                    caldata_symlink_creation "$board_name" "3"
                    caldata_symlink_creation "$board_name" "4"
                ;;
                *)
                    #No sym links
                ;;
            esac
            case $board_name in
                rdp466* | rdp485* | rdp496)
                    caldata_symlink_creation "$board_name" "2"
                    caldata_symlink_creation "$board_name" "3"
                ;;
                rdp487* )
                    caldata_symlink_creation "$board_name" "2"
                ;;
                rdp464*)
                    caldata_symlink_creation "$board_name" "2"
                    caldata_symlink_creation "$board_name" "3"
                    caldata_symlink_creation "$board_name" "4"
                ;;
                rdp498* | rdp500* | rdp501*)
                    caldata_symlink_creation "$board_name" "1"
                ;;
                *)
                    #No sm links
                ;;
            esac

        fi
        if [ -d /lib/firmware/$arch/WIFI_FW/qcn9625 ]; then
            if [  -e /lib/firmware/$arch/WIFI_FW/qcn9625/board-2.bin ]; then
                mkdir -p /lib/firmware/ath12k/QCN9625/hw1.0/
                cd /lib/firmware/ath12k/QCN9625/hw1.0/
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/m3.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/amss.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/mcss.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/aux.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/amss_dualmac.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/board-2.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/regdb.bin .
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9625/qdss_trace_config.bin .
            fi
            case $board_name in
                rdp492*|rdp488*|rdp489*)
                    caldata_symlink_creation_mr "$board_name" "1"
                    caldata_symlink_creation_mr "$board_name" "2"
                    caldata_symlink_creation_mr "$board_name" "3"
                ;;
                rdp499* | rdp502* | rdp505*)
                    caldata_symlink_creation_mr "$board_name" "1"
                ;;
                rdp503* | rdp504* | rdp506*)
                    caldata_symlink_creation_mr "$board_name" "1"
                    caldata_symlink_creation_mr "$board_name" "2"
                ;;
                rdp507* | rdp490* | rdp491*)
                    # qcn9625 is the 2nd ftm.conf entry for dual-radio Rimini RDPs
                    caldata_symlink_creation_mr "$board_name" "2"
                ;;
                *)
                    #No sm links
                ;;
            esac

        fi
    if [ -d /lib/firmware/$arch/WIFI_FW/qcn9589 ]; then
        if [ -e /lib/firmware/$arch/WIFI_FW/qcn9589/board-2.bin ]; then
            mkdir -p /lib/firmware/ath12k/QCN9589/hw1.0/
            cd /lib/firmware/ath12k/QCN9589/hw1.0/
            ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/m3.bin .
            ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/amss.bin .
            ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/board-2.bin .
            if [ -e /lib/firmware/$arch/WIFI_FW/qcn9589/regdb.bin ]; then
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/regdb.bin .
            fi
            ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/qdss_trace_config.bin .
            if [ -e /lib/firmware/$arch/WIFI_FW/qcn9589/aux.bin ]; then
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/aux.bin .
            fi
            if [ -e /lib/firmware/$arch/WIFI_FW/qcn9589/mcss.bin ]; then
                ln -s /lib/firmware/$arch/WIFI_FW/qcn9589/mcss.bin .
            fi

            case $board_name in
                rdp507* | rdp490* | rdp491*)
                    # qcn9589 is the 1st ftm.conf entry for dual-radio Rimini RDPs
                    caldata_symlink_creation_mr "$board_name" "1"
                ;;
                rdp511* | rdp512*)
                    # single-radio Rimini RDPs, qcn9589 only
                    caldata_symlink_creation_mr "$board_name" "1"
                ;;
                *)
                    #No sm links
                ;;
                        esac
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

        if grep -Eq "IPQ5424|IPQ5210|IPQ9650" /proc/device-tree/model; then
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk '{print $2}')
        else
                local platform=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $1}')
                local board=$(grep -ao "IPQ.*" /proc/device-tree/model | awk -F/ '{print $2}')
        fi

	if grep -Eq "ECHO" /proc/device-tree/model; then
		local platform="ECHO"
		local board=$(cat /proc/device-tree/model | sed -e 's/^.*Inc\. //' -e 's/ IDP / /' | tr ' ' '-')
		if [ -d /data/vendor ]; then
			mkdir -p /data/vendor/updates
			if [ -d /ini ]; then
				/sbin/mount-copybind /systemrw/misc /ini/
				ln -sf /ini/* /data/vendor/updates/
			else
				echo "ECHO: /ini not mounted, skipping symlinks" > /dev/console
			fi

			if [ -d /firmware/image ]; then
				ln -sf /firmware/image/* /data/vendor/updates/
			else
				echo "ECHO: /firmware/image not available, skipping symlinks" > /dev/console
			fi
			echo "/data/vendor/updates" > /sys/module/firmware_class/parameters/path
		else
			echo "ECHO: /data/vendor not present, skipping updates directory creation" > /dev/console
		fi
	else
		echo "ini" >  /sys/module/firmware_class/parameters/path
	fi

        if [ "$platform" == "IPQ9574" ]; then
                mount_wifi_fw "IPQ9574"
        elif [ "$platform" == "IPQ5332" ]; then
                mount_wifi_fw "IPQ5332"
        elif [ "$platform" == "IPQ8074" ]; then
                mount_wifi_fw "IPQ8074"
        elif [ "$platform" == "IPQ5424" ]; then
                mount_wifi_fw "IPQ5424"
	elif [ "$platform" == "IPQ5210" ]; then
		mount_wifi_fw "IPQ5210"
	elif [[ "$platform" == IPQ9650 ]]; then
		mount_wifi_fw "IPQ9650"
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

        if [[ "$arch" == "IPQ6018" ]] || [[ "$arch" == "IPQ5018" ]] || [[ "$arch" == "IPQ9574" ]] || [[ "$arch" == "IPQ5332" ]] || [[ "$arch" == "IPQ5424" ]] || [[ "$arch" == "IPQ5210" ]] || [[ "$arch" == "IPQ9650" ]]; then
                part_name="rootfs"
                wifi_on_rootfs="1"
        fi

	if [ "$arch" == "IPQ5424" ] || [ "$arch" == "IPQ5210" ] || [ "$arch" == "IPQ9650" ]; then
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
        if grep -Eq "IPQ5424|IPQ5210|IPQ9650" /proc/device-tree/model; then
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
	elif [ "$platform" == "IPQ5210" ]; then
		stop_wifi_fw "IPQ5210"
	elif [[ "$platform" == "IPQ9650" ]]; then
		stop_wifi_fw "IPQ9650"
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
	[ ! -e /tmp/sysinfo/board_name ] && {
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
