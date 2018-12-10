#!/bin/sh

. /usr/share/flashman_init.conf
. /usr/share/functions.sh

case "$1" in
1)
  log "MQTTMSG" "Running Update"
  sh /usr/share/flashman_update.sh $2
  ;;
boot)
  log "MQTTMSG" "Rebooting"
  /sbin/reboot
  ;;
rstmqtt)
  log "MQTTMSG" "Clean up MQTT secret"
  reset_mqtt_secret
  ;;
rstapp)
  log "MQTTMSG" "Clean up APP secret"
  rm /root/router_passwd
  ;;
log)
  log "MQTTMSG" "Sending LIVE log "
  send_boot_log "live"
  ;;
onlinedev)
  log "MQTTMSG" "Sending Online Devices.."
  send_online_devices 
  ;;
measure)
  log "MQTTMSG" "Changing Zabbix PSK settings"
  update_zabbix_psk "$2"
  ;;
*)
  log "MQTTMSG" "Cant recognize message: $1"
  ;;
esac

