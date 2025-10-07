#!/usr/bin/env python3

import ipaddress
import scapy.all as scapy
import sys
import json

def find_free_ip(subnet_str):
    try:
        subnet = ipaddress.ip_network(subnet_str, strict=False)
    except ValueError as e:
        print(f"Invalid subnet: {e}", file=sys.stderr)
        sys.exit(1)

    # Skanujemy tylko hosty (bez adresu sieci i broadcastu)
    ip_list = list(subnet.hosts())

    # Wyślij ARP requests
    ans, _ = scapy.arping(str(subnet), verbose=0)

    # Zbieramy używane IP
    used_ips = set()
    for snd, rcv in ans:
        used_ips.add(rcv.psrc)

    # Znajdź pierwszy wolny adres IP
    for ip in ip_list:
        if str(ip) not in used_ips:
            #print(ip)
            print(json.dumps({"ip": str(ip)}))
            return

    print("No free IPs found in the subnet", file=sys.stderr)
    sys.exit(2)

if __name__ == "__main__":
    subnet = sys.argv[1] if len(sys.argv) > 1 else "192.168.0.0/24"
    find_free_ip(subnet)
