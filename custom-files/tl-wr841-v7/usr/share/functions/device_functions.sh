#!/bin/sh

save_wifi_local_config() {
  uci commit wireless
}

is_5ghz_capable() {
  # false
  echo "0"
}

led_on() {
  if [ -f "$1"/brightness ]
  then
    if [ -f "$1"/max_brightness ]
    then
      cat "$1"/max_brightness > "$1"/brightness
    else
      echo "255" > "$1"/brightness
    fi
  fi
}

led_off() {
  if [ -f "$1"/trigger ]
  then
    echo "none" > "$1"/trigger
    echo "0" > "$1"/brightness
  fi
}

reset_leds() {
  for trigger_path in $(ls -d /sys/class/leds/*)
  do
    led_off "$trigger_path"
  done

  /etc/init.d/led restart > /dev/null

  led_on /sys/class/leds/tp-link\:green\:system
  if [ -f /sys/class/leds/ath9k-phy0/trigger ]
  then
    echo "phy0tpt" > /sys/class/leds/ath9k-phy0/trigger
  fi
}

blink_leds() {
	local _do_restart=$1

  if [ $_do_restart -eq 0 ]
  then
    ledsoff=$(ls -d /sys/class/leds/*)
    for trigger_path in $ledsoff
    do
      led_off "$trigger_path"
      echo "timer" > "$trigger_path"/trigger
    done
  fi
}

get_mac() {
  local _mac_address_tag=""
  local _p0
  _p0=$(awk '{print toupper($1)}' /sys/class/ieee80211/phy0/macaddress)

  if [ ! -z "$_p0" ]
  then
    _mac_address_tag=$_p0
  fi
  echo "$_mac_address_tag"
}

# Possible values: 10 or 100
get_wan_negotiated_speed() {
  cat /sys/class/net/eth1/speed
}

# Possible values: half or full
get_wan_negotiated_duplex() {
  cat /sys/class/net/eth1/duplex
}
