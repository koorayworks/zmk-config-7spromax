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
# Usage: ./build-vm.sh [all|left|right|reset|sm|sm-left|sm-right]
#   all/left/right/reset : original BLE Micro Pro (board ble_micro_pro)
#   sm/sm-left/sm-right  : SuperMini nRF52840 (board nice_nano; the
#                          SuperMini connector map matches nice!nano
#                          except D0/D1, unused by the matrix; LED
#                          data pin and NFC-as-GPIO are handled by
#                          config/nice_nano.overlay / .conf)
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
    local name="$1" board="$2" shield="$3" studio="$4" out_name="$5"
    local build_dir="$BUILD_ROOT/$name"
    local -a args=(build -p always -s "$ZMK_DIR/app" -d "$build_dir" -b "$board")
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
    echo "Building $name: board=$board shield=$shield studio=$studio"
    echo "------------------------------------------------------------"
    ( cd "$WORKSPACE" && west "${args[@]}" ) || fail "west build failed for $name"
    [[ -f "$build_dir/zephyr/zmk.uf2" ]] || fail "UF2 not generated for $name"
    cp "$build_dir/zephyr/zmk.uf2" "$OUT_DIR/$out_name"
    echo "OK: $OUT_DIR/$out_name"
}

case "$TARGET" in
    all)
        build_one reset ble_micro_pro settings_reset  no  7spromax-settings-reset.uf2
        build_one left  ble_micro_pro 7spromax_left   yes 7spromax-left.uf2
        build_one right ble_micro_pro 7spromax_right  no  7spromax-right.uf2
        ;;
    left)  build_one left  ble_micro_pro 7spromax_left   yes 7spromax-left.uf2 ;;
    right) build_one right ble_micro_pro 7spromax_right  no  7spromax-right.uf2 ;;
    reset) build_one reset ble_micro_pro settings_reset  no  7spromax-settings-reset.uf2 ;;
    sm)
        build_one sm-left  nice_nano 7spromax_left   yes 7spromax-sm-left.uf2
        build_one sm-right nice_nano 7spromax_right  no  7spromax-sm-right.uf2
        ;;
    sm-left)  build_one sm-left  nice_nano 7spromax_left   yes 7spromax-sm-left.uf2 ;;
    sm-right) build_one sm-right nice_nano 7spromax_right  no  7spromax-sm-right.uf2 ;;
    *) fail "Usage: $0 [all|left|right|reset|sm|sm-left|sm-right]" ;;
esac

echo "Build complete"
