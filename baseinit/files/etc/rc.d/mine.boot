# "services"
# wpa_supplicant -B -i wlp2s0 -c /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1 &
# dhcpcd -BM &

# respawn setsid /sbin/agetty 38400 tty1 linux --autologin foo --noclear &
# respawn setsid /sbin/agetty 38400 tty2 linux --autologin root --noclear &
