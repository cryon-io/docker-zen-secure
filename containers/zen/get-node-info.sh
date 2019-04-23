#!/bin/sh

#  HORIZEN Secure Node docker template
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

ver=$(./get-version.sh)
type="ZEN_SECURE"

API_KEY=$(cat ~/api.key)
NODE_ID=$(jq .secure.nodeid "$HOME/nodetracker/config/config.json" -r)
if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "null" ]; then 
    NODE_ID=$(jq .secure.nodeid "$HOME/nodetracker/config/config.json.BACK" -r)
fi
HOME_SERVER="https://securenodes$(jq .secure.home "$HOME/nodetracker/config/config.json" -r | sed 's\ts\\g').zensystem.io"

mn_info=$(curl -s -X GET -w "\n%{http_code}\n" --url "$HOME_SERVER/api/nodes/$NODE_ID/detail?key=$API_KEY" \
                                        --header 'Cache-Control: no-cache' \
                                        --silent -k)
HTTP_CODE=$(printf "%s" "$mn_info" | tail -n 1) 
if [ "$HTTP_CODE" = "200" ]; then 
    CONTENT_LINES_COUNT=$(($(printf "%s" "$RESULT" | wc -l) - 1))
    mn_status="$(printf "%s" "$mn_info" | head -n $CONTENT_LINES_COUNT | jq .status -r)"
    if [ "$mn_status" = "up" ]; then
        mn_status="Securenode successfully started"
    fi
    if [ "$mn_status" = "null" ]; then
        mn_status="unknown"
    fi
else 
    mn_status="unknown"
fi

block_count="$(zen-cli getblockchaininfo 2>&1)"
if printf "%s" "$block_count" | grep "error message:"; then 
    block_count=$(printf "%s" "$block_count" | tail -n 1)   
else 
    block_count="$(printf "%s" "$block_count" | jq .blocks)"
fi

network_info="$(zen-cli getnetworkinfo 2>&1)"
if printf "%s" "$network_info" | grep "error message:"; then
    cert_valid="$(printf "%s" "$network_info" | tail -n 1)"
else 
    cert_valid="$(printf "%s" "$network_info" | jq .tls_cert_verified)"
    if [ "$cert_valid" = "true" ]; then
        cert_valid="valid"
    else
        cert_valid="invalid"
    fi
fi

explorer_stats=$(curl -sL https://explorer.zen-solutions.io/api/sync)
sync_status=false
if [ "$(($(printf "%s" "$explorer_stats" | jq .blockChainHeight) - 10))" -le "$block_count" ]; then
    sync_status=true
fi

printf "\
TYPE: %s
VERSION: %s
MN STATUS: %s
BLOCKS: %s
SYNCED: %s
ADDITIONAL INFO-CERT: %s
" "$type" "$ver" "$mn_status" "$block_count" "$sync_status" "$cert_valid"> /home/zen/.zen/node.info

printf "\
TYPE: %s
VERSION: %s
MN STATUS: %s
BLOCKS: %s
SYNCED: %s
ADDITIONAL INFO-CERT: %s
" "$type" "$ver" "$mn_status" "$block_count" "$sync_status" "$cert_valid"