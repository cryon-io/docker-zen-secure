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

INNER_UID=12000
target_uid=$(grep "dockremap" /etc/subuid)
target_uid=$(echo "$target_uid" | cut -d ":" -f 2)
INNER_UID=$(($target_uid + $INNER_UID))

DIRS=\
'{
    "writable": [
        "data/certbot",
        "data/zen",
        "data/certs",
        "data/tracker",
        "data/zen-params"
    ]
}'

chmod +x "$BASEDIR/../zen-cli"
chmod +x "$BASEDIR/"*.sh

echo "Configuring access permissions for UID: $INNER_UID"
for row in $(printf "%s\n" "$DIRS" | jq -r '.writable[]'); do
    echo "Setting permission for path: $BASEDIR/../$row"
    chown -R $INNER_UID:ans "$BASEDIR/../$row" && echo "Access permission to '$row' set to uid $INNER_UID."
done
chmod -R 750 "$BASEDIR/../data/certs/"
chmod -R a+rwx "$BASEDIR/../data/"*
exit $?