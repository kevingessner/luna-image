#!/bin/bash -ex

DIR=$(dirname "$(realpath "$0")")
OUT_BASE=$DIR/luna-base.img
OUT_FINAL=${1-"$DIR/luna.img"}
RASPIOS_IMAGE_URL=https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2023-12-06/2023-12-05-raspios-bullseye-armhf-lite.img.xz
RASPIOS_IMAGE_FILE=$(basename "$RASPIOS_IMAGE_URL")

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
        \ # required on WSL \
        --chroot \
        --poptions noupdate,noupgrade,noautoremove \
        --extend --xmb 18000 \
        --plugin user:"adduser=luna" \
        --plugin $DIR/authorized_keys.sh:"user=luna|keyfile=$HOME/.ssh/rpi_luna_ssh_20230511.pub" \
        --plugin copydir:"from=$DIR/../luna|to=/home/luna/|rsyncopts=--archive --cvs-exclude --info=progress2"
fi

cp "$OUT_BASE" "$OUT_FINAL"

sudo sdm \
    --customize "$OUT_FINAL" \
    --redo-customize \
    \ # required on WSL \
    --chroot \
    --poptions noupdate,noupgrade,noautoremove \
    --plugin apps:"apps=autoconf,imagemagick" \
    --plugin disables:"piwiz|triggerhappy" \
    --plugin L10n:"keymap=us|locale=en_US.UTF-8|timezone=UTC" \
    --plugin network:"wifissid=TP-Link_C930|wifipassword=09744165|wificountry=US" \
    --hostname mypi1 \
    --regen-ssh-host-keys
