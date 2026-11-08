#!/usr/bin/env bash
# one line every 2s: cpu%|memGB|tempC|bat%|batStatus|igpu%|gpu%|lan|ssid|signal
pt=0; pi=0; i=0; ssid=""; sig=0; prc=0; pnow=0
intel=""
for card in /sys/class/drm/card[0-9]; do
  [[ $(cat "$card/device/vendor" 2>/dev/null) == 0x8086 ]] && intel=$card
done
while true; do
  # Busy time: the share of this interval the GPU spent outside its RC6 sleep state.
  igpu=""
  if [[ -r $intel/gt/gt0/rc6_residency_ms ]]; then
    rc=$(<"$intel/gt/gt0/rc6_residency_ms"); now=$(date +%s%3N)
    if (( prc > 0 && now > pnow )); then
      igpu=$(( 100 - (rc - prc) * 100 / (now - pnow) ))
      (( igpu < 0 )) && igpu=0
      (( igpu > 100 )) && igpu=100
    fi
    prc=$rc; pnow=$now
  fi
  read -r _ u n s idle iow irq sirq st _ < /proc/stat
  t=$((u+n+s+idle+iow+irq+sirq+st)); id=$((idle+iow)); dt=$((t-pt)); di=$((id-pi))
  cpu=$(( dt>0 ? (100*(dt-di))/dt : 0 )); pt=$t; pi=$id
  mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f",(t-a)/1048576}' /proc/meminfo)
  temp=$(( $(cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 || echo 0) / 1000 ))
  bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
  chg=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
  # A runtime-suspended dGPU reads as 0%: calling nvidia-smi would wake it.
  gpm=$(cat /sys/bus/pci/drivers/nvidia/0000:*/power/runtime_status 2>/dev/null | head -1)
  case "$gpm" in
    "") gpu="" ;;
    suspended) gpu=0 ;;
    *) gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1) ;;
  esac
  # up = cable on any physical wired interface, empty = no wired interface
  lan=""
  for nic in /sys/class/net/*; do
    [[ -e $nic/device && ! -d $nic/wireless ]] || continue
    lan=down
    [[ $(cat "$nic/carrier" 2>/dev/null) == 1 ]] && { lan=up; break; }
  done
  if (( i % 3 == 0 )); then
    line=$(nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null | grep '^yes' | head -1)
    sig=$(cut -d: -f2 <<<"$line"); ssid=$(cut -d: -f3- <<<"$line")
  fi
  echo "$cpu|$mem|$temp|$bat|$chg|$igpu|$gpu|$lan|$ssid|${sig:-0}"
  i=$((i+1)); sleep 2
done
