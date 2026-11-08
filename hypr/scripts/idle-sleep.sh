#!/usr/bin/env bash
# Runs once the machine has been idle long enough: suspends only on battery. While plugged in it
# keeps waiting, so unplugging during the idle stretch still suspends. hypridle kills it on resume.
supplies="${POWER_SUPPLY_DIR:-/sys/class/power_supply}"

while ! grep -qs '^Discharging$' "$supplies"/BAT*/status; do
    sleep 30
done
systemctl suspend
