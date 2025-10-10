import socket
import ipaddress
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

def is_port_open(ip, port, timeout=0.1):
    try:
        with socket.create_connection((str(ip), port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def find_first_open_host(network, port, max_threads=100):
    net = ipaddress.ip_network(network, strict=False)
    lock = threading.Lock()
    result = [None]

    def worker(ip):
        if result[0] is not None:
            return
        if is_port_open(ip, port):
            with lock:
                if result[0] is None:
                    result[0] = str(ip)

    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        futures = {executor.submit(worker, ip): ip for ip in net.hosts()}
        for future in as_completed(futures):
            if result[0] is not None:
                break

    return result[0]

def main():
    parser = argparse.ArgumentParser(description="Find first host with open port and print as Ansible variable")
    parser.add_argument("--network", default="192.168.0.0/24", help="CIDR network to scan (default: 192.168.0.0/24)")
    parser.add_argument("--port", type=int, default=3142, help="Port to scan (default: 3142)")
    args = parser.parse_args()

    host = find_first_open_host(args.network, args.port)

    if host:
        print(f"proxy_host: {host}")
    else:
        print(f"No host found with port {args.port} open in network {args.network}")

if __name__ == "__main__":
    main()

