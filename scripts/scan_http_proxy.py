import socket
import ipaddress
import argparse

def is_port_open(ip, port, timeout=0.1):
    try:
        with socket.create_connection((str(ip), port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def find_first_open_host(network, port):
    net = ipaddress.ip_network(network, strict=False)
    for ip in net.hosts():
        if is_port_open(ip, port):
            return str(ip)
    return None

def main():
    parser = argparse.ArgumentParser(description="Find first host with open port and print as Ansible variable")
    parser.add_argument("--network", default="192.168.0.0/24", help="CIDR network to scan (default: 192.168.0.0/24)")
    parser.add_argument("--port", type=int, default=3142, help="Port to scan (default: 3142)")
    args = parser.parse_args()

    #print(f"Scanning network {args.network} for port {args.port}...")

    host = find_first_open_host(args.network, args.port)

    if host:
        #print("\n# Ansible variable:")
        print(f"proxy_host: {host}")
    else:
        print("\nNo host found with port", args.port, "open in network", args.network)

if __name__ == "__main__":
    main()

