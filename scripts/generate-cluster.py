#!/usr/bin/env python3
"""Generate cluster.yaml and nodes.yaml from Proxmox VM metadata.

This script queries the Proxmox API for virtual machines tagged with
``k3s-server``, ``k3s-worker`` and ``k3s-storage``. The discovered VMs are used
as the basis for generating ``cluster.yaml`` and ``nodes.yaml`` files. The
generated configuration follows the structure of ``cluster.sample.yaml`` and
``nodes.sample.yaml``.

Environment variables required for authentication:

- ``PROXMOX_HOST`` – Proxmox host name or IP
- ``PROXMOX_USER`` and ``PROXMOX_PASSWORD`` or
  ``PROXMOX_TOKEN_ID`` and ``PROXMOX_TOKEN_SECRET``
- ``PROXMOX_VERIFY_SSL`` – ``true`` (default) or ``false``

The script is intentionally lightweight and only populates a subset of the
available fields. The resulting YAML files are meant to be tweaked manually
before use.
"""

import ipaddress
import os
from typing import Dict, List, Optional

import yaml
from proxmoxer import ProxmoxAPI

ROLE_TAGS = {
    "k3s-server": "controller",
    "k3s-worker": "worker",
    "k3s-storage": "storage",
}


def connect_proxmox() -> Optional[ProxmoxAPI]:
    host = os.environ.get("PROXMOX_HOST")
    verify = os.environ.get("PROXMOX_VERIFY_SSL", "true").lower() == "true"

    token_id = os.environ.get("PROXMOX_TOKEN_ID")
    token_secret = os.environ.get("PROXMOX_TOKEN_SECRET")
    user = os.environ.get("PROXMOX_USER")
    password = os.environ.get("PROXMOX_PASSWORD")

    if not host:
        print("PROXMOX_HOST not set, skipping generation")
        return None

    try:
        if token_id and token_secret:
            return ProxmoxAPI(host, token_id=token_id, token_secret=token_secret, verify_ssl=verify)
        return ProxmoxAPI(host, user=user, password=password, verify_ssl=verify)
    except Exception as err:  # pragma: no cover - best effort connection
        print(f"Failed to connect to Proxmox: {err}")
        return None


def get_vms(proxmox: ProxmoxAPI) -> List[Dict]:
    """Return VM information filtered by ROLE_TAGS."""
    resources = proxmox.cluster.resources.get(type="vm")
    vms = []
    for vm in resources:
        tags = {t.strip() for t in (vm.get("tags") or "").split(",") if t.strip()}
        if not tags.intersection(ROLE_TAGS.keys()):
            continue
        vms.append(vm)
    return vms


def first_ipv4(interface: Dict) -> Optional[Dict]:
    for addr in interface.get("ip-addresses", []):
        if addr.get("ip-address-type") == "ipv4":
            return addr
    return None


def vm_network_info(proxmox: ProxmoxAPI, node: str, vmid: str) -> (Optional[str], Optional[str], Optional[int]):
    try:
        result = proxmox.nodes(node).qemu(vmid).agent("network-get-interfaces").get()
    except Exception:  # pragma: no cover - guest agent may not be running
        return None, None, None
    for iface in result.get("result", []):
        ipv4 = first_ipv4(iface)
        if ipv4:
            return ipv4.get("ip-address"), iface.get("hardware-address"), ipv4.get("prefix")
    return None, None, None


def vm_disk_info(proxmox: ProxmoxAPI, node: str, vmid: str) -> Optional[str]:
    try:
        config = proxmox.nodes(node).qemu(vmid).config.get()
    except Exception:  # pragma: no cover - fallback when API fails
        return None
    for key in ("scsi0", "virtio0", "sata0", "ide0"):
        disk = config.get(key)
        if disk:
            return disk
    return None


def compute_cidr(ip: str, prefix: int) -> str:
    network = ipaddress.ip_network(f"{ip}/{prefix}", strict=False)
    return str(network)


def generate():
    proxmox = connect_proxmox()
    if not proxmox:
        return

    vms = get_vms(proxmox)
    if not vms:
        print("No matching VMs found")
        return

    nodes: List[Dict] = []
    cidr: Optional[str] = None

    for vm in vms:
        node_name = vm["node"]
        vmid = vm["vmid"]
        name = vm["name"]
        tags = {t.strip() for t in (vm.get("tags") or "").split(",") if t.strip()}

        ip, mac, prefix = vm_network_info(proxmox, node_name, vmid)
        disk = vm_disk_info(proxmox, node_name, vmid)

        if ip and prefix and not cidr:
            cidr = compute_cidr(ip, prefix)

        node_data = {
            "name": name,
            "address": ip or "",
            "controller": "k3s-server" in tags,
            "disk": disk or "",
            "mac_addr": mac or "",
            "schematic_id": "",
        }
        nodes.append(node_data)

    with open("nodes.yaml", "w") as f:
        yaml.safe_dump({"nodes": nodes}, f, sort_keys=False)
        print("nodes.yaml written")

    cluster_config = {}
    if os.path.exists("cluster.sample.yaml"):
        with open("cluster.sample.yaml") as f:
            cluster_config = yaml.safe_load(f)
    if cidr:
        cluster_config["node_cidr"] = cidr
    with open("cluster.yaml", "w") as f:
        yaml.safe_dump(cluster_config, f, sort_keys=False)
        print("cluster.yaml written")


if __name__ == "__main__":
    generate()
