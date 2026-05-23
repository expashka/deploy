#!/usr/bin/env bash
# Re-apply VPN policy routing so Telegram egress keeps working
# after the api container possibly got a new IP.
set -euo pipefail

VPN_SCRIPT="${VPN_ROUTING_SCRIPT:-/usr/local/sbin/vpn-policy-routing.sh}"

if [[ -x "$VPN_SCRIPT" ]]; then
  "$VPN_SCRIPT"
  echo "VPN routing re-applied via $VPN_SCRIPT"
else
  echo "VPN routing script not found at $VPN_SCRIPT — skipping"
fi
