#!/bin/dash
":"; exec /boot/emacs/bin/emacs --quick --script "$0" "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-

;; This was helpful - https://gist.github.com/lunaryorn/91a7734a8c1d93a8d1b0d3f85fe18b1e

(setenv "PATH" "/bin")
(setenv "SHELL" "/bin/dash")
(setq exec-path '("/bin")
      shell-file-name "/bin/dash"
      debug-on-error t)

;;HAAAACK and remember, internet is  definitely for fat people.

;;https://felipec.wordpress.com/2013/11/04/init

(defun emergency ()
  (start-process-shell-command "emacs" nil "exec /boot/emacs/bin/emacs"))

;; https://stackoverflow.com/questions/23299314/finding-the-exit-code-of-a-shell-command-in-elisp
(defun process-exit-code-and-output (program &rest args)
  "Run PROGRAM with ARGS and return the exit code and output in a list."
  (with-temp-buffer
    (list (apply 'call-process program nil (current-buffer) nil args)
          (buffer-string))))

(message
 (concat "Welcome to KISS " (shell-command-to-string "uname -sr")))

(or (and
     (eq 0 (call-process "mountpoint" nil nil nil "-q" "/proc"))
     (message "/proc is already mounted"))
    (progn
      (message "mounting /proc...")
      (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "nosuid,noexec,nodev" "-t" "proc" "proc" "/proc"))))

(or (and
     (eq 0 (call-process "mountpoint" nil nil nil "-q" "/sys"))
     (message "/sys is already mounted"))
    (progn
      (message "mounting /sys...")
      (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "nosuid,noexec,nodev" "-t" "sysfs" "sys" "/sys"))))

(or (and
     (eq 0 (call-process "mountpoint" nil nil nil "-q" "/run"))
     (message "/run is already mounted"))
    (progn
      (message "mounting /run...")
      (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "mode=0755,nosuid,nodev" "-t" "tmpfs" "run" "/run"))))

(or (and
     (eq 0 (call-process "mountpoint" nil nil nil "-q" "/dev"))
     (message "/dev is already mounted"))
    (progn
      (message "mounting /dev...")
      (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "mode=0755,nosuid" "-t" "devtmpfs" "dev" "/dev"))))



(and
 (message "\(Richard Stallman --out o/\)")
 (kill-emacs 0))

;; TODO

;;              # shellcheck disable=2174
;;              mkdir -pm 0755 /run/runit \
;;              /run/lvm   \
;;              /run/user  \
;;              /run/lock  \
;;              /run/log   \
;;              /dev/pts   \
;;              /dev/shm

;;              mnt /dev/pts -o mode=0620,gid=5,nosuid,noexec -nt devpts     devpts
;;              mnt /dev/shm -o mode=1777,nosuid,nodev        -nt tmpfs      shm
;;              }

;;              log "Starting eudev..."; {
;;              command -v udevd >/dev/null && {
;;              udevd --daemon
;;              udevadm trigger --action=add --type=subsystems
;;              udevadm trigger --action=add --type=devices
;;              udevadm settle
;;              }
;;              }

;;              log "Remounting rootfs as ro..."; {
;;              ubase-box mount -o remount,ro / || emergency_shell
;;              }

;;              log "Activating encrypted devices (if any exist)..."; {
;;              [ -e /etc/crypttab ] && [ -x /bin/cryptsetup ] && {
;;              exec 3<&0

;;              # shellcheck disable=2086
;;              while read -r name dev pass opts err; do
;;              # Skip comments.
;;              [ "${name##\#*}" ] || continue

;;              # Break on invalid crypttab.
;;              [ "$err" ] && {
;;              printf 'error: A valid crypttab has only 4 columns.\n'
;;              break
;;              }

;;              # Turn 'UUID=*' lines into device names.
;;              [ "${dev##UUID*}" ] || dev=$(blkid -l -o device -t "$dev")

;;              # Parse options by turning list into a pseudo array.
;;              IFS=,
;;              set -- $opts
;;              IFS=$old_ifs

;;              copts="cryptsetup luksOpen"

;;              # Create an argument list (no other way to do this in sh).
;;              for opt; do case $opt in
;;              discard)            copts="$copts --allow-discards" ;;
;; readonly|read-only) copts="$copts -r" ;;
;; tries=*)            copts="$copts -T ${opt##*=}" ;;
;; esac; done

;; # If password is 'none', '-' or empty ask for it.
;; case $pass in
;; none|-|"") $copts "$dev" "$name" <&3 ;;
;; *)         $copts -d "$pass" "$dev" "$name" ;;
;; esac
;; done < /etc/crypttab

;; exec 3>&-

;; [ "$copts" ] && [ -x /bin/vgchance ] && {
;; log "Activating LVM devices for dm-crypt..."
;; vgchange --sysinit -a y || emergency_shell
;; }
;; }
;; }

;; log "Checking filesystems..."; {
;; fsck -ATat noopts=_netdev
;; [ $? -gt 1 ] && emergency_shell
;; }

;; log "Mounting rootfs rw..."; {
;; ubase-box mount -o remount,rw / || emergency_shell
;; }

;; log "Mounting all local filesystems..."; {
;; ubase-box mount -a || emergency_shell
;; }

;; log "Enabling swap..."; {
;; swapon -a || emergency_shell
;; }

;; log "Seeding random..."; {
;; if [ -f /var/random.seed ]; then
;; cat /var/random.seed > /dev/urandom
;; else
;; log "This may hang."
;; log "Mash the keyboard to generate entropy..."

;; dd count=1 bs=512 if=/dev/random of=/var/random.seed
;; fi
;; }

;; log "Setting up loopback..."; {
;; ip link set up dev lo
;; }

;; log "Setting hostname..."; {
;; read -r hostname < /etc/hostname
;; printf '%s\n' "${hostname:-KISS}" > /proc/sys/kernel/hostname
;; } 2>/dev/null

;; log "Loading sysctl settings..."; {
;; find /run/sysctl.d \
;; /etc/sysctl.d \
;; /usr/local/lib/sysctl.d \
;; /usr/lib/sysctl.d \
;; /lib/sysctl.d \
;; /etc/sysctl.conf \
;; -name \*.conf -type f 2>/dev/null \
;; | while read -r conf; do
;; seen="$seen ${conf##*/}"

;; case $seen in
;; *" ${conf##*/} "*) ;;
;; *) printf '%s\n' "* Applying $conf ..."
;; sysctl -p "$conf" ;;
;; esac
;; done
;; }

;; command -v udevd >/dev/null &&
;; udevadm control --exit

;; log "Storing dmesg output to /var/log/dmesg.log"; {
;; dmesg > /var/log/dmesg.log
;; }

;; log "Boot stage complete..."

;; sh -c 'ubase-box respawn ubase-box getty /dev/tty1 linux' &>/dev/null &
;; sh -c 'ubase-box respawn ubase-box getty /dev/tty2 linux' &>/dev/null &
;; sh -c 'ubase-box respawn ubase-box getty /dev/tty3 linux' &>/dev/null &
;; sh -c 'ubase-box respawn ubase-box getty /dev/tty4 linux' &>/dev/null &
;; sh -c 'ubase-box respawn ubase-box getty /dev/tty5 linux' &>/dev/null &
;; sh -c 'ubase-box respawn ubase-box getty /dev/tty6 linux' &>/dev/null &

;; # optionally use a different service supervisor than busybox runit
;; [ -f "/etc/rc.supervisor"] && . /etc/rc.supervisor && exit 0
;; sh -c 'ubase-box respawn /usr/bin/runsvdir -P /var/service' &
;; }

;; main
