#!/bin/dash
":"; exec /boot/emacs/bin/emacs --quick --script "$0" "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-

(require 'subr-x)

(setenv "PATH" "/bin")
(setenv "SHELL" "/bin/dash")

(setq exec-path '("/bin")
      shell-file-name "/bin/dash"
      debug-on-error nil)

;;HAAAACK and remember, internet is  definitely for fat people.

;; https://github.com/Sweets/hummingbird
;;https://felipec.wordpress.com/2013/11/04/init
;; https://gist.github.com/lunaryorn/91a7734a8c1d93a8d1b0d3f85fe18b1e

;; https://stackoverflow.com/questions/23299314/finding-the-exit-code-of-a-shell-command-in-elisp
(defun process-exit-code-and-output (program &rest args)
  "Run PROGRAM with ARGS and return the exit code and output in a list."
  (with-temp-buffer
    (list (apply 'call-process program nil (current-buffer) nil args)
          (buffer-string))))

(defun split-file (FILE delim)
  (with-temp-buffer
    (insert-file-contents FILE)
    (split-string (buffer-string) delim t)))

(defun emergency ()
  (start-process-shell-command "emacs" nil "exec /boot/emacs/bin/emacs"))

(message
 (concat "Welcome to KISS " (shell-command-to-string "uname -sr")))

(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "nosuid,noexec,nodev" "-t" "proc" "proc" "/proc"))

(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "nosuid,noexec,nodev" "-t" "sysfs" "sys" "/sys"))

(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "mode=0755,nosuid,nodev" "-t" "tmpfs" "run" "/run"))

;; already mounted
(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "mode=0755,nosuid" "-t" "devtmpfs" "dev" "/dev"))

(progn
  (make-directory "/run/lvm" t)
  (set-file-modes "/run" #o755)

  (make-directory "/run/user" t)
  (set-file-modes "/run/user" #o755)

  (make-directory "/run/lock" t)
  (set-file-modes "/run/lock" #o755)

  (make-directory "/run/log" t)
  (set-file-modes "/run/log" #o755)

  (make-directory "/run/pts" t)
  (set-file-modes "/run/pts" #o755)

  (make-directory "/run/shm" t)
  (set-file-modes "/run/shm" #o755))

;; fail
(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "mode=0620,gid=5,nosuid" "-nt" "devpts" "devpts" "/dev/pts"))

;; fail
(message "%s"
         (process-exit-code-and-output
          "ubase-box" "mount" "-o" "mode=0777,nosuid,nodev" "-nt" "tmpfs" "shm" "/dev/shm"))

(when (executable-find "udevd")
  (message "Starting eudev...")
  (message "%s"
           (process-exit-code-and-output
            "udevd" "--daemon"))
  (message "%s"
           (process-exit-code-and-output
            "udevadm" "trigger" "--action=add" "--type=subsystems"))
  (message "%s"
           (process-exit-code-and-output
            "udevadm" "trigger" "--action=add" "--type=devices"))
  (message "%s"
           (process-exit-code-and-output
            "udevadm" "settle")))

(progn
  (message "Remounting rootfs as ro...")
  (or (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "remount,ro" "/"))
      (emergency)))

(progn
  (message "Checking filesystems...")
  (or (eq 0 (call-process "fsck" nil nil nil "-ATat" "noopts=_netdev"))
      (emergency)))

(progn
  (message "Remounting rootfs as rw...")
  (or (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-o" "remount,rw" "/"))
      (emergency)))

(progn
  (message "Mounting all local filesystems...")
  (or (message "%s"
               (process-exit-code-and-output
                "ubase-box" "mount" "-a"))
      (emergency)))

(progn
  (message "Seeding random...")
  (if (file-exists-p "/var/random.seed")
      (start-process-shell-command "cat" nil "cat /var/random.seed > /dev/urandom")
    (and
     (message "This may hang. Mash the keyboard to generate entropy...")
     (message "%s"
              (process-exit-code-and-output "dd" "count=1" "bs=512" "if=/dev/random" "of=/var/random.seed")))))

(progn
  (message "Setting up loopback...")
  (message "%s"
           (process-exit-code-and-output "ip" "link" "set" "up" "dev" "lo")))

(shell-command-to-string "grep /etc/")

(progn
  (message "Setting hostname...")
  (or
   (and
    (setq hostname
          (and (file-exists-p "/etc/hostname")
               (string-trim (format "%s" (split-file "/etc/hostname" "\n")) "(" ")")))
    (message "%s"
             (shell-command (concat "echo " hostname " > /proc/sys/kernel/hostname"))))
   (message "%s"
            (shell-command "echo KISS > /proc/sys/kernel/hostname"))))

(when (file-exists-p "/etc/sysctl.conf")
  (message "Loading sysctl settings...")
  (message "%s"
           (process-exit-code-and-output "sysctl" "-p" "/etc/sysctl.conf")))

(when (executable-find "udevd")
  (message "exit udev")
  (message "%s"
           (process-exit-code-and-output "udevadm" "control" "--exit")))

(progn
  (message "Storing dmesg output to /var/log...")
  (start-process-shell-command "dmesg" nil "dmesg > /var/log/dmesg.log"))

(message "Boot stage complete...")

;; buggy job control (figure out proper forking /exec)
(start-process-shell-command "getty" nil "exec sh -c 'ubase-box respawn /sbin/getty 38400 tty1' &>/dev/null &")
(start-process-shell-command "getty" nil "exec sh -c 'ubase-box respawn /sbin/getty 38400 tty2' &>/dev/null &")

;; (async-shell-command "ubase-box respawn ubase-box getty /dev/tty2 linux")
;; (async-shell-command "ubase-box respawn ubase-box getty /dev/tty3 linux")
;; (async-shell-command "ubase-box respawn ubase-box getty /dev/tty4 linux")
;; (async-shell-command "ubase-box respawn ubase-box getty /dev/tty5 linux")
;; (async-shell-command "ubase-box respawn ubase-box getty /dev/tty6 linux")

;; runsvdir can't open supverise/lock ??????
(start-process-shell-command "sh" nil "sh -c 'exec ubase-box respawn /usr/bin/runsvdir -P /var/service' &")

(and
 (message "\(Richard Stallman --out o/\)")
 (kill-emacs 0))
p
