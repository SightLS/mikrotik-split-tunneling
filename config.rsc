# #1. НАСТРОЙКА ИНТЕРФЕЙСА WIREGUARD

/interface wireguard add \
    name=wg-amnezia \
    private-key="ВАШ_ПРИВАТНЫЙ_КЛЮЧ"           # Приватный ключ клиента WireGuard
    listen-port=45323 \
    mtu=1376

/ip address add \
    address=ВАШ_ЛОКАЛЬНЫЙ_WG_IP/32             # Например: 10.8.1.2
    interface=wg-amnezia

# #2. НАСТРОЙКА ПИРА (VPN-СЕРВЕРА)

/interface wireguard peers add \
    interface=wg-amnezia \
    public-key="ПУБЛИЧНЫЙ_КЛЮЧ_СЕРВЕРА"        # Публичный ключ WireGuard-сервера
    preshared-key="PRESHARED_КЛЮЧ"             # Предварительно согласованный ключ
    endpoint-address=IP_АДРЕС_СЕРВЕРА          # Например: 123.123.12.11
    endpoint-port=45323 \
    allowed-address=СПИСОК_IP_САЙТОВ_ЧЕРЕЗ_VPN # IP, которые будут маршрутизироваться через VPN
    persistent-keepalive=25

# #3. СПИСОК IP САЙТОВ, ТРАФИК К КОТОРЫМ ДОЛЖЕН ИДТИ ЧЕРЕЗ VPN

/ip firewall address-list
add list=VPN_SITES address=IP_САЙТА_1          # Например: 199.223.232.0/21
add list=VPN_SITES address=IP_САЙТА_2
add list=VPN_SITES address=IP_САЙТА_3
# Добавьте нужные диапазоны IP

# #4. МАРШРУТЫ ЧЕРЕЗ VPN

/ip route
add dst-address=IP_САЙТА_1 gateway=wg-amnezia
add dst-address=IP_САЙТА_2 gateway=wg-amnezia
add dst-address=IP_САЙТА_3 gateway=wg-amnezia
# Повторите для всех IP из списка VPN_SITES

# #5. ИСКЛЮЧЕНИЕ VPN-СЕРВЕРА ИЗ VPN-МАРШРУТИЗАЦИИ

/ip route
add dst-address=IP_АДРЕС_СЕРВЕРА gateway=ЛОКАЛЬНЫЙ_ШЛЮЗ \
    comment="VPN server direct route"
# ЛОКАЛЬНЫЙ_ШЛЮЗ — ваш обычный интернет-шлюз, например: 192.168.88.1

# #6. NAT (МАСКАРАДИНГ) ДЛЯ VPN-ТРАФИКА

/ip firewall nat
add chain=srcnat out-interface=wg-amnezia action=masquerade

# #7. DNS И ЗАЩИТА ОТ УТЕЧЕК

/ip dns set servers=1.1.1.1,1.0.0.1 allow-remote-requests=yes
/ip firewall nat add chain=dstnat protocol=udp dst-port=53 action=redirect to-ports=53

# #8. ЗАЩИТА ОТ УТЕЧЕК — ДОСТУП К IP ИЗ VPN_SITES ТОЛЬКО ЧЕРЕЗ VPN

# Разрешаем доступ к VPN-сайтам только через туннель:

/ip firewall filter add \
    chain=forward \
    src-address=ВАШ_ЛОКАЛЬНЫЙ_IP \
    dst-address-list=VPN_SITES \
    action=accept \
    comment="Разрешить VPN-трафик к нужным сайтам"

/ip firewall filter add \
    chain=forward \
    src-address=ВАШ_ЛОКАЛЬНЫЙ_IP \
    dst-address-list=VPN_SITES \
    action=drop \
    comment="Запретить не-VPN доступ к этим сайтам"
