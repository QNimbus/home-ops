#!/usr/bin/env python3
"""Generate cluster.yaml and nodes.yaml from Proxmox VM metadata.

This script queries the Proxmox API for virtual machines tagged with
``k8s-server``, ``k8s-worker`` and ``k8s-storage``. The discovered VMs are used
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

import argparse
import ipaddress
import os
import re
import sys
from typing import Dict, List, Optional

import yaml
from dotenv import load_dotenv
from git import Repo
from proxmoxer import ProxmoxAPI

ROLE_TAGS = {
    "k8s-server": "controller",
    "k8s-worker": "agent",
    "k8s-storage": "storage",
}


def get_repo_name() -> Optional[str]:
    """Return the GitHub repository name in the form 'owner/repo'."""
    try:
        repo = Repo(search_parent_directories=True)
        remote = repo.remotes.origin
        url = next(remote.urls)
    except Exception:  # pragma: no cover - git may not be set up
        return None

    match = re.search(r"github\.com[:/](.+?)(?:\.git)?$", url)
    if match:
        return match.group(1)
    return None


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
            return ProxmoxAPI(
                host,
                token_id=token_id,
                token_secret=token_secret,
                verify_ssl=verify,
            )
        return ProxmoxAPI(
            host,
            user=user,
            password=password,
            verify_ssl=verify,
        )
    except Exception as err:  # pragma: no cover - best effort connection
        print(f"Failed to connect to Proxmox: {err}")
        return None


def get_vms(proxmox: ProxmoxAPI) -> List[Dict]:
    """Return VM information filtered by ROLE_TAGS."""
    resources = proxmox.cluster.resources.get(type="vm")
    vms = []
    for vm in resources:
        tags = {
            t.strip()
            for t in (vm.get("tags") or "").split(",")
            if t.strip()
        }
        if not tags.intersection(ROLE_TAGS.keys()):
            continue
        vms.append(vm)
    return vms


def first_ipv4(interface: Dict) -> Optional[Dict]:
    for addr in interface.get("ip-addresses", []):
        if addr.get("ip-address-type") == "ipv4":
            return addr
    return None


def vm_network_info(
    proxmox: ProxmoxAPI, node: str, vmid: str
) -> (Optional[str], Optional[str], Optional[int]):
    try:
        result = (
            proxmox.nodes(node)
            .qemu(vmid)
            .agent("network-get-interfaces")
            .get()
        )
    except Exception as e:  # pragma: no cover - guest agent may not be running
        print(f"Warning: Could not get network info for VM {vmid} on node {node}: {e}")
        return None, None, None

    for iface in result.get("result", []):
        name = iface.get("name")
        # Skip loopback interface which usually reports 127.0.0.1
        if name == "lo":
            continue
        ipv4 = first_ipv4(iface)
        if ipv4:
            ip = ipv4.get("ip-address")
            try:
                if ipaddress.ip_address(ip).is_loopback:
                    continue
            except Exception:
                pass
            return (
                ip,
                iface.get("hardware-address"),
                ipv4.get("prefix"),
            )
    return None, None, None


def vm_config_network_info(proxmox: ProxmoxAPI, node: str, vmid: str) -> Optional[str]:
    """Get MAC address from VM configuration as fallback."""
    try:
        config = proxmox.nodes(node).qemu(vmid).config.get()
        # Look for network interfaces in config
        for key in config:
            if key.startswith('net') and '=' in str(config[key]):
                # Parse network config like "virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0"
                net_config = str(config[key])
                mac_match = re.search(r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})', net_config)
                if mac_match:
                    return mac_match.group(0).lower()
    except Exception as e:
        print(f"Warning: Could not get config network info for VM {vmid} on node {node}: {e}")
    return None


def vm_disk_info(proxmox: ProxmoxAPI, node: str, vmid: str) -> Optional[str]:
    """Get disk device path, converting from Proxmox disk specification."""
    try:
        config = proxmox.nodes(node).qemu(vmid).config.get()
    except Exception as e:  # pragma: no cover - fallback when API fails
        print(f"Warning: Could not get disk info for VM {vmid} on node {node}: {e}")
        return None

    # Look for disk configurations in order of preference
    # The first disk found will be considered the primary disk (/dev/sda)
    for key in ("scsi0", "virtio0", "sata0", "ide0"):
        disk = config.get(key)
        if disk:
            print(f"Found disk configuration for VM {vmid}: {key}={disk}")
            # For VM deployments, the first/primary disk is typically /dev/sda
            # regardless of the Proxmox disk specification
            return "/dev/sda"

    # If no disk found, return default
    print(f"No disk configuration found for VM {vmid}, using default /dev/sda")
    return "/dev/sda"


def compute_cidr(ip: str, prefix: int) -> str:
    network = ipaddress.ip_network(f"{ip}/{prefix}", strict=False)
    return str(network)


def generate(
    schematic_id: Optional[str] = None,
    node_cidr: Optional[str] = None,
    node_dns_servers: Optional[str] = None,
    node_ntp_servers: Optional[str] = None,
    node_default_gateway: Optional[str] = None,
    node_vlan_tag: Optional[str] = None,
    cluster_api_addr: Optional[str] = None,
    cluster_api_tls_sans: Optional[str] = None,
    cluster_pod_cidr: Optional[str] = None,
    cluster_svc_cidr: Optional[str] = None,
    cluster_dns_gateway_addr: Optional[str] = None,
    cluster_gateway_addr: Optional[str] = None,
    repository_name: Optional[str] = None,
    repository_branch: Optional[str] = None,
    repository_visibility: Optional[str] = None,
    cloudflare_domain: Optional[str] = None,
    cloudflare_token: Optional[str] = None,
    cloudflare_gateway_addr: Optional[str] = None,
    cilium_loadbalancer_mode: Optional[str] = None,
    cilium_bgp_router_addr: Optional[str] = None,
    cilium_bgp_router_asn: Optional[str] = None,
    cilium_bgp_node_asn: Optional[str] = None,
):
    print("Starting cluster and nodes generation...")
    load_dotenv()

    print("Attempting to connect to Proxmox...")
    proxmox = connect_proxmox()

    nodes: List[Dict] = []
    used_ips: set[str] = set()
    cidr: Optional[str] = None

    if proxmox:
        print("Successfully connected to Proxmox API")
        vms = get_vms(proxmox)
        if not vms:
            print("No matching VMs found with required tags (k8s-server, k8s-worker, k8s-storage)")
        else:
            print(f"Found {len(vms)} matching VMs:")
            for vm in vms:
                print(f"  - {vm['name']} (ID: {vm['vmid']}, Node: {vm['node']}, Tags: {vm.get('tags', 'none')})")
            print()
            print("Processing VM details...")
            for vm in vms:
                node_name = vm["node"]
                vmid = vm["vmid"]
                name = vm["name"]
                tags = {
                    t.strip()
                    for t in (vm.get("tags") or "").split(",")
                    if t.strip()
                }

                ip, mac, prefix = vm_network_info(proxmox, node_name, vmid)

                # If we couldn't get MAC from guest agent, try config
                if not mac:
                    mac = vm_config_network_info(proxmox, node_name, vmid)

                disk = vm_disk_info(proxmox, node_name, vmid)

                if ip:
                    used_ips.add(ip)
                if ip and prefix and not cidr:
                    cidr = compute_cidr(ip, prefix)

                node_data = {
                    "name": name,
                    "address": ip or "",
                    "controller": "k8s-server" in tags,
                    "disk": disk or "/dev/sda",
                    "mac_addr": mac or "",
                    "schematic_id": schematic_id or os.environ.get("SCHEMATIC_ID", ""),
                }
                nodes.append(node_data)

                # Print status for debugging
                print(f"VM {name}: IP={ip or 'MISSING'}, MAC={mac or 'MISSING'}, Disk={disk or 'MISSING'}")

            print(f"\nSuccessfully processed {len(nodes)} nodes")
    else:
        print("Skipping VM discovery - no Proxmox connection")

    if nodes:
        print(f"\nWriting {len(nodes)} nodes to nodes.yaml")
        with open("nodes.yaml", "w") as f:
            yaml.safe_dump({"nodes": nodes}, f, sort_keys=False)
            print("nodes.yaml written successfully")
    else:
        print("No nodes to write to nodes.yaml")

    print("\nGenerating cluster configuration...")
    cluster_config: Dict[str, object] = {}
    if os.path.exists("cluster.sample.yaml"):
        print("Loading base configuration from cluster.sample.yaml")
        with open("cluster.sample.yaml") as f:
            cluster_config = yaml.safe_load(f) or {}
    else:
        print("cluster.sample.yaml not found, starting with empty configuration")

    def parse_list(val: Optional[str]) -> Optional[List[str]]:
        if not val:
            return None
        return [v.strip() for v in val.split(',') if v.strip()]

    node_cidr = node_cidr or os.environ.get("NODE_CIDR") or cidr
    if node_cidr:
        cluster_config["node_cidr"] = node_cidr
        print(f"Using node CIDR: {node_cidr}")
    else:
        print("Warning: No node CIDR specified")

    network = ipaddress.ip_network(node_cidr) if node_cidr else None

    dns = parse_list(node_dns_servers or os.environ.get("NODE_DNS_SERVERS"))
    if dns is not None:
        cluster_config["node_dns_servers"] = dns

    ntp = parse_list(node_ntp_servers or os.environ.get("NODE_NTP_SERVERS"))
    if ntp is not None:
        cluster_config["node_ntp_servers"] = ntp

    node_default_gateway_val = (
        node_default_gateway or os.environ.get("NODE_DEFAULT_GATEWAY")
    )
    if node_default_gateway_val:
        used_ips.add(node_default_gateway_val)
        cluster_config["node_default_gateway"] = node_default_gateway_val

    node_vlan_tag = node_vlan_tag or os.environ.get("NODE_VLAN_TAG")
    if node_vlan_tag:
        cluster_config["node_vlan_tag"] = node_vlan_tag

    def pick_unused_ip() -> Optional[str]:
        if not network:
            return None
        for ip in network.hosts():
            sip = str(ip)
            if sip not in used_ips:
                used_ips.add(sip)
                return sip
        return None

    cluster_api_addr = (
        cluster_api_addr
        or os.environ.get("CLUSTER_API_ADDR")
        or pick_unused_ip()
    )
    if cluster_api_addr:
        cluster_config["cluster_api_addr"] = cluster_api_addr

    cluster_api_tls_sans = parse_list(
        cluster_api_tls_sans or os.environ.get("CLUSTER_API_TLS_SANS")
    )
    if cluster_api_tls_sans:
        cluster_config["cluster_api_tls_sans"] = cluster_api_tls_sans

    cluster_pod_cidr_val = (
        cluster_pod_cidr or os.environ.get("CLUSTER_POD_CIDR")
    )
    if cluster_pod_cidr_val:
        cluster_config["cluster_pod_cidr"] = cluster_pod_cidr_val

    cluster_svc_cidr_val = (
        cluster_svc_cidr or os.environ.get("CLUSTER_SVC_CIDR")
    )
    if cluster_svc_cidr_val:
        cluster_config["cluster_svc_cidr"] = cluster_svc_cidr_val

    cluster_dns_gateway_addr = (
        cluster_dns_gateway_addr
        or os.environ.get("CLUSTER_DNS_GATEWAY_ADDR")
        or pick_unused_ip()
    )
    if cluster_dns_gateway_addr:
        cluster_config["cluster_dns_gateway_addr"] = cluster_dns_gateway_addr

    cluster_gateway_addr = (
        cluster_gateway_addr
        or os.environ.get("CLUSTER_GATEWAY_ADDR")
        or pick_unused_ip()
    )
    if cluster_gateway_addr:
        cluster_config["cluster_gateway_addr"] = cluster_gateway_addr

    repo = (
        repository_name
        or os.environ.get("REPOSITORY_NAME")
        or get_repo_name()
    )
    if repo:
        cluster_config["repository_name"] = repo

    branch = repository_branch or os.environ.get("REPOSITORY_BRANCH")
    if branch:
        cluster_config["repository_branch"] = branch

    visibility = (
        repository_visibility or os.environ.get("REPOSITORY_VISIBILITY")
    )
    if visibility:
        cluster_config["repository_visibility"] = visibility

    cloudflare_domain = (
        cloudflare_domain or os.environ.get("CLOUDFLARE_DOMAIN")
    )
    if cloudflare_domain:
        cluster_config["cloudflare_domain"] = cloudflare_domain

    cloudflare_token = (
        cloudflare_token or os.environ.get("CLOUDFLARE_TOKEN")
    )
    if cloudflare_token:
        cluster_config["cloudflare_token"] = cloudflare_token

    cloudflare_gateway_addr = (
        cloudflare_gateway_addr
        or os.environ.get("CLOUDFLARE_GATEWAY_ADDR")
        or pick_unused_ip()
    )
    if cloudflare_gateway_addr:
        cluster_config["cloudflare_gateway_addr"] = cloudflare_gateway_addr

    cilium_loadbalancer_mode_val = (
        cilium_loadbalancer_mode or os.environ.get("CILIUM_LOADBALANCER_MODE")
    )
    if cilium_loadbalancer_mode_val:
        cluster_config["cilium_loadbalancer_mode"] = cilium_loadbalancer_mode_val

    cilium_bgp_router_addr = (
        cilium_bgp_router_addr or os.environ.get("CILIUM_BGP_ROUTER_ADDR")
    )
    if cilium_bgp_router_addr:
        cluster_config["cilium_bgp_router_addr"] = cilium_bgp_router_addr

    cilium_bgp_router_asn = (
        cilium_bgp_router_asn or os.environ.get("CILIUM_BGP_ROUTER_ASN")
    )
    if cilium_bgp_router_asn:
        cluster_config["cilium_bgp_router_asn"] = cilium_bgp_router_asn

    cilium_bgp_node_asn = (
        cilium_bgp_node_asn or os.environ.get("CILIUM_BGP_NODE_ASN")
    )
    if cilium_bgp_node_asn:
        cluster_config["cilium_bgp_node_asn"] = cilium_bgp_node_asn

    with open("cluster.yaml", "w") as f:
        yaml.safe_dump(cluster_config, f, sort_keys=False)
        print("cluster.yaml written successfully")
        print(f"Cluster configuration contains {len(cluster_config)} settings")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate cluster.yaml and nodes.yaml"
    )
    parser.add_argument("--schematic-id")
    parser.add_argument("--node-cidr")
    parser.add_argument("--node-dns-servers")
    parser.add_argument("--node-ntp-servers")
    parser.add_argument("--node-default-gateway")
    parser.add_argument("--node-vlan-tag")
    parser.add_argument("--cluster-api-addr")
    parser.add_argument("--cluster-api-tls-sans")
    parser.add_argument("--cluster-pod-cidr")
    parser.add_argument("--cluster-svc-cidr")
    parser.add_argument("--cluster-dns-gateway-addr")
    parser.add_argument("--cluster-gateway-addr")
    parser.add_argument("--repository-name")
    parser.add_argument("--repository-branch")
    parser.add_argument("--repository-visibility")
    parser.add_argument("--cloudflare-domain")
    parser.add_argument("--cloudflare-token")
    parser.add_argument("--cloudflare-gateway-addr")
    parser.add_argument("--cilium-loadbalancer-mode")
    parser.add_argument("--cilium-bgp-router-addr")
    parser.add_argument("--cilium-bgp-router-asn")
    parser.add_argument("--cilium-bgp-node-asn")
    # if len(sys.argv) == 1:
    #     parser.print_help()
    #     sys.exit(0)

    args = parser.parse_args()

    generate(
        schematic_id=args.schematic_id,
        node_cidr=args.node_cidr,
        node_dns_servers=args.node_dns_servers,
        node_ntp_servers=args.node_ntp_servers,
        node_default_gateway=args.node_default_gateway,
        node_vlan_tag=args.node_vlan_tag,
        cluster_api_addr=args.cluster_api_addr,
        cluster_api_tls_sans=args.cluster_api_tls_sans,
        cluster_pod_cidr=args.cluster_pod_cidr,
        cluster_svc_cidr=args.cluster_svc_cidr,
        cluster_dns_gateway_addr=args.cluster_dns_gateway_addr,
        cluster_gateway_addr=args.cluster_gateway_addr,
        repository_name=args.repository_name,
        repository_branch=args.repository_branch,
        repository_visibility=args.repository_visibility,
        cloudflare_domain=args.cloudflare_domain,
        cloudflare_token=args.cloudflare_token,
        cloudflare_gateway_addr=args.cloudflare_gateway_addr,
        cilium_loadbalancer_mode=args.cilium_loadbalancer_mode,
        cilium_bgp_router_addr=args.cilium_bgp_router_addr,
        cilium_bgp_router_asn=args.cilium_bgp_router_asn,
        cilium_bgp_node_asn=args.cilium_bgp_node_asn,
    )
