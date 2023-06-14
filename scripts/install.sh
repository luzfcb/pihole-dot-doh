#!/bin/bash

# clean stubby config
mkdir -p /etc/stubby \
    && rm -f /etc/stubby/stubby.yml

# urls:
# https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
# https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-armhf.deb
# https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb
# https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb


# Run your shell script and detect the architecture
architecture=$(uname -m)
if [ "${architecture}" = "x86_64" ]; then
  echo "Current architecture is amd64. Using cloudflared-linux-amd64.deb"
  cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
elif [ "${architecture}" = "armv7l" ]; then
  echo "Current architecture is ARMv7. Using cloudflared-linux-armhf.deb"
  cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-armhf.deb"
elif [ "${architecture}" = "armv6l" ]; then
  echo "Current architecture is ARMv6. Using cloudflared-linux-arm.deb"
  cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb"
elif [ "${architecture}" = "aarch64" ]; then
  echo "Current architecture is ARM64. Using cloudflared-linux-arm64.deb"
  cloudflared_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
else
  echo "Unknown architecture: ${architecture}"
  exit 1
fi


# install cloudflared
cd /tmp \
&& wget "${cloudflared_url}" -O /tmp/cloudflared.deb \
&& apt install -y /tmp/cloudflared.deb \
&& rm -f /tmp/cloudflared.deb \
&& echo "$(date "+%d.%m.%Y %T") Cloudflared installed for ${architecture}" >> /build_date.info


useradd -s /usr/sbin/nologin -r -M cloudflared \
    && chown cloudflared:cloudflared /usr/local/bin/cloudflared
    
# clean cloudflared config
mkdir -p /etc/cloudflared \
    && rm -f /etc/cloudflared/config.yml

# clean up
apt -y autoremove \
    && apt -y autoclean \
    && apt -y clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

#!/bin/bash

# Creating pihole-dot-doh service
mkdir -p /etc/services.d/pihole-dot-doh

# run file
echo '#!/usr/bin/env bash' | tee /etc/services.d/pihole-dot-doh/run
# Copy config file if not exists
echo 'cp -n /temp/stubby.yml /config/' | tee -a /etc/services.d/pihole-dot-doh/run
echo 'cp -n /temp/cloudflared.yml /config/' | tee -a /etc/services.d/pihole-dot-doh/run
# run stubby in background
echo 's6-echo "Starting stubby"' | tee -a /etc/services.d/pihole-dot-doh/run
echo 'stubby -g -C /config/stubby.yml' | tee -a /etc/services.d/pihole-dot-doh/run
# run cloudflared in foreground
echo 's6-echo "Starting cloudflared"' | tee -a /etc/services.d/pihole-dot-doh/run
echo '/usr/local/bin/cloudflared --config /config/cloudflared.yml' | tee -a /etc/services.d/pihole-dot-doh/run
chmod 755 /etc/services.d/pihole-dot-doh/run

# finish file
echo '#!/usr/bin/env bash' | tee /etc/services.d/pihole-dot-doh/finish
echo 's6-echo "Stopping stubby"' | tee -a /etc/services.d/pihole-dot-doh/finish
echo 'killall -9 stubby' | tee -a /etc/services.d/pihole-dot-doh/finish
echo 's6-echo "Stopping cloudflared"' | tee -a /etc/services.d/pihole-dot-doh/finish
echo 'killall -9 cloudflared' | tee -a /etc/services.d/pihole-dot-doh/finish
