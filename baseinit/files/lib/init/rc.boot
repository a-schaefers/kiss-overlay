#!/bin/sh

. /usr/lib/init/rc.lib

log "Mounting pseudo filesystems..."; {
    mnt /proc -o nosuid,noexec,nodev    -t proc     proc
    mnt /sys  -o nosuid,noexec,nodev    -t sysfs    sys
    mnt /run  -o mode=0755,nosuid,nodev -t tmpfs    run
    mnt /dev  -o mode=0755,nosuid       -t devtmpfs dev

    mkdir \
        -pm 0755 \
        /run/runit \
        /run/lvm   \
        /run/user  \
        /run/lock  \
        /run/log   \
        /dev/pts   \
        /dev/shm

    mnt /dev/pts -o mode=0620,gid=5,nosuid,noexec -nt devpts devpts
    mnt /dev/shm -o mode=1777,nosuid,nodev        -nt tmpfs  shm
}

log "Starting udev..."; {
    udevd -d
    udevadm trigger -c add    -t subsystems
    udevadm trigger -c add    -t devices
    udevadm trigger -c change -t devices
    udevadm settle
}

log "Remounting rootfs as ro..."; {
    mount -o remount,ro / || sos
}

log "Loading rc.conf settings..."; {
    [ -f /etc/rc.conf ] && . /etc/rc.conf
}

log "Checking filesystems..."; {
    fsck -ATat noopts=_netdev

    # It can't be assumed that success is 0
    # and failure is > 0.
    [ $? -gt 1 ] && sos
}

log "Mounting rootfs rw..."; {
    mount -o remount,rw / || sos
}

log "Mounting all local filesystems..."; {
    mount -a || sos
}

log "Seeding random..."; {
    if [ -f /var/random.seed ]; then
        cat /var/random.seed > /dev/urandom
    else
        log "This may hang."
        log "Mash the keyboard to generate entropy..."

        dd count=1 bs=512 if=/dev/random of=/var/random.seed
    fi
}

log "Setting up loopback..."; {
    ip link set up dev lo
}

log "Setting hostname..."; {
    read -r hostname < /etc/hostname
    printf %s "${hostname:-KISS}" > /proc/sys/kernel/hostname
} 2>/dev/null


log "Running rc.d hooks..."; {
    for file in /etc/rc.d/*.boot; do
        [ -f "$file" ] && . "$file"
    done
}
