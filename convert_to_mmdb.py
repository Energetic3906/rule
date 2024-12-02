import sys
from netaddr import IPSet, IPNetwork
from mmdb_writer import MMDBWriter

def convert_to_mmdb(input_file, output_file):
    # Create an MMDB writer with IPv6 compatibility
    writer = MMDBWriter(ip_version=6, ipv4_compatible=True)

    with open(input_file, 'r') as csvfile:
        for line in csvfile:
            ip_range = line.strip()  # Remove any leading/trailing whitespace
            
            if not ip_range:  # Skip empty lines
                continue
            
            try:
                network = IPNetwork(ip_range)
                
                # Define the record structure according to the specified format
                record = {
                    'country': {
                        'geoname_id': 1814991,  # Geoname ID for China
                        'is_in_european_union': False,
                        'iso_code': 'CN',
                        'names': {
                            'de': 'China',
                            'en': 'China',
                            'es': 'China',
                            'fr': 'Chine',
                            'ja': '中国',
                            'pt-BR': 'China',
                            'ru': 'Китай',
                            'zh-CN': '中国'
                        }
                    }
                }
                
                # Insert the network into the MMDB writer
                writer.insert_network(IPSet([ip_range]), record)
                
            except Exception as e:
                print(f"Error processing {ip_range}: {e}")

    # Save the MMDB file
    writer.to_db_file(output_file)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_to_mmdb.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    convert_to_mmdb(input_file, output_file)
