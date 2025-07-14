# #1. WIREGUARD INTERFACE SETUP

/interface wireguard add \
    name=wg-amnezia \
    private-key="YOUR_PRIVATE_KEY"              # WireGuard client private key
    listen-port=45323 \
    mtu=1376

/ip address add \
    address=YOUR_LOCAL_WG_IP/32                  # For example: 10.8.1.2
    interface=wg-amnezia

# #2. PEER (VPN SERVER) CONFIGURATION

/interface wireguard peers add \
    interface=wg-amnezia \
    public-key="SERVER_PUBLIC_KEY"               # WireGuard server public key
    preshared-key="PRESHARED_KEY"                # Pre-shared key
    endpoint-address=SERVER_IP_ADDRESS            # For example: 123.123.12.11
    endpoint-port=45323 \
    allowed-address=VPN_SITES_IP_LIST             # IPs to route through VPN
    persistent-keepalive=25

# #3. LIST OF IPs TO ROUTE THROUGH VPN

/ip firewall address-list
add list=VPN_SITES address=SITE_IP_1            # For example: 199.223.232.0/21
add list=VPN_SITES address=SITE_IP_2
add list=VPN_SITES address=SITE_IP_3
# Add required IP ranges here

# #4. ROUTES THROUGH VPN

/ip route
add dst-address=SITE_IP_1 gateway=wg-amnezia
add dst-address=SITE_IP_2 gateway=wg-amnezia
add dst-address=SITE_IP_3 gateway=wg-amnezia
# Repeat for all IPs in VPN_SITES list

# #5. EXCLUDE VPN SERVER FROM VPN ROUTING

/ip route
add dst-address=SERVER_IP_ADDRESS gateway=LOCAL_GATEWAY \
    comment="VPN server direct route"
# LOCAL_GATEWAY — your regular internet gateway, e.g., 192.168.88.1

# #6. NAT (MASQUERADE) FOR VPN TRAFFIC

/ip firewall nat
add chain=srcnat out-interface=wg-amnezia action=masquerade

# #7. DNS AND LEAK PROTECTION

/ip dns set servers=1.1.1.1,1.0.0.1 allow-remote-requests=yes
/ip firewall nat add chain=dstnat protocol=udp dst-port=53 action=redirect to-ports=53

# #8. LEAK PROTECTION — ACCESS TO VPN_SITES ONLY THROUGH VPN

# Allow traffic to VPN sites only via VPN tunnel:

/ip firewall filter add \
    chain=forward \
    src-address=YOUR_LOCAL_IP \
    dst-address-list=VPN_SITES \
    action=accept \
    comment="Allow VPN traffic to specified sites"

/ip firewall filter add \
    chain=forward \
    src-address=YOUR_LOCAL_IP \
    dst-address-list=VPN_SITES \
    action=drop \
    comment="Block non-VPN access to these sites"
