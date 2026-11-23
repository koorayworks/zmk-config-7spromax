#!/usr/bin/env bash
# Local build for 7sProMax + BLE Micro Pro (original, non-boost) x2, ZMK v0.3.
# Mirrors zmk-config-corne-v2-bmp/build-local.sh: reuses the verified
# corne-v2-bmp-v03 west workspace (same ZMK fork/revision this config's
# west.yml pins) and the v0.3 env.sh (venv + Zephyr SDK 0.16.3).
#
# Usage:
#   ./build-local.sh [all|left|right|reset]
#
# UF2 files are copied to the Windows side via ~/bin/copy-uf2.

set -u

TARGET="${1:-all}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ZMK_WORKSPACE:-$HOME/zmk-dev/corne-v2-bmp-v03}"
ZMK_DIR="${ZMK_DIR:-$WORKSPACE/zmk}"
ENV_SH="${ZMK_ENV_SH:-$HOME/zmk-dev/v0.3/env.sh}"
BUILD_ROOT="${BUILD_ROOT:-$WORKSPACE/build/7spromax}"
COPY_UF2="${COPY_UF2:-$HOME/bin/copy-uf2}"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -d "$ZMK_DIR/app" ]] || fail "ZMK app directory not found: $ZMK_DIR/app"
[[ -f "$ENV_SH" ]] || fail "Verified v0.3 env.sh not found: $ENV_SH"
[[ -f "$PROJECT_DIR/config/7spromax.conf" ]] || fail "Missing config/7spromax.conf"
[[ -f "$PROJECT_DIR/config/7spromax.keymap" ]] || fail "Missing config/7spromax.keymap"
[[ -d "$PROJECT_DIR/boards/arm/ble_micro_pro" ]] || fail "Missing ble_micro_pro board definition"
[[ -x "$COPY_UF2" ]] || fail "copy-uf2 not found/executable: $COPY_UF2"

# Reuse the verified Python/west + Zephyr SDK environment, but do not
# let an inherited ZEPHYR_BASE force west back into the old workspace.
# shellcheck disable=SC1090
source "$ENV_SH"
unset ZEPHYR_BASE || true

WEST="$(command -v west || true)"
[[ -n "$WEST" ]] || fail "west not found after sourcing $ENV_SH"

ACTUAL_TOPDIR="$(cd "$ZMK_DIR" && west topdir 2>/dev/null || true)"
[[ -n "$ACTUAL_TOPDIR" ]] || fail "west workspace not found from: $ZMK_DIR"
[[ "$ACTUAL_TOPDIR" == "$WORKSPACE" ]] || fail "Unexpected west topdir: $ACTUAL_TOPDIR (expected $WORKSPACE)"

mkdir -p "$BUILD_ROOT"

echo "============================================================"
echo " 7sProMax + BLE Micro Pro / ZMK v0.3 local build"
echo "============================================================"
echo "Workspace : $WORKSPACE"
echo "ZMK       : $ZMK_DIR"
echo "Project   : $PROJECT_DIR"
echo "Build     : $BUILD_ROOT"
echo

build_half() {
    local side="$1"
    local shield="$2"
    local out_name="$3"
    local build_dir="$BUILD_ROOT/$side"
    local uf2="$build_dir/zephyr/zmk.uf2"

    echo "------------------------------------------------------------"
    echo "Building $side: board=ble_micro_pro shield=$shield"
    echo "------------------------------------------------------------"

    (
        cd "$ACTUAL_TOPDIR"
        west build -p always -s "$ZMK_DIR/app" -d "$build_dir" -b ble_micro_pro -- \
            -DSHIELD="$shield" \
            -DZMK_CONFIG="$PROJECT_DIR/config" \
            -DBOARD_ROOT="$PROJECT_DIR"
    ) || fail "west build failed for $side"

    [[ -f "$uf2" ]] || fail "UF2 was not generated: $uf2"

    echo "Copying UF2 to Windows..."
    "$COPY_UF2" "$uf2" zmk-dev v0.3 7spromax "$out_name"
    echo "OK: $out_name"
    echo
}

case "$TARGET" in
    all)
        build_half reset settings_reset 7spromax-settings-reset.uf2
        build_half left  7spromax_left  7spromax-left.uf2
        build_half right 7spromax_right 7spromax-right.uf2
        ;;
    left)
        build_half left 7spromax_left 7spromax-left.uf2
        ;;
    right)
        build_half right 7spromax_right 7spromax-right.uf2
        ;;
    reset)
        build_half reset settings_reset 7spromax-settings-reset.uf2
        ;;
    *)
        fail "Usage: $0 [all|left|right|reset]"
        ;;
esac

echo "============================================================"
echo "Build complete"
echo "============================================================"
