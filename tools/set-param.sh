#!/bin/sh

#  Horizen Secure Node docker template
#  Copyright © 2019 cryon.io
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#  Contact: cryi@tutanota.com

BASEDIR=$(dirname "$0")

PARAM=$(echo "$1" | sed "s/=.*//")
VALUE=$(echo "$1" | sed "s/[^>]*=//")


# Sets value in json file (if file does not exist or invalid, it is recreated)
# Params:
# $1 - file
# $2 - key
# $3 - value
set_json_file_value() {
    if [ -s "$1" ]; then 
        JSON_VALUE=$(jq ".secure | . = if has(\"$2\") then .[\"$2\"] = \"$3\" else . + { \"$2\" : \"$3\" } end " "$1" )
        JSON_VALUE=$(jq ". | . = if has(\"secure\") then .[\"secure\"] = $JSON_VALUE else . + { \"secure\": $JSON_VALUE } end " "$1")
        altValue="{ secure : { \"$2\":\"$3\" } }"
        printf "%s\n" "${JSON_VALUE:-$altValue}" > "$1" # in case json file is invalid, we will overwrite it
    else 
        printf "%s\n" "{ secure : { \"$2\":\"$3\" } }" > "$1"
    fi
} 

if [ ! -f "$BASEDIR/../data/tracker/config/config.json" ]; then
    cp "$BASEDIR/../config/template.json" "$BASEDIR/../data/tracker/config/config.json"
fi

case $PARAM in
    ip)
        TEMP=$(sed "s/externalip=.*/externalip=$VALUE/g" "$BASEDIR/../data/zen/zen.conf")
        printf "%s" "$TEMP" > "$BASEDIR/../data/zen/zen.conf"
        TEMP=$(sed "s/      - ip=.*/      - ip=$VALUE/g" "$BASEDIR/../containers/certbot/docker-compose.yml")
        printf "%s" "$TEMP" > "$BASEDIR/../containers/certbot/docker-compose.yml"
    ;;  
    PROJECT)
        printf "PROJECT=%s" "$VALUE" >  "$BASEDIR/../project_id"
    ;;
    bootstrap)
        TEMP=$(sed "s/BOOTSTRAP_URL=.*/BOOTSTRAP_URL=\"$VALUE\"/g" "$BASEDIR/before-start.sh")
        printf "%s" "$TEMP" > "$BASEDIR/before-start.sh"
    ;;
    stakeaddr|email|ipv|nodetype)
        set_json_file_value "$BASEDIR/../data/tracker/config/config.json" "$PARAM" "$VALUE"
    ;;
    fqdn)
        set_json_file_value "$BASEDIR/../data/tracker/config/config.json" "$PARAM" "$VALUE"
        TEMP=$(sed "s/      - fqdn=.*/      - fqdn=$VALUE/g" "$BASEDIR/../containers/certbot/docker-compose.yml")
        printf "%s" "$TEMP" > "$BASEDIR/../containers/certbot/docker-compose.yml"
    ;;
    region)
        servers=$(jq ".secure | .servers | .[]" "$BASEDIR/../data/tracker/config/config.json" -r | grep ".$VALUE")
        random_home=$(awk -v min=1 -v max=$(echo "$servers" | wc -l) 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
        home=$(printf "%s" "$servers" | sed -n "$random_home,$random_home p")
        set_json_file_value "$BASEDIR/../data/tracker/config/config.json" "$PARAM" "$VALUE"
        set_json_file_value "$BASEDIR/../data/tracker/config/config.json" "home" "$home"
    ;;
    API_KEY)
        printf "%s" "$VALUE" > "$BASEDIR/../data/api.key"
    ;;
esac
