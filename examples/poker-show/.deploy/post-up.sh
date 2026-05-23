#!/usr/bin/env bash
# Re-apply VPN policy routing after api container possibly got a new IP.
# Telegram egress goes through the VPN tunnel.
set -euo pipefail

SERVICE="${VPN_ROUTING_SERVICE:-vpn-policy-routing.service}"

if systemctl list-unit-files "$SERVICE" >/dev/null 2>&1; then
  if systemctl restart "$SERVICE" 2>/dev/null; then
    echo "VPN routing re-applied ($SERVICE)"
  else
    echo "WARN: could not restart $SERVICE (need root?) — Telegram may break until re-applied"
  fi
else
  echo "VPN routing service not installed — skipping"
fi
