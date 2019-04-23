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

PATH_TO_SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$PATH_TO_SCRIPT")

if [ -f "$BASEDIR/../project_id" ]; then
    PROJECT=$(sed 's/PROJECT=//g' "$BASEDIR/../project_id")
    PROJECT="--project-name $PROJECT"
fi

container=$(docker-compose -f "$BASEDIR/../docker-compose.yml" $PROJECT ps -q mn)
if [ -z "$container" ]; then 
    # masternode is not running
    exit 1
fi

# update certificates
docker-compose -f "$BASEDIR/../containers/certbot/docker-compose.yml" run certbot
certs_exit_code=$?
sh "$BASEDIR/../tools/fs-permissions.sh"
# update node
if docker exec --user zen "$container" apt list --upgradable | grep zen/ || [ "$certs_exit_code" = "1" ]; then
    docker-compose -f "$BASEDIR/../docker-compose.yml" $PROJECT build --no-cache && \
    docker-compose -f "$BASEDIR/../docker-compose.yml" $PROJECT up -d --force-recreate
    sleep 10
    container=$(docker-compose -f "$BASEDIR/../docker-compose.yml" $PROJECT ps -q mn)
    sh "$BASEDIR/../tools/fs-permissions.sh"
    if docker exec --user zen "$container" apt list --upgradable | grep zen/; then
        exit 0
    else 
        # failed to update masternode
        exit 2
    fi
else 
    exit 0
fi