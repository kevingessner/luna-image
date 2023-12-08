#!/bin/bash
#
# This is an sdm plugin for: authorized_keys
#
# The plugin is called three times: for Phase 0, Phase 1, and post-install.
#

function loadparams() {
    source $SDMPT/etc/sdm/sdm-readparams
}

# $1 is the phase: "0", "1", or "post-install"
# $2 is the argument list: arg1=val1|arg2=val2|arg3=val3| ...
#
# Main code for the Plugin
#
phase=$1
pfx="$(basename $0)"     #For messages
args="$2"
loadparams
vldargs="|user|keyfile|"
rqdargs="|user|keyfile|"                   # |list|of|required|args|or|nullstring|
assetdir="$SDMPT/etc/sdm/assets/$pfx"

if [ "$phase" == "0" ]
then
    #
    # In Phase 0 all references to directories in the image must be preceded by $SDMPT
    #
    logtoboth "* Plugin $pfx: Start Phase 0"
    plugin_getargs $pfx "$args" "$vldargs" "$rqdargs" || exit
    #
    # Print the keys found (example usage). plugin_getargs returns the list of found keys in $foundkeys
    #
    plugin_printkeys
    mkdir -p $assetdir
    base=$(basename "$keyfile")
    logtoboth "* Plugin $pfx: keyfile '$keyfile' ($base) for user '$user'"
    cp "$keyfile" "$assetdir/$base"
    logtoboth "* Plugin $pfx: Complete Phase 0"

elif [ "$phase" == "1" ]
then
    #
    # Phase 1 (in nspawn)
    #
    logtoboth "* Plugin $pfx: Start Phase 1"
    plugin_getargs $pfx "$args" "$vldargs" "$rqdargs"

    homedir=$( getent passwd "$user" | cut -d: -f6 )
    base=$(basename "$keyfile")
    mkdir -p "$homedir/.ssh"
    cat "$assetdir/$base" >> "$homedir/.ssh/authorized_keys"
    chown -R "$user:$user" "$homedir/.ssh"
    chmod 0700 "$homedir/.ssh"
    chmod 0600 "$homedir/.ssh/authorized_keys"

    logtoboth "* Plugin $pfx: Complete Phase 1"
else
    #
    # Plugin Post-install edits
    #
    #logtoboth "* Plugin $pfx: Start Phase post-install"
    #plugin_getargs $pfx "$args" "$vldargs" "$rqdargs"
    #logfreespace "at start of Plugin $pfx Phase post-install"
    #
    # INSERT Your Plugin's post-install code here
    # In Phase post-install all references to directories in the image can be direct
    #
    #logfreespace "at end of $pfx Custom Phase post-install"
    #logtoboth "* Plugin $pfx: Complete Phase post-install"
    :
fi
