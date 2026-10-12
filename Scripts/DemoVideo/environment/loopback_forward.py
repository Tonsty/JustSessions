"""Forwards a port on 127.0.0.1 to the VM's SSH port, so the demo app reaches devbox over loopback.

macOS asks before a newly signed app reaches the local network; loopback is not covered, so the forward lets the
demo app's bundle ID connect without a Local Network grant.

Usage: loopback_forward.py <listen port> <VM address> [VM port]
"""
import socket
import sys
import threading


def pipe(source, destination):
    try:
        while data := source.recv(65536):
            destination.sendall(data)
    except OSError:
        pass
    finally:
        for end in (source, destination):
            try:
                end.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass


def serve(listen_port, target):
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", listen_port))
    listener.listen(32)
    while True:
        client, _ = listener.accept()
        upstream = socket.create_connection(target)
        threading.Thread(target=pipe, args=(client, upstream), daemon=True).start()
        threading.Thread(target=pipe, args=(upstream, client), daemon=True).start()


if __name__ == "__main__":
    serve(int(sys.argv[1]), (sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 22))
