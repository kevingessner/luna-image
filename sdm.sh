#!/bin/bash -ex

DIR=$(dirname "$(realpath "$0")")
OUT_BASE=$DIR/luna-base.img
OUT_FINAL=${1-"$DIR/luna.img"}
RASPIOS_IMAGE_URL=https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2023-12-06/2023-12-05-raspios-bullseye-armhf-lite.img.xz
RASPIOS_IMAGE_FILE=$(basename "$RASPIOS_IMAGE_URL")

LUNA_USERNAME=luna
LUNA_UID=1001
LUNA_SDM_COPYDIR="copydir:from=$DIR/../luna|to=/home/$LUNA_USERNAME/|rsyncopts=--archive --cvs-exclude --info=progress2 --chown=$LUNA_UID:$LUNA_UID"



if ! [[ -f "$OUT_BASE" ]]
then
    if ! [[ -f "$RASPIOS_IMAGE_FILE" ]]
    then
        wget "$RASPIOS_IMAGE_URL"
    fi
    sha256sum --check "$RASPIOS_IMAGE_FILE".sha256
    xzcat "$RASPIOS_IMAGE_FILE" > "$OUT_BASE"

    sudo sdm \
        --customize "$OUT_BASE" \
        --chroot `# required on WSL` \
        --poptions noupdate,noupgrade,noautoremove \
        --extend --xmb 18000 \
        --plugin user:"adduser=$LUNA_USERNAME|uid=$LUNA_UID" \
        --plugin $DIR/authorized_keys.sh:"user=$LUNA_USERNAME|keyfile=$HOME/.ssh/rpi_luna_ssh_20230511.pub" \
        --plugin "$LUNA_SDM_COPYDIR"
fi

rsync --progress --update "$OUT_BASE" "$OUT_FINAL"

sudo sdm \
    --customize "$OUT_FINAL" \
    --redo-customize \
    --chroot `# required on WSL` \
    --poptions noupdate,noupgrade,noautoremove \
    --plugin apps:"apps=autoconf,imagemagick,python3-venv,fontconfig,fonts-liberation,fonts-urw-base35" \
    --plugin disables:"piwiz|triggerhappy" \
    --plugin L10n:"keymap=us|locale=en_US.UTF-8|timezone=UTC" \
    --plugin network:"wifissid=TP-Link_C930|wifipassword=09744165|wificountry=US" \
    --plugin hotspot:"domain=luna.local|type=local|ssid=luna-setup|passphrase=luna-setup|hwmode=g|channel=3" \
    `# update the luna files in the base image; should be quick if the PNGs are unchanged` \
    --plugin "$LUNA_SDM_COPYDIR" \
    --hostname mypi1 \
    --regen-ssh-host-keys
