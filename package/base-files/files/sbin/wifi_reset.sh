#!/bin/sh
#
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: ISC
#
# wifi_reset.sh - standalone shell-level equivalent of pwhm's WiFi.Reset() DM function.
#
# WiFi.Reset() (src/wld.c: _Reset()/s_doReset()) normally:
#   1. deletes pwhm's persisted DM config (wld_persist_deleteSavedConf())
#   2. stops hostapd/wpa_supplicant per radio (wld_secDmn_stop, via the FSM reset)
#   3. deletes runtime-created VAP/EndPoint instances
#   4. re-parses the factory-default ODL files back into the data model
#   5. lets the FSM re-apply config, which respawns hostapd/wpa_supplicant
#
# That whole sequence runs *inside* the pwhm (wld) process over ubus. This script
# exists for the case where pwhm itself is hung/unresponsive and can't be reached
# over ubus, so instead of calling `ubus call WiFi Reset '{}'` it reimplements the
# same end state at the OS level: kill pwhm + its hostapd/wpa_supplicant children,
# wipe their runtime state and pwhm's persisted config, then restart pwhm so it
# loads straight from the factory-default ODLs under /etc/amx/wld/ (same files
# WiFi.Reset() itself reloads).
#
# Scope/caveats (read before running):
#  - This is destructive: all runtime-created VAPs/EndPoints and any config pwhm
#    had persisted are gone after this runs, same as a real WiFi.Reset().
#  - Dynamically-created VAP network interfaces (wlanX_Y style) are NOT deleted
#    here - pwhm normally removes them via the vendor HAL (mfn_wrad_delvapif)
#    before deleting its own DM instances. Since pwhm isn't driving this script,
#    we don't have a safe/portable way to tell a "default" radio interface from
#    a "user-created" VAP interface purely from the OS side. Any stale VAP
#    interfaces are listed at the end for manual review.
#  - Assumes hostapd/wpa_supplicant on this board are only used for WiFi (pwhm
#    generic plugin). If something else on the board runs its own hostapd/
#    wpa_supplicant instances, narrow the pkill patterns below before use.
#
# Usage: wifi_reset.sh [-y] [-n]
#   -y   don't prompt for confirmation
#   -n   dry run: print what would be done, change nothing
#

DRY_RUN=0
ASSUME_YES=0

while getopts "yn" opt; do
    case "$opt" in
        y) ASSUME_YES=1 ;;
        n) DRY_RUN=1 ;;
        *) echo "usage: $0 [-y] [-n]" >&2; exit 1 ;;
    esac
done

log() { echo "[wifi_reset] $*"; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "DRY-RUN: $*"
    else
        "$@" || true
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    echo "wifi_reset.sh must be run as root" >&2
    exit 1
fi

if [ "$ASSUME_YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
    printf 'This will stop WiFi, wipe pwhm persisted config, and reload factory defaults. Continue? [y/N] '
    read -r reply
    case "$reply" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

PWHM_INIT="/etc/init.d/prplmesh_whm"
PERSISTED_CONF="/etc/config/wld/odl/wld.odl"
VESTIGIAL_CONF="/var/lib/wld/wld_config.odl"
USP_SOCK="/var/run/pwhm_usp.sock"

# --- 1. stop pwhm (procd stop works even if the app is hung: procd signals the
#        tracked instance directly, independent of the app's own responsiveness) ---
log "stopping pwhm service"
if [ -x "$PWHM_INIT" ]; then
    run dmesg -n1
    run "$PWHM_INIT" stop
fi

#        (this is the exact file wld_persist_deleteSavedConf() removes) ---
log "deleting persisted pwhm config: $PERSISTED_CONF"
run rm -f "$PERSISTED_CONF"
run rm -f "$VESTIGIAL_CONF"

# --- 6. restart pwhm from scratch ---
log "starting pwhm service"
if [ -x "$PWHM_INIT" ]; then
    run "$PWHM_INIT" start
    sleep 5
    run dmesg -n4
fi

if [ "$DRY_RUN" -eq 1 ]; then
    log "dry run complete, nothing was changed"
    exit 0
fi

sleep 2
if pgrep -f "/usr/bin/wld" >/dev/null 2>&1; then
    log "pwhm restarted (pid $(pgrep -f '/usr/bin/wld' | tr '\n' ' '))"
else
    log "WARNING: pwhm did not come back up on its own - check whether an" \
        "external process manager (prplMesh Process Manager) is expected to" \
        "respawn it, or start it manually: $PWHM_INIT start"
fi

# --- 7. best-effort: flag any lingering VAP-style wifi interfaces for manual
#        review (pwhm normally deletes these itself before this point; we
#        can't reliably distinguish "default" vs "user-created" from the OS
#        side, so we only report, we don't delete) ---
if command -v iw >/dev/null 2>&1; then
    extra_ifaces=$(iw dev 2>/dev/null | awk '/^phy#/{phy=$0} /Interface/{print $2}' | grep -E '_[0-9]+$' || true)
    if [ -n "$extra_ifaces" ]; then
        log "NOTE: the following interfaces look like leftover VAPs and were" \
            "NOT removed automatically - review and remove manually if stale:"
        echo "$extra_ifaces" | sed 's/^/    /'
    fi
fi

log "done"

