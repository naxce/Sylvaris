#!/usr/bin/env bash
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
seeds="$here/../fixtures/seed"
failed=0

for steps in "$here"/*.steps; do
    name="$(basename "$steps" .steps)"
    case "$name" in
    theme-empty) seed="" ;;
    theme*) seed="$seeds/tp" ;;
    broken | notice) seed="$seeds/broken" ;;
    blackout) seed="$seeds/blackout" ;;
    *) seed="$seeds/warm" ;;
    esac
    extra=()
    if [ "$name" = niri-toggles ]; then
        extra=(env HL_NIRI_SOCKET=/nonexistent PATH="$here/fake-niri:$PATH")
    fi
    if ! "${extra[@]}" "$here/run.sh" "$here/out/$name" "$steps" ${seed:+"$seed"} >/dev/null 2>&1; then
        echo "FAIL $name (run.sh)"
        failed=1
    elif grep -qE "TypeError|ReferenceError|is not a function|Cannot read property" "$here/out/$name/qs.log"; then
        echo "FAIL $name (script error)"
        grep -E "TypeError|ReferenceError|is not a function|Cannot read property" "$here/out/$name/qs.log" | head -3
        failed=1
    else
        echo "ok   $name"
    fi
done
exit "$failed"
