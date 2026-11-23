#!/usr/bin/env bash
# VM-local build check for 7sProMax + BLE Micro Pro (original) x2, ZMK v0.3.
# Self-contained counterpart of build-local.sh (which targets the ZBook
# workspace): uses the VM west workspace + venv + Zephyr SDK.
#
# One-time setup (already done on this VM, kept here for reference):
#   python3 -m venv ~/zmk-dev-vm/venv
#   ~/zmk-dev-vm/venv/bin/pip install west
#   cd ~ && ~/zmk-dev-vm/venv/bin/west init -m <this repo path> ~/zmk-dev-vm/ws
#   cd ~/zmk-dev-vm/ws && ~/zmk-dev-vm/venv/bin/west update
#   ~/zmk-dev-vm/venv/bin/pip install -r ~/zmk-dev-vm/ws/zephyr/scripts/requirements.txt
#
# Usage: ./build-vm.sh [all|left|right|reset]
# UF2s land in ./build-vm-out/.

set -u

TARGET="${1:-all}"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${ZMK_WORKSPACE:-$HOME/zmk-dev-vm/ws}"
ZMK_DIR="$WORKSPACE/zmk"
BUILD_ROOT="$PROJECT_DIR/build-vm"
OUT_DIR="$PROJECT_DIR/build-vm-out"

export PATH="$HOME/zmk-dev-vm/venv/bin:$PATH"
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK_INSTALL_DIR:-$HOME/zephyr-sdk-0.17.0}"
unset ZEPHYR_BASE || true

fail() { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$ZMK_DIR/app" ]] || fail "ZMK app not found: $ZMK_DIR/app"
[[ -d "$ZMK_DIR/app/snippets/studio-rpc-usb-uart" ]] || fail "Studio snippet missing in this ZMK tree"
command -v west >/dev/null || fail "west not found in venv"

mkdir -p "$BUILD_ROOT" "$OUT_DIR"

build_one() {
    local name="$1" shield="$2" studio="$3" out_name="$4"
    local build_dir="$BUILD_ROOT/$name"
    local -a args=(build -p always -s "$ZMK_DIR/app" -d "$build_dir" -b ble_micro_pro)
    if [[ "$studio" == "yes" ]]; then
        args+=(-S studio-rpc-usb-uart)
    fi
    args+=(-- -DSHIELD="$shield" -DZMK_CONFIG="$PROJECT_DIR/config" -DBOARD_ROOT="$PROJECT_DIR")
    if [[ "$studio" == "yes" ]]; then
        args+=(
            -DCONFIG_ZMK_STUDIO=y
            -DCONFIG_ZMK_CUSTOM_SETTINGS_STUDIO_RPC=y
            -DCONFIG_ZMK_STUDIO_RPC_RX_BUF_SIZE=128
            -DCONFIG_ZMK_STUDIO_RPC_CUSTOM_SUBSYSTEM_REQUEST_PAYLOAD_MAX_BYTES=96
        )
    fi
    echo "------------------------------------------------------------"
    echo "Building $name: shield=$shield studio=$studio"
    echo "------------------------------------------------------------"
    ( cd "$WORKSPACE" && west "${args[@]}" ) || fail "west build failed for $name"
    [[ -f "$build_dir/zephyr/zmk.uf2" ]] || fail "UF2 not generated for $name"
    cp "$build_dir/zephyr/zmk.uf2" "$OUT_DIR/$out_name"
    echo "OK: $OUT_DIR/$out_name"
}

case "$TARGET" in
    all)
        build_one reset settings_reset  no  7spromax-settings-reset.uf2
        build_one left  7spromax_left   yes 7spromax-left.uf2
        build_one right 7spromax_right  no  7spromax-right.uf2
        ;;
    left)  build_one left  7spromax_left   yes 7spromax-left.uf2 ;;
    right) build_one right 7spromax_right  no  7spromax-right.uf2 ;;
    reset) build_one reset settings_reset  no  7spromax-settings-reset.uf2 ;;
    *) fail "Usage: $0 [all|left|right|reset]" ;;
esac

echo "Build complete"
