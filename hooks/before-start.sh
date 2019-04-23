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
BOOTSTRAP_URL=""

if [ ! -d "$BASEDIR/../data/blocks" ]; then 
    
    if [ -n "$BOOTSTRAP_URL" ]; then
        URL="$BOOTSTRAP_URL"
    fi
   
    if [ -n "$URL" ]; then
        FILE=snapshot

        printf "loading chain snapshot"
        case "$URL" in
        *.tar.gz) 
            (cd "$BASEDIR/../data/" && \
            curl -L "$URL" -o "./$FILE.tar.gz" && \
            tar -xzvf "./$FILE.tar.gz" && \
            rm -f "./$FILE.tar.gz")
        ;;
        *.zip)
            (cd "$BASEDIR/../data/" && \
            curl -L "$URL" -o "./$FILE.zip" && \
            unzip "./$FILE.zip" && \
            rm -f "./$FILE.zip")
        ;;
        esac
        
    fi
fi

# handle certificates
docker-compose -f "$BASEDIR/../containers/certbot/docker-compose.yml" run --service-ports certbot
certbot_exit_code=$?
sh "$BASEDIR/../tools/fs-permissions.sh"

case "$certbot_exit_code" in
    "0")
        echo "Already have valid certificates..."
    ;;
    "1")
        echo "Certificates obtained or renewed"
    ;;
    "2")
        echo "Cannot obtaine certificate, if IP address does not match. Check for dns propagation of your domain..."
        exit 1
    ;;
    "3")
        echo "Failed to obtain chain.crt. Please retry..."
        exit 2
    ;;
    "4")
        echo "Failed to obtain cert.pem. Please retry..." 
        exit 3
    ;;
    "5")
        echo "Failed to obtain privkey.pem. Please retry..."
        exit 4;
    ;;
esac
exit 0
