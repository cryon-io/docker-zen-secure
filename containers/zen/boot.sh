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


shutdown() {
  echo "shutting down container"

  # first shutdown any service started by runit
  for _srv in $(ls -1 ~/service); do
    sv force-stop $_srv
  done

  # shutdown runsvdir command
  kill -HUP $RUNSVDIR
  wait $RUNSVDIR

  # give processes time to stop
  sleep 0.5

  # kill any other processes still running in the container
  for _pid  in $(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1$' | head -n -6); do
    timeout -t 30 /bin/sh -c "kill $_pid && wait $_pid || kill -9 $_pid"
  done
  exit
}


export ZENCONF=/home/zen/.zen/zen.conf
# store enviroment variables
export > /home/zen/envvars

PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin

touch /home/zen/.fetching-params

zen-fetch-params

rm /home/zen/.fetching-params
# run all scripts in the run_once folder
/bin/run-parts ~/run_once

exec env - PATH=$PATH runsvdir -P ~/service &

RUNSVDIR=$!
echo "Started runsvdir, PID is $RUNSVDIR"
echo "wait for processes to start...."

sleep 5
for _srv in $(ls -1 ~/service); do
    sv status $_srv
done

# catch shutdown signals
trap shutdown TERM HUP QUIT INT
wait $RUNSVDIR

shutdown
