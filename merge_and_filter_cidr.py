import ipaddress
import sys

def read_cidr_from_file(filename):
    """Read CIDR list from file"""
    with open(filename, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def write_cidr_to_file(filename, cidr_list):
    """Write CIDR list to file"""
    sorted_cidr = sorted(cidr_list, key=lambda x: ipaddress.ip_network(x).network_address)
    with open(filename, 'w') as f:
        f.write('\n'.join(sorted_cidr) + '\n')

def filter_redundant_cidr(cidr_list):
    """Filter out CIDRs that are covered by larger ranges"""
    # Convert CIDRs to ip_network objects and sort (from small to large)
    networks = sorted([ipaddress.ip_network(cidr) for cidr in cidr_list], key=lambda x: x.prefixlen)
    
    # Filter out covered CIDRs
    filtered_networks = []
    removed_cidrs = []  # Record removed smaller CIDRs
    for network in networks:
        # Check if covered by existing networks
        is_redundant = any(network.subnet_of(existing) for existing in filtered_networks)
        if is_redundant:
            removed_cidrs.append(str(network))
        else:
            filtered_networks.append(network)
    
    # Convert back to CIDR strings
    return [str(network) for network in filtered_networks], removed_cidrs

def main():
    # Check command line arguments
    if len(sys.argv) != 5:
        print("Usage: python3 merge_and_filter_cidr.py ipv4_file1.txt ipv4_file2.txt ipv6_file1.txt ipv6_file2.txt")
        sys.exit(1)
    
    # Get file paths
    ipv4_file1, ipv4_file2, ipv6_file1, ipv6_file2 = sys.argv[1:5]
    
    # Process IPv4 files
    ipv4_cidr = read_cidr_from_file(ipv4_file1) + read_cidr_from_file(ipv4_file2)
    ipv4_unique = list(set(ipv4_cidr))
    ipv4_filtered, ipv4_removed = filter_redundant_cidr(ipv4_unique)
    
    # Process IPv6 files
    ipv6_cidr = read_cidr_from_file(ipv6_file1) + read_cidr_from_file(ipv6_file2)
    ipv6_unique = list(set(ipv6_cidr))
    ipv6_filtered, ipv6_removed = filter_redundant_cidr(ipv6_unique)
    
    # Write output files
    write_cidr_to_file("merged_ipv4.txt", ipv4_filtered)
    write_cidr_to_file("merged_ipv6.txt", ipv6_filtered)
    
    # # Output removed CIDRs
    # if ipv4_removed:
    #     print("\nFollowing IPv4 CIDRs were removed as they are covered by larger ranges:")
    #     for cidr in ipv4_removed:
    #         print(f"- {cidr}")
    # else:
    #     print("\nNo IPv4 CIDRs were removed")
    
    # if ipv6_removed:
    #     print("\nFollowing IPv6 CIDRs were removed as they are covered by larger ranges:")
    #     for cidr in ipv6_removed:
    #         print(f"- {cidr}")
    # else:
    #     print("\nNo IPv6 CIDRs were removed")
if __name__ == "__main__":
    main()