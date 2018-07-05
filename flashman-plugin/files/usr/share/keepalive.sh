#!/bin/sh

. /usr/share/flashman_init.conf
. /usr/share/functions.sh
. /usr/share/libubox/jshn.sh

SERVER_ADDR="$FLM_SVADDR"
OPENWRT_VER=$(cat /etc/openwrt_version)
HARDWARE_MODEL=$(get_hardware_model)
HARDWARE_VER=$(cat /tmp/sysinfo/model | awk '{ print toupper($3) }')
SYSTEM_MODEL=$(get_system_model)
CLIENT_MAC=$(get_mac)
WAN_IP_ADDR=$(get_wan_ip)
WAN_CONNECTION_TYPE=$(uci get network.wan.proto | awk '{ print tolower($1) }')
PPPOE_USER=""
PPPOE_PASSWD=""
WIFI_SSID=""
WIFI_PASSWD=""
WIFI_CHANNEL=""

_need_update=0
while true
do
  sleep 300

  _number=$(head /dev/urandom | tr -dc "012345" | head -c1)

  if [ "$_number" -eq 3 ] || [ "$1" == "now" ]
  then
    # Get PPPoE data if available
    if [ "$WAN_CONNECTION_TYPE" == "pppoe" ]
    then
      PPPOE_USER=$(uci get network.wan.username)
      PPPOE_PASSWD=$(uci get network.wan.password)
    fi

    # Get WiFi data if available
    if [ "$(uci get wireless.@wifi-device[0].disabled)" == "0" ] || [ "$SYSTEM_MODEL" == "MT7628AN" ]
    then
      WIFI_SSID=$(uci get wireless.@wifi-iface[0].ssid)
      WIFI_PASSWD=$(uci get wireless.@wifi-iface[0].key)
      WIFI_CHANNEL=$(uci get wireless.radio0.channel)
    fi

     log "KEEPALIVE" "Ping Flashman ..."
    _data="id=$CLIENT_MAC&version=$ANLIX_PKG_VERSION&model=$HARDWARE_MODEL&model_ver=$HARDWARE_VER&release_id=$FLM_RELID&pppoe_user=$PPPOE_USER&pppoe_password=$PPPOE_PASSWD&wan_ip=$WAN_IP_ADDR&wifi_ssid=$WIFI_SSID&wifi_password=$WIFI_PASSWD&wifi_channel=$WIFI_CHANNEL&connection_type=$WAN_CONNECTION_TYPE"
    _url="https://$SERVER_ADDR/deviceinfo/syn/"
    _res=$(rest_flashman "$_url" "$_data") 

    if [ "$?" -eq 1 ]
    then
      log "KEEPALIVE" "Fail in Rest Flashman! Aborting..."
    else
      json_load "$_res"
      json_get_var _do_update do_update
      json_get_var _do_newprobe do_newprobe
      json_close_object

      if [ "$_do_newprobe" == "1" ]
      then
        log "KEEPALIVE" "Router Registred in Flashman Successfully!"
        #on a new probe, force a new registry in mqtt secret
        reset_mqtt_secret
        sh /usr/share/flashman_update.sh
      fi

      if [ "$_do_update" == "1" ]
      then
        _need_update=$(( _need_update + 1 ))
      else
        _need_update=0
      fi

      if [ $_need_update -eq 7 ]
      then
        #More than 7 checks (>20 min), force a firmware update
        log "KEEPALIVE" "Running update ..."                                                                                                                                          
        sh /usr/share/flashman_update.sh
      fi
    fi
  fi
done
