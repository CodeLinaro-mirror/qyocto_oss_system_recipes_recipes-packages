#
# Copyright (c) 2020, The Linux Foundation. All rights reserved.
#
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: ISC
#

. /lib/functions/boot.sh
. /lib/upgrade/common.sh

RAMFS_COPY_DATA="/etc/fw_env.config /var/lock/fw_printenv.lock /tmp/firm_list.txt"
RAMFS_COPY_BIN="/usr/bin/dumpimage /usr/sbin/ubiattach /usr/sbin/ubidetach
	/usr/sbin/ubiformat /usr/sbin/ubiupdatevol /bin/rm /usr/bin/find
	/usr/sbin/mkfs.ext4 /usr/sbin/fw_printenv /sbin/lsmod"

# ── Constants ─────────────────────────────────────────────────────────────────
[ -z "${FOOTER_SIZE+x}" ] && readonly FOOTER_SIZE=104
[ -z "${MAGIC_ASCII+x}" ] && readonly MAGIC_ASCII="FMBL"
[ -z "${MAGIC_HEX+x}" ] && readonly MAGIC_HEX="464d424c"   # "FMBL" in lowercase hex
die() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo "$*"
}
# File size in bytes
file_size() {
    wc -c < "$1"
}

# Read 4 bytes at byte-offset $2 in file $1, return as decimal uint32 LE.
read_uint32_le() {
    local file=$1 offset=$2
    local hex
    hex=$(dd if="$file" bs=1 skip="$offset" count=4 2>/dev/null \
          | hexdump -v -e '1/1 "%02x"')
    echo $(( (0x${hex:0:2})
           + (0x${hex:2:2}) * 256
           + (0x${hex:4:2}) * 65536
           + (0x${hex:6:2}) * 16777216 ))
}

# SHA256 (hex) of an entire file.
sha256_file() {
    sha256sum "$1" | awk '{print $1}'
}


parse_footer() {
    local file=$1
    local fsize footer_offset
    fsize=$(file_size "$file")

    [[ $fsize -ge $FOOTER_SIZE ]] \
        || die "File too small for footer: $fsize bytes"

    footer_offset=$(( fsize - FOOTER_SIZE ))

    # ── Magic ────────────────────────────────────────────────────────────────
    local magic_hex
    magic_hex=$(dd if="$file" bs=1 skip="$footer_offset" count=4 2>/dev/null \
                | hexdump -v -e '1/1 "%02x"')
    [[ "$magic_hex" == "$MAGIC_HEX" ]] \
        || die "Bad magic: expected $MAGIC_HEX, got $magic_hex"

    # ── Blob size ────────────────────────────────────────────────────────────
    local blob_size
    blob_size=$(read_uint32_le "$file" $(( footer_offset + 4 )))

    local total_needed=$(( FOOTER_SIZE + blob_size ))
    [[ $fsize -ge $total_needed ]] \
        || die "File too small: need $total_needed bytes (blob=$blob_size + footer=$FOOTER_SIZE), have $fsize"

    # ── Stored SHA256 values (hex) ───────────────────────────────────────────
    local stored_img_sha256 stored_blob_sha256 stored_footer_sha256
    stored_img_sha256=$(dd if="$file" bs=1 skip=$(( footer_offset + 8  )) count=32 2>/dev/null \
                        | hexdump -v -e '1/1 "%02x"')
    stored_blob_sha256=$(dd if="$file" bs=1 skip=$(( footer_offset + 40 )) count=32 2>/dev/null \
                         | hexdump -v -e '1/1 "%02x"')
    stored_footer_sha256=$(dd if="$file" bs=1 skip=$(( footer_offset + 72 )) count=32 2>/dev/null \
                           | hexdump -v -e '1/1 "%02x"')

    # ── Verify footer SHA256 (integrity of the footer itself) ────────────────
    local computed_footer_sha256
    computed_footer_sha256=$(dd if="$file" bs=1 skip="$footer_offset" count=72 2>/dev/null \
                             | sha256sum | awk '{print $1}')
    [[ "$stored_footer_sha256" == "$computed_footer_sha256" ]] \
        || die "Footer SHA256 mismatch: stored=$stored_footer_sha256, computed=$computed_footer_sha256"

    # Print parsed fields for callers
    echo "blob_size=$blob_size"
    echo "stored_img_sha256=$stored_img_sha256"
    echo "stored_blob_sha256=$stored_blob_sha256"
    echo "stored_footer_sha256=$stored_footer_sha256"
    echo "footer_offset=$footer_offset"
    echo "blob_offset=$(( footer_offset - blob_size ))"
    echo "fit_size=$(( footer_offset - blob_size ))"
}

cmd_extract_blob() {
    local fit_image=$1 output_bin=$2
    [[ -f "$fit_image" ]] || { echo "ERROR: File not found: $fit_image" >&2; return 1; }

    local fields
    fields=$(parse_footer "$fit_image") || return 1

    local blob_size stored_blob_sha256 blob_offset fit_size
    eval "$fields"

    # Extract blob bytes
    dd if="$fit_image" bs=1 skip="$blob_offset" count="$blob_size" \
       of="$output_bin" 2>/dev/null

    # Verify extracted blob
    local actual_sha256
    actual_sha256=$(sha256_file "$output_bin")
    [[ "$actual_sha256" == "$stored_blob_sha256" ]] \
        || { echo "ERROR: Extracted blob SHA256 mismatch (stored=$stored_blob_sha256, computed=$actual_sha256)" >&2; return 1; }

    info "[OK] Blob extracted → $output_bin  ($blob_size bytes)"
    info "     Blob SHA256 : $actual_sha256  ✓"
}

image_contains() {
	local img=$1
	local sec=$2
	dumpimage -l ${img} | grep -q "^ Image.*(${sec}.*)" || return 1
}

image_has_mandatory_section() {
	local img=$1
	local mandatory_sections=$2

	for sec in ${mandatory_sections}; do
		image_contains $img ${sec} || {\
			return 1
		}
	done
}

parse_scr() {
	local input_file=$1
	local output_file=$2

	if [ -e $output_file ]; then
		echo " Output file exists removing it.... " > /dev/console
		rm $output_file
	fi

	while IFS= read -r line; do
		if echo "$line" | grep -q 'xtract_n_flash'; then
			value=$(echo "$line" | awk '{print $3}')
			label=$(echo "$line" | awk '{print $4}')

			echo "$value $label" >> "$output_file"
		fi
	done < "$input_file"
}

extract_scr_file() {
	local img=$1
	local file_name=$2
	local position=$3
	local version=$(dumpimage -V 2>&1 | awk '{split($3, a, "."); print a[1]}')

	if [ "$version" == "2016" ]; then
		dumpimage -i ${img} -o ${file_name} -T flat_dt -p $position ${file_name} >/dev/null
	else
		dumpimage -o ${file_name} -T flat_dt -p $position ${img} >/dev/null
	fi
}

extract_images() {
	local img=$1
	local output_file=$2
	local version=$(dumpimage -V 2>&1 | awk '{split($3, a, "."); print a[1]}')

	echo "Extracted Firmwares are ..."
	while IFS= read -r line; do
		image_name=$(echo $line | cut -d ' ' -f1)
		echo $image_name
		position=$(dumpimage -l ${img} |grep $image_name |cut -d ' ' -f3)
		if [ "$version" == "2016" ]; then
			dumpimage -i ${img} -o /tmp/${image_name}.bin -T flat_dt -p $position ${image_name} >/dev/null
		else
			dumpimage -o /tmp/${image_name}.bin -T flat_dt -p $position ${img} >/dev/null
		fi
	done < $output_file
}

image_demux() {
	local img=$1
	local machid=$(fw_printenv | grep machid | cut -d'=' -f2)
	local script_file="script_${machid}"
	local input_scr=/tmp/${script_file}.scr
	local output_list=/tmp/firm_list.txt
	local position=$(dumpimage -l ${img} |grep $script_file |cut -d ' ' -f3)

	extract_scr_file $img $input_scr $position
	parse_scr $input_scr $output_list
	extract_images $img $output_list

	return 0
}

image_is_FIT() {
	if ! dumpimage -l $1 > /dev/null 2>&1; then
		echo "$1 is not a valid FIT image"
		return 1
	fi
	return 0
}

do_flash_mtd() {
	local bin=$1
	local mtdname=$2
	local append=""
	local mtdname_rootfs="rootfs"
	local boot_layout=`find / -name boot_layout`
	local flash_type=`fw_printenv | grep flash_type=11`

	local mtdpart=$(grep "\"${mtdname}\"" /proc/mtd | awk -F: '{print $1}')
	if [ ! -n "$mtdpart" ]; then
		echo "$mtdname is not available" && return
	fi

	local pgsz=$(cat /sys/class/mtd/${mtdpart}/writesize)

	local mtdpart_rootfs=$(grep "\"${mtdname_rootfs}\"" /proc/mtd | awk -F: '{print $1}')

	[ -f "$UPGRADE_BACKUP" -a "$2" == "rootfs" ] && append="-j $UPGRADE_BACKUP"
	dd if=/tmp/${bin}.bin bs=${pgsz} conv=sync | mtd $append -e "/dev/${mtdpart}" write - "/dev/${mtdpart}"
}

do_flash_emmc() {
	local bin=$1
	local emmcblock=$2

	dd if=/dev/zero of=${emmcblock} &> /dev/null
	dd if=/tmp/${bin}.bin of=${emmcblock}
}

set_boot_part() {
	local output=$(find /sys/block/ -name '*boot*')
	echo "$output" | while read -r line; do
		echo $1 > ${line}/force_ro
	done
}

do_flash_partition() {
	local bin=$1
	local mtdname=$2
	local emmcblock="$(find_mmc_part "$mtdname")"

	if [ -e "$emmcblock" ]; then
		do_flash_emmc $bin $emmcblock
	else
		do_flash_mtd $bin $mtdname
	fi
}

# do_flash_failsafe_partition() - flashes the target partitions for upgrade.
do_flash_failsafe_partition() {
	local bin=$1
	local mtdname=$2
	local booted_bank=$(get_booted_bank)
	local target

	case "$booted_bank" in
		active)    target="${mtdname}_1" ;;
		inactive*) target="${mtdname}" ;;
	esac

	local emmcblock="$(find_mmc_part "$target")"

	if [ -e "$emmcblock" ]; then
		do_flash_emmc $bin $emmcblock
	else
		do_flash_mtd $bin $target
	fi
}

# do_flash_ubi() - flashes UBI image to the target partitions.
do_flash_ubi() {
	local bin=$1
	local mtdname=$2
	local alive=$(cat /tmp/.alive_upgrade)
	local mtdpart
	local booted_bank=$(get_booted_bank)
	local target

	case "$booted_bank" in
		active)    target="${mtdname}_1" ;;
		inactive*) target="${mtdname}" ;;
	esac

	if [ $alive -eq 0 ]; then
		# Detach the currently RUNNING rootfs UBI device.
		local running_part
		case "$booted_bank" in
			active)    running_part="${mtdname}" ;;
			inactive*) running_part="${mtdname}_1" ;;
		esac
		local running_mtdpart=$(grep "\"${running_part}\"" /proc/mtd | awk -F: '{print $1}')
		ubidetach -p /dev/${running_mtdpart}
	fi

	mtdpart=$(grep "\"${target}\"" /proc/mtd | awk -F: '{print $1}')
	if [ ! -n "$mtdpart" ]; then
		echo "$target is not available" && return 1
	fi
	ubiformat /dev/${mtdpart} -y -f /tmp/${bin}.bin
}

# do_flash_failsafe_ubi_volume() - flashes UBI volume to the target partitions.
do_flash_failsafe_ubi_volume() {
	local bin=$1
	local mtdname=$2
	local vol_name=$3
	local tmpfile="${bin}.bin"
	local mtdpart
	local booted_bank=$(get_booted_bank)
	local target

	case "$booted_bank" in
		active)    target="${mtdname}_1" ;;
		inactive*) target="${mtdname}" ;;
	esac

	mtdpart=$(grep "\"${target}\"" /proc/mtd | awk -F: '{print $1}')

	if [ ! -n "$mtdpart" ]; then
		echo "$target is not available" && return
	fi

	ubiattach -p /dev/${mtdpart}

	volumes=$(ls /sys/class/ubi/*/ | grep ubi._.*)

	for vol in ${volumes}
	do
		[ -f /sys/class/ubi/${vol}/name ] && name=$(cat /sys/class/ubi/${vol}/name)
			[ ${name} == ${vol_name} ] && m_vol=${vol}
	done
	sync
	sleep 3
	sync
	ubiupdatevol /dev/${m_vol} /tmp/${tmpfile}
	sync
}

to_lower ()
{
	echo $1 | awk '{print tolower($0)}'
}

to_upper ()
{
	echo $1 | awk '{print toupper($0)}'
}

# get_cmdline_partlabel() - returns current booted partition data.
get_cmdline_partlabel() {
	cat /proc/cmdline 2>/dev/null | grep -o 'PARTLABEL=[^ ]*' | cut -d= -f2
}

# get_booted_bank() - return the current booted bank information
get_booted_bank() {
	local partlabel=$(get_cmdline_partlabel)
	case "$partlabel" in
		rootfs-inactive) echo "inactive" ;;
		*)               echo "active" ;;
	esac
}

# do_post_upgrade() - negates bootfrom ENV based on current boot.
do_post_upgrade() {
	local partlabel=$(get_cmdline_partlabel)
	case "$partlabel" in
		rootfs-active)   fw_setenv bootfrom 1 2>/dev/null ;;
		rootfs-inactive) fw_setenv bootfrom 0 2>/dev/null ;;
	esac
}

flash_section() {
	local img=$1
	local output_list=/tmp/firm_list.txt

	while IFS= read -r line; do
		image_name=$(echo $line | cut -d ' ' -f1)
		partition=$(echo $line | cut -d ' ' -f2)
		case "${image_name}" in
			mibib*)      echo " Section $image_name is ignored "; continue ;;
			bootconfig*) echo " Section $image_name is ignored "; continue ;;
			gpt*)        echo " Section $image_name is ignored "; continue ;;
			norgpt*)     echo " Section $image_name is ignored "; continue ;;
			gptbackup*)  echo " Section $image_name is ignored "; continue ;;
			norgptbackup*) echo " Section $image_name is ignored "; continue ;;
			script*)     echo " Section $image_name is ignored "; continue ;;
			wifi_fw*|wififw*)     do_flash_failsafe_partition ${image_name} "0:WIFIFW"; do_flash_failsafe_ubi_volume ${image_name} "rootfs" "wifi_fw" ;;
			ubi*)        do_flash_ubi ${image_name} $partition ;;
			*)           do_flash_failsafe_partition ${image_name} $partition ;;
		esac
		echo "Flashed ${image_name}"
	done < $output_list
	return 0
}

erase_emmc_config() {
	local mtdpart=$(cat /proc/mtd | grep rootfs)
	local emmcblock="$(find_mmc_part "rootfs_data")"
	if [ -z "$mtdpart" -a -e "$emmcblock" ]; then
		yes | mkfs.ext4 "$emmcblock"
	fi
}

platform_check_image() {
	local board=$(cat /tmp/sysinfo/board_name)
	local board_model=$(to_lower $(grep -o "IPQ.*" /tmp/sysinfo/model | awk -F/ '{print $3}'))
	local mandatory_nand="ubi"
	local mandatory_nor_emmc="hlos fs"
	local mandatory_nor="hlos"
	local mandatory_section_found=0
	local ddr_section="ddr"
	local optional="sb11 sbl2 u-boot lkboot ddr-${board_model} tz rpm"
	local ignored="mibib bootconfig script gpt gptbackup"

	image_is_FIT $1 || return 1

	image_has_mandatory_section $1 ${mandatory_nand} && {\
		mandatory_section_found=1
	}

	image_has_mandatory_section $1 ${mandatory_nor_emmc} && {\
		mandatory_section_found=1
	}

	image_has_mandatory_section $1 ${mandatory_nor} && {\
		mandatory_section_found=1
	}

	if [ $mandatory_section_found -eq 0 ]; then
		echo "Error: mandatory section(s) missing from \"$1\". Abort..."
		return 1
	fi

	image_has_mandatory_section $1 $ddr_section && {\
		image_contains $1 ddr-$board_model || {\
			image_contains $1 ddr-$(to_upper $board_model) || {\
			return 1
			}
		}
	}
	for sec in ${optional}; do
		image_contains $1 ${sec} || {\
			echo "Warning: optional section \"${sec}\" missing from \"$1\". Continue..."
		}
	done

	for sec in ${ignored}; do
		image_contains $1 ${sec} && {\
			echo "Warning: section \"${sec}\" will be ignored from \"$1\". Continue..."
		}
	done

	echo 1711 > /proc/sys/vm/min_free_kbytes
	echo 3 > /proc/sys/vm/drop_caches

	if [ -e /sys/sec_upgrade/sec_auth ]; then
		cmd_extract_blob $1 /tmp/metadata_output.bin || return 1
		echo -n 0xCD /tmp/metadata_output.bin > /sys/sec_upgrade/sec_auth || return 1
	fi
	image_demux $1 || {\
		echo "Error: \"$1\" couldn't be extracted. Abort..."
		return 1
	}

	[ -f /tmp/hlos_version ] && rm -f /tmp/*_version
	# dumpimage -c $1
	# if [[ "$?" == 0 ]];then
	# 	return $?
	# else
	# 	echo "Rebooting the system"
	# 	reboot
	#	return 1
	# fi
	return 0
}

do_upgrade() {
	v "Performing system upgrade..."
	if type 'platform_do_upgrade' >/dev/null 2>/dev/null; then
		platform_do_upgrade "$ARGV"
	else
		default_do_upgrade "$ARGV"
	fi

	if [ "$SAVE_CONFIG" -eq 1 ] && type 'platform_copy_config' >/dev/null 2>/dev/null; then
		platform_copy_config
	fi

	v "Upgrade completed"
}

platform_do_upgrade() {
	local upgrade_set=true
	local board=$(cat /tmp/sysinfo/board_name)
	local alive=$(cat /tmp/.alive_upgrade)
	local output_list=/tmp/firm_list.txt
	local booted_bank=$(get_booted_bank)

	# Block upgrade if force-inactive boot (detected from DT)
	local dt_bank
	if [ -f /proc/device-tree/chosen/u-boot,booted-bank ]; then
		dt_bank=$(awk 'BEGIN{RS="\0"}{print; exit}' /proc/device-tree/chosen/u-boot,booted-bank)
		if [ "$dt_bank" = "inactive,forced" ]; then
			echo " Force booted in inactive bank, Upgrade not supported" > /dev/console
			return 1
		fi
	fi

	# verify some things exist before erasing
	if [ ! -e $1 ]; then
		echo "Error: Can't find $1 after switching to ramfs, aborting upgrade!"
		reboot
	fi

	while IFS= read -r line; do
		image_name=$(echo $line | cut -d ' ' -f1)
		if [ ! -e /tmp/${image_name}.bin ]; then
			echo "Error: Can't find ${image_name} after switching to ramfs, aborting upgrade!"
			if [ $alive -eq 0 ]; then
				reboot
			fi
		fi
	done < $output_list

	case "$upgrade_set" in
	true)
		#setting boot mmc device to write enabled
		set_boot_part 0

		if ! flash_section "$1"; then
			echo " Failed to flash firmwares "
			return 1
		fi

		#setting back boot mmc devices to read only
		set_boot_part 1

		if [ $alive -eq 0 ]; then
			do_post_upgrade
			if [ -f /sys/class/registers/bootcount ]; then
				echo 0 > /sys/class/registers/bootcount
			fi
		fi

		erase_emmc_config
		return 0;
		;;
	esac

	echo "Upgrade failed!"
	return 1;
}

# set_force_inactive() - sets force_inactive to trigger a one-shot boot from the inactive bank.
set_force_inactive() {
	if [ -f /sys/class/registers/force_inactive ]; then
		echo 1 > /sys/class/registers/force_inactive
		echo " force_inactive triggered..."
	else
		echo " force_inactive sysfs not available"
		return 1
	fi
	return 0
}

# activate_bank() - activates the specified bank for alive/OMCI upgrade.
# activate_bank <bank>   bank = 0 (active) or 1 (inactive)
# activate_bank          boots opposite bank as per current bank
activate_bank() {
	if [ -n "$1" ]; then
		case "$1" in
			0|1) ;;
			*) echo "ERROR: Invalid bank to activate: '$1'" >&2; return 1 ;;
		esac
		if ! fw_setenv bootfrom "$1" 2>/dev/null; then
			echo "ERROR: Activate bank $1 failed" >&2
			return 1
		fi
		case "$1" in
			0) echo "Active Bank is Activated" ;;
			1) echo "Inactive Bank is Activated" ;;
		esac
	else
		local partlabel=$(get_cmdline_partlabel)
		case "$partlabel" in
			rootfs-active)
				fw_setenv bootfrom 1 2>/dev/null
				echo "Inactive Bank is Activated"
				;;
			rootfs-inactive)
				fw_setenv bootfrom 0 2>/dev/null
				echo "Active Bank is Activated"
				;;
			*)
				echo "ERROR: Invalid bank to activate" >&2
				return 1
				;;
		esac
	fi
	if [ -f /sys/class/registers/bootcount ]; then
		echo 0 > /sys/class/registers/bootcount
	fi
	return 0
}

# commit_bank() - commits the specified bank for alive/OMCI upgrade.
# commit_bank <bank>   bank = 0 (active) or 1 (inactive)
# commit_bank          sets bootfrom to commit the running bank.
commit_bank() {
	if [ -n "$1" ]; then
		case "$1" in
			0|1) ;;
			*) echo "ERROR: Invalid bank to commit: '$1'" >&2; return 1 ;;
		esac
		if ! fw_setenv bootfrom "$1" 2>/dev/null; then
			echo "ERROR: Commit bank $1 failed" >&2
			return 1
		fi
		case "$1" in
			0) echo "Active Bank is Committed" ;;
			1) echo "Inactive Bank is Committed" ;;
		esac
		return 0
	else
		local partlabel=$(get_cmdline_partlabel)
		case "$partlabel" in
			rootfs-active)
				fw_setenv bootfrom 0 2>/dev/null
				echo "Active Bank is Committed"
				;;
			rootfs-inactive)
				fw_setenv bootfrom 1 2>/dev/null
				echo "Inactive Bank is Committed"
				;;
			*)
				echo "ERROR: Invalid bank to commit" >&2
				return 1
				;;
		esac
		return 0
	fi
}

get_magic_long_at() {
        dd if="$1" skip=$(( 65536 / 4 * $2 )) bs=4 count=1 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

# find rootfs_data start magic
platform_get_offset() {
        offsetcount=0
        magiclong="x"

        while magiclong=$( get_magic_long_at "$1" "$offsetcount" ) && [ -n "$magiclong" ]; do
                case "$magiclong" in
                        "deadc0de"|"19852003")
                                echo $(( $offsetcount * 65536 ))
                                return
                        ;;
                esac
                offsetcount=$(( $offsetcount + 1 ))
        done
	echo $(( $offsetcount * 65536 ))
}

find_last_mtd_part() {
        local PART="$(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}' | tail -1)"
        local PREFIX=/dev/mtdblock

        PART="${PART##mtd}"
        [ -d /dev/mtdblock ] && PREFIX=/dev/mtdblock/
        echo "${PART:+$PREFIX$PART}"
}

platform_copy_config() {
	local nand_part="$(find_last_mtd_part "ubi_rootfs")"
	local emmcblock="$(find_mmc_part "rootfs")"
	local alive=$(cat /tmp/.alive_upgrade)
	local booted_bank=$(get_booted_bank)
	local upgradepart
	mkdir -p /tmp/overlay

	# Determine upgrade partition based on booted bank
	case "$booted_bank" in
		active)    upgradepart="rootfs_1" ;;
		inactive*) upgradepart="rootfs" ;;
	esac

	if [ -e "${nand_part%% *}" ]; then
		local mtdpart
		mtdpart=$(grep "\"${upgradepart}\"" /proc/mtd | awk -F: '{print $1}')
		ubiattach -p /dev/${mtdpart}
		volumes=$(ls /sys/class/ubi/*/ | grep ubi._.*)
		for vol in ${volumes}
		do
			[ -f /sys/class/ubi/${vol}/name ] && name=$(cat /sys/class/ubi/${vol}/name)
			if [[ ${vol} == *"/sys/class/"* ]]; then
				continue
			else
				[ ${name} == "rootfs_data" ] && m_vol=$(echo ${vol} | sed 's/_[^_]*//')
			fi
		done
		mount -t ubifs $m_vol:rootfs_data /tmp/overlay
	elif [ -e "$emmcblock" ]; then
		local loopdev="$(losetup -f)"
		emmcblock="$(find_mmc_part ${upgradepart})"
		data_blockoffset="$(get_squashfs_size ${emmcblock})"
		losetup -o $data_blockoffset $loopdev $emmcblock || {
			echo "Failed to mount looped rootfs_data."
			reboot
		}
		echo y | mkfs.ext4 -F -L rootfs_data $loopdev
		sync
		mount -t ext4 "$loopdev" /tmp/overlay
	fi

	cp /tmp/sysupgrade.tgz /tmp/overlay/
	sync
	umount /tmp/overlay
}
