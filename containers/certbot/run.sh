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

BASEDIR=$(dirname "$0")

# shellcheck disable=SC2154
if [ ! "$ip" = "$(dig "$fqdn" @1.1.1.1 +short)" ]; then
    exit 2
fi

if [ -f "$BASEDIR/certs/privkey.pem" ] && [ -f "$BASEDIR/certs/chain.pem" ] && [ ! -f "$BASEDIR/certs/temp.certs" ]; then
    certbot renew --no-self-upgrade --config-dir "$BASEDIR/certbot/" --work-dir "$BASEDIR/certbot/" --logs-dir "$BASEDIR/certbot/" --http-01-port 8080
else
    certbot certonly -n --agree-tos --register-unsafely-without-email --standalone -d "$fqdn" --config-dir "$BASEDIR/certbot/" --work-dir "$BASEDIR/certbot/" --logs-dir "$BASEDIR/certbot/"   --http-01-port 8080
fi

newPath=$(ls -td "$BASEDIR/certbot/live/"*/ | head -1)

privkeyHash=$(sha256sum "$newPath/privkey.pem" | awk '{ print $1 }')
privkeyHash2=$(sha256sum "$BASEDIR/certs/privkey.pem" | awk '{ print $1 }')
chainHash=$(sha256sum "$newPath/chain.pem" | awk '{ print $1 }')
chainHash2=$(sha256sum "$BASEDIR/certs/chain.crt" | awk '{ print $1 }')
certHash=$(sha256sum "$newPath/cert.pem" | awk '{ print $1 }')
certHash2=$(sha256sum "$BASEDIR/certs/cert.pem" | awk '{ print $1 }')

UPDATED=false

if [ ! -f "$BASEDIR/certs/chain.crt" ] || [ ! "$chainHash" = "$chainHash2" ]; then
    cp -f "$newPath/chain.pem" "$BASEDIR/certs/chain.crt" || exit 3
    chmod 751 "$BASEDIR/certs/chain.crt"
    UPDATED=true
fi;

if [ ! -f "$BASEDIR/certs/cert.pem" ] || [ ! "$certHash" = "$certHash2" ]; then
    cp -f "$newPath/cert.pem" "$BASEDIR/certs/cert.pem" || exit 4
    UPDATED=true
fi;

if [ ! -f "$BASEDIR/certs/privkey.pem" ] || [ ! "$privkeyHash" = "$privkeyHash2" ]; then
    cp -f "$newPath/privkey.pem" "$BASEDIR/certs/privkey.pem" || exit 4
    UPDATED=true
fi;

chmod -R 755 "$BASEDIR/certs/"
if [ "$UPDATED" = "true" ]; then
    exit 1;
fi