#!/bin/dash
":"; exec /boot/emacs/bin/emacs --quick --script "$0" "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-

;; This was helpful - https://gist.github.com/lunaryorn/91a7734a8c1d93a8d1b0d3f85fe18b1e

(setenv "PATH" "/bin")
(setq exec-path '("/bin"))
(setq debug-on-error t)

;;HAAAACK








;; Richard Stallman --out o/
(kill-emacs 0)
