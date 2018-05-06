#!/bin/bash


# Usage:

#  $ ./crypt.sh --file="~/crypto/vault-encrypted" --size="512" --mapping="vault-device" --caption="vault-volume" --location="~/crypto/vault-decrypted" --create
#  $ ./crypt.sh -f="~/crypto/vault-encrypted" -s="512" -m="vault-device" -c="vault-volume" -l="~/vault-decrypted" --create

#  $ ./crypt.sh --file="~/crypto/vault-encrypted" --mapping="vault-device" --location="~/crypto/vault-decrypted" --mount
#  $ ./crypt.sh -f="~/crypto/vault-encrypted" -m="vault-device" -l="~/crypto/vault-decrypted" --mount

#  $ ./crypt.sh --location="~/crypto/vault-decrypted" --mapping="vault-device" --unmount
#  $ ./crypt.sh -l="~/crypto/vault-decrypted" -m="vault-device" --unmount


#set -x  # echo on

function create_empty_file {
	file_path="$1"
	dir_path=$(dirname "${file_path}")
	sudo mkdir --parents "$dir_path"
	sudo chown ${USER:=$(/usr/bin/id -run)}:$USER "$dir_path"
	
	fallocate -l "$2M" "$file_path"
	#dd if=/dev/zero of="$1" bs=1M count="$2"
	#dd if=/dev/urandom of="$1" bs=1M count="$2"
	#dd if=/dev/random of="$1" bs=1M count="$2"
}

function create_dm_crypt_luks_container {
	cryptsetup --verbose --verify-passphrase --batch-mode luksFormat "$1"
	#cryptsetup --verbose luksDump "$1"
	#file "$1"
}

function open_container {
	sudo cryptsetup --verbose luksOpen "$1" "$2"
	#ls /dev/mapper
}

function format_and_create_filesystem {
	sudo mkfs.ext4 -j "/dev/mapper/$1"
}

function set_label {
	sudo e2label "/dev/mapper/$1" "$2"
}

function mount_container {	
	sudo mkdir --parents "$2"
	sudo mount "/dev/mapper/$1" "$2"
	sudo chown ${USER:=$(/usr/bin/id -run)}:$USER "$2"

	#df -h
	#cd "$2"
	#ls
}

function unmount_container {
	sudo umount "$1"
	
	sudo rmdir "$1"
	#sudo rm --recursive "$1"
	
	#df -h
}

function close_container {
	sudo cryptsetup --verbose luksClose "$1"
	#ls /dev/mapper
}

for i in "$@"; do
	case $i in
		-f=*|--file=*)
			file_container="${i#*=}"
			eval file_container=$file_container
			shift # past argument=value
			;;
		-s=*|--size=*)
			file_size="${i#*=}"
			shift # past argument=value
			;;
		-m=*|--mapping=*)
			mapping_name="${i#*=}"
			shift # past argument=value
			;;
		-c=*|--caption=*)
			label="${i#*=}"
			shift # past argument=value
			;;
		-l=*|--location=*)
			mount_location="${i#*=}"
			eval mount_location=$mount_location
			shift # past argument=value
			;;
		--create)
			create_empty_file "$file_container" "$file_size"
			create_dm_crypt_luks_container "$file_container"
			open_container "$file_container" "$mapping_name"
			format_and_create_filesystem "$mapping_name"
			set_label "$mapping_name" "$label"
			close_container "$mapping_name"
			shift # past argument with no value
			;;
		--mount)
			open_container "$file_container" "$mapping_name"
			mount_container "$mapping_name" "$mount_location"
			shift # past argument with no value
			;;
		--unmount)
			unmount_container "$mount_location"
			close_container "$mapping_name"
			shift # past argument with no value
			;;
		*)
			# unknown option
			;;
	esac
done

