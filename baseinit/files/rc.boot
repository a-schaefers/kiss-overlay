#!/bin/dash

. /usr/lib/init/rc.lib

PATH=/usr/local/bin:/usr/bin:/usr/sbin
old_ifs=$IFS

log "Welcome to KISS $(uname -sr)!"

log "Mounting pseudo filesystems..."; {
    mnt /proc -o nosuid,noexec,nodev    -t proc     proc
    mnt /sys  -o nosuid,noexec,nodev    -t sysfs    sys
    mnt /run  -o mode=0755,nosuid,nodev -t tmpfs    run
    mnt /dev  -o mode=0755,nosuid       -t devtmpfs dev

    # shellcheck disable=2174
    mkdir -pm 0755 /run/runit \
                   /run/lvm   \
                   /run/user  \
                   /run/lock  \
                   /run/log   \
                   /dev/pts   \
                   /dev/shm

    mnt /dev/pts -o mode=0620,gid=5,nosuid,noexec -nt devpts devpts
    mnt /dev/shm -o mode=1777,nosuid,nodev        -nt tmpfs  shm
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

log "Starting eudev..."; {
    command -v udevd >/dev/null && {
        udevd --daemon
        udevadm trigger --action=add --type=subsystems
        udevadm trigger --action=add --type=devices
        udevadm trigger --action=change --type=devices
        udevadm settle
    }
}

log "Remounting rootfs as ro..."; {
    mount -o remount,ro / || emergency_shell
}

log "Checking filesystems..."; {
    fsck -ATat noopts=_netdev
    [ $? -gt 1 ] && emergency_shell
}

log "Mounting rootfs rw..."; {
    mount -o remount,rw / || emergency_shell
}

log "Mounting all local filesystems..."; {
    mount -a || emergency_shell
}

log "Loading rc.conf settings..."; {
    [ -f /etc/rc.conf ] && . /etc/rc.conf
}

log "Setting up loopback..."; {
    ip link set up dev lo
}

log "Setting hostname..."; {
    read -r hostname < /etc/hostname
    printf '%s\n' "${hostname:-KISS}" > /proc/sys/kernel/hostname
} 2>/dev/null

log "Running rc.d hooks..."; {
    for file in /etc/rc.d/*.boot; do
        [ -f "$file" ] && . "$file"
    done
}

log "Boot stage complete..."
