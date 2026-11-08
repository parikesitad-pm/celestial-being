#!/usr/bin/env bash
# GPU status for waybar. Never wakes the NVIDIA dGPU (keeps battery + heat low).
# iGPU load is approximated by actual/max GT frequency (no root needed).
igpu=/sys/class/drm/card1
dgpu=/sys/class/drm/card0

# resolve by vendor id, so card numbering changes don't matter
for c in /sys/class/drm/card[0-9]; do
  v=$(cat "$c/device/vendor" 2>/dev/null)
  [ "$v" = "0x8086" ] && igpu=$c
  [ "$v" = "0x10de" ] && dgpu=$c
done

act=$(cat "$igpu/gt_act_freq_mhz" 2>/dev/null || echo 0)
max=$(cat "$igpu/gt_max_freq_mhz" 2>/dev/null || echo 1)
ipct=$(( act * 100 / max ))
tip="Intel Iris Xe: ${act}/${max} MHz"
text="󰢮 ${ipct}%"

if [ "$(cat "$dgpu/device/power/runtime_status" 2>/dev/null)" = "active" ] && command -v nvidia-smi >/dev/null; then
  read -r u t < <(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | tr -d ',')
  if [ -n "$u" ]; then
    text="󰢮 ${ipct}% · N ${u}%"
    tip="$tip\nNVIDIA GTX 1650: ${u}% ${t}°C"
  fi
else
  tip="$tip\nNVIDIA GTX 1650: sleeping (0 W)"
fi

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tip"
