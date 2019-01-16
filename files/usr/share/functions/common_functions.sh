#!/bin/sh

. /usr/share/flashman_init.conf
. /usr/share/libubox/jshn.sh
. /usr/share/functions/device_functions.sh

log() {
  logger -t "$1 " "$2"
}

get_flashbox_version() {
  echo "$(cat /etc/anlix_version)"
}

get_hardware_model() {
  echo "$(cat /tmp/sysinfo/model | awk '{ print toupper($2) }')"
}

get_hardware_version() {
  echo "$(cat /tmp/sysinfo/model | awk '{ print toupper($3) }')"
}

set_mqtt_secret() {
  json_cleanup
  json_load_file /root/flashbox_config.json
  json_get_var _mqtt_secret mqtt_secret
  json_close_object

  if [ "$_mqtt_secret" != "" ]
  then
    echo "$_mqtt_secret"
  else
    local _rand=$(head /dev/urandom | tr -dc A-Z-a-z-0-9)
    local _mqttsec=${_rand:0:32}
    local _data="id=$(get_mac)&mqttsecret=$_mqttsec"
    local _url="deviceinfo/mqtt/add"
    local _res=$(rest_flashman "$_url" "$_data")

    json_cleanup
    json_load "$_res"
    json_get_var _is_registered is_registered
    json_close_object

    if [ "$_is_registered" = "1" ]
    then
      json_cleanup
      json_load_file /root/flashbox_config.json
      json_add_string mqtt_secret $_mqttsec
      json_dump > /root/flashbox_config.json
      json_get_var _mqtt_secret mqtt_secret
      json_close_object
      echo "$_mqtt_secret"
    fi
  fi
}

reset_mqtt_secret() {
  json_cleanup
  json_load_file /root/flashbox_config.json
  json_get_var _mqtt_secret mqtt_secret

  if [ "$_mqtt_secret" != "" ]
  then
    json_add_string mqtt_secret ""
    json_dump > /root/flashbox_config.json
  fi

  json_close_object
  set_mqtt_secret
}

# send data to flashman using rest api
rest_flashman() {
  local _url=$1
  local _data=$2
  local _res
  local _curl_out
  _res=$(curl -s \
         -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
         --tlsv1.2 --connect-timeout 5 --retry 1 \
         --data "$_data&secret=$FLM_CLIENT_SECRET" \
         "https://$FLM_SVADDR/$_url")
  _curl_out=$?

  if [ "$_curl_out" -eq 0 ]
  then
    echo "$_res"
    return 0
  elif [ "$_curl_out" -eq 51 ]
  then
    # curl code 51 is bad certificate
    return 2
  else
    # other curl errors
    return 1
  fi
}

is_authenticated() {
  local _res
  local _is_authenticated=1

  if [ "$FLM_USE_AUTH_SVADDR" == "y" ]
  then
    _res=$(curl -s \
      -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
      --tlsv1.2 --connect-timeout 5 --retry 1 \
      --data \
      "id=$(get_mac)&organization=$FLM_CLIENT_ORG&secret=$FLM_CLIENT_SECRET" \
      "https://$FLM_AUTH_SVADDR/api/device/auth")

    json_cleanup
    json_load "$_res"
    json_get_var _is_authenticated is_authenticated
    json_close_object
  else
    _is_authenticated=0
  fi

  return $_is_authenticated
}
