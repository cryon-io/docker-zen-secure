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

FROM ubuntu:bionic

# setup dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y
# RUN apt install software-properties-common -y
# RUN add-apt-repository universe -y

#RUN apt-get install build-essential software-properties-common apt-transport-https lsb-release dirmngr pwgen jq curl git -y
RUN apt-get install build-essential software-properties-common apt-transport-https lsb-release dirmngr pwgen git jq curl runit bc -y

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt install -y nodejs

RUN echo 'deb https://zencashofficial.github.io/repo/ '$(lsb_release -cs)' main' | tee /etc/apt/sources.list.d/zen.list
RUN gpg --keyserver keyserver.ubuntu.com  --recv 219F55740BBF7A1CE368BA45FB7053CE4991B669 || gpg --keyserver ha.pool.sks-keyservers.net --recv 219F55740BBF7A1CE368BA45FB7053CE4991B669
RUN gpg --export 219F55740BBF7A1CE368BA45FB7053CE4991B669 | apt-key add -
RUN add-apt-repository ppa:certbot/certbot -y
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install zen certbot -y

ADD healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK --interval=10s --timeout=30s --start-period=30s --retries=3 \
  CMD /healthcheck.sh

# create user
RUN adduser --disabled-login \
         --disabled-password \
         --gecos "" \
         --uid 12000 \
         zen

WORKDIR /home/zen/

COPY get-node-info.sh ./get-node-info.sh
COPY get-version.sh ./get-version.sh
COPY ./boot.sh /sbin/boot.sh
# set execution rights
RUN chmod +x /sbin/boot.sh ./get-version.sh ./get-node-info.sh

#prepare node tracker
RUN git clone https://github.com/ZencashOfficial/nodetracker.git
WORKDIR /home/zen/nodetracker
RUN npm install

# prepare runit services
WORKDIR /home/zen/
COPY ./service ./service
RUN chmod +x ./service/**/run
RUN mkdir -p ./run_once

WORKDIR /home/zen/
# prepare certificate management and store
ADD update-cert-store.sh ./run_once/update-cert-store
RUN chmod +x ./run_once/update-cert-store
RUN chown -R zen:zen /usr/local/share/ca-certificates/
RUN chown -R zen:zen /etc/ssl/certs/

# take ownership of all files in home dir
RUN chown -R zen:zen .

USER zen
# boot zen secure
CMD [ "/sbin/boot.sh" ]
