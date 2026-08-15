#!/bin/sh
# Waybar custom/hardware module: CPU, memory, and discrete-GPU usage/temp in
# one combined block. Needs dot_config/waybar/style.css's font-family
# switched to "JetBrainsMono Nerd Font" (verified installed and covers these
# codepoints via fc-scan) or these show as tofu boxes instead of icons.
set -eu

cpu_icon=''   # nf-fa-microchip U+F2DB
mem_icon=''   # nf-fa-memory U+EFC5
gpu_icon='󰢮'  # nf-md-expansion_card U+F08AE (no dedicated GPU glyph exists)
temp_icon=''  # nf-fa-thermometer_half U+F2C9, reused for CPU and GPU

# --- CPU usage: delta against the previous run's /proc/stat snapshot,
# same technique waybar's own (now-removed) cpu module used internally ---
stat_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-hwstatus-cpu"
read -r _ u n s i iw irq sirq st _ < /proc/stat
idle=$((i + iw))
total=$((u + n + s + idle + irq + sirq + st))
cpu_usage=0
if [ -f "$stat_file" ]; then
    prev_idle=0
    prev_total=0
    read -r prev_idle prev_total < "$stat_file" || true
    dt=$((total - prev_total))
    if [ "$dt" -gt 0 ]; then
        cpu_usage=$(( (100 * (dt - (idle - prev_idle))) / dt ))
    fi
fi
printf '%s %s\n' "$idle" "$total" > "$stat_file"

# --- CPU temp: k10temp, PCI 0000:00:18.3 (stable across reboots, unlike
# the hwmonN number it happens to register under) ---
cpu_temp="?"
for f in /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input; do
    if [ -r "$f" ]; then
        cpu_temp="$(($(cat "$f") / 1000))"
        break
    fi
done

# --- Memory usage: MemTotal/MemAvailable, same basis the native memory
# module uses (not naive MemFree, which ignores cache/buffers) ---
mem_total="$(awk '/^MemTotal:/{print $2}' /proc/meminfo)"
mem_avail="$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)"
mem_usage=$(( (100 * (mem_total - mem_avail)) / mem_total ))

# --- Discrete GPU usage/temp: found by PCI address, not card/hwmon number,
# since those can reorder after a driver update or reboot ---
gpu_pci=0000:03:00.0
card_dev=""
for c in /sys/class/drm/card[0-9]*/device; do
    case "$(readlink -f "$c")" in
        *"$gpu_pci") card_dev="$c" ;;
    esac
done

gpu_usage="?"
if [ -n "$card_dev" ] && [ -r "$card_dev/gpu_busy_percent" ]; then
    gpu_usage="$(cat "$card_dev/gpu_busy_percent")"
fi

hwmon=""
if [ -n "$card_dev" ]; then
    for h in "$card_dev"/hwmon/hwmon*; do
        if [ -d "$h" ]; then
            hwmon="$h"
            break
        fi
    done
fi

gpu_temp="?"
if [ -n "$hwmon" ]; then
    for f in "$hwmon"/temp*_label; do
        [ -r "$f" ] || continue
        if [ "$(cat "$f")" = "junction" ]; then
            input="${f%_label}_input"
            if [ -r "$input" ]; then
                gpu_temp="$(($(cat "$input") / 1000))"
            fi
            break
        fi
    done
fi

# --- worst-case class across every metric, same 85/95 convention used
# elsewhere in this config ---
class="normal"
for v in "$cpu_usage" "$cpu_temp" "$mem_usage" "$gpu_usage" "$gpu_temp"; do
    if [ "$v" = "?" ]; then
        continue
    fi
    if [ "$v" -ge 95 ]; then
        class="critical"
    elif [ "$v" -ge 85 ] && [ "$class" != "critical" ]; then
        class="warning"
    fi
done

text="$cpu_icon $cpu_usage% $temp_icon $cpu_temp°C  $mem_icon $mem_usage%  $gpu_icon $gpu_usage% $temp_icon $gpu_temp°C"
tooltip="CPU: $cpu_usage% ($cpu_temp°C)\nMemory: $mem_usage%\nGPU: $gpu_usage% ($gpu_temp°C)"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
