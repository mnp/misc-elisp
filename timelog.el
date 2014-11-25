;; -*- Lisp -*-

;; timelog.el - Time logging utility, for grokking to timesheet etc
;;
;; INSTALLING
;; Load or autoload in your .emacs file. Set values of then
;; customizable vars, below, after the load line. 
;;  
;; USAGE 
;; The main call is timelog-entry, called interactively, which you'll
;; want to bind to a key for convenience.  After calling that, you're
;; prompted for hours, then a freeform blurb may be entered.
;; timelog-save (defaults to C-c C-c) will save the entry to your
;; ~/.timelog file, or timelog-cancel (C-c C-k) won't.  The .timelog
;; file has a semiparseable format.  Sexpr or json would be better.
;;
;; TODO
;; Report generation - timesheet, status reports.
;; More UI thought - what data to track?
;;
;; Created Wed Jul 31 10:47:36 1991 mitch@mira
;; Lifted from the tomb 2014 mitchell.perilstein@gmail.com
;;
;; Copyright (C) 2014 Mitchell Perilstein
;; Licensed under GNU LGPL Version 3.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  User customizable vars. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar timelog-sinks '((941000 "RD/VLK")
			(610401 "HLS/UI")
			(0611   "Comp Sys Mgmnt")
			(950900 "ET/VLK")
			(960800 "MT/VLK")
			(0710   "Administration")
			(0243   "Vacation"))
  "*Time usage categories, list of (acct_number name). Users should copy this
to their .emacs and re-order it for their convenience.")

(defvar timelog-file (expand-file-name "~/.timelog")
  "*User's private time log file.")

(defvar timelog-user (user-full-name) 
  "*User's timesheet name.")

(defvar timelog-user-number (user-uid) 
  "*User's timesheet number.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Internal vars.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar timelog-account nil)
(defvar timelog-account-buffer nil)
(defvar timelog-hours "")

(defvar timelog-edit-map ())
(if timelog-edit-map
    ()
  (setq timelog-edit-map (make-keymap))
  (define-key timelog-edit-map "\C-c\C-k" 'timelog-cancel)
  (define-key timelog-edit-map "\C-c\C-c" 'timelog-save))

(defvar timelog-menu-map ())
(if timelog-menu-map
    ()
  (setq timelog-menu-map (make-keymap))
  (define-key timelog-menu-map "\C-n" 'timelog-next)
  (define-key timelog-menu-map "n" 'timelog-next)
  (define-key timelog-menu-map "\C-p" 'timelog-prev)
  (define-key timelog-menu-map "p" 'timelog-prev)
  (define-key timelog-menu-map "\C-m" 'timelog-select)
  (define-key timelog-menu-map " " 'timelog-select))

(defun timelog-save ()
  (interactive)
  (message "Saving...")
  (goto-char (point-min))
  (insert 10 12 10) ; ^L^M
  (append-to-file (point-min) (point-max) timelog-file)
  (kill-buffer (buffer-name)))

(defun timelog-cancel ()
  (interactive)
  (kill-buffer (buffer-name)))

(defun timelog-next ()
  (interactive)
  (next-line 1))

(defun timelog-prev ()
  (interactive)
  (previous-line 1))

(defun timelog-select ()
  (interactive)
  (beginning-of-line 1)
  (setq timelog-account (read timelog-account-buf))
  (kill-buffer timelog-account-buf)
  (if timelog-account
      (let* ((outbuf (get-buffer-create "*Timelog*"))
	     (acc (assoc timelog-account timelog-sinks))
	     (accname (car (cdr acc)))
	     (accnum (car acc)))
	(switch-to-buffer outbuf)
	(erase-buffer)
	(insert (format "(%d %c%s%c %s %dhs)\n---\n" 
			 accnum
			 ?" accname ?"
			 (current-time-string)
			timelog-hours))
	(kill-all-local-variables)
	(use-local-map timelog-edit-map)
	(setq major-mode 'Timelog-edit)
	(setq mode-name "Timelog Edit")
	(message "Editing %s. ^C^C:save ^C^K:cancel" accname))
    (message "You must pick an account.")))

(defun timelog-entry (hours)
  (interactive "nHours: ")
  (setq timelog-hours hours
	timelog-account nil)
  (timelog-account-menu))

(defun timelog-account-menu nil
  (interactive)
  (setq timelog-account-buf (get-buffer-create "*accounts*"))
  (pop-to-buffer timelog-account-buf)
  (mapcar '(lambda (x)
	     (insert (format "%d\t\t%s\n" (car x) (car (cdr x)))))
	  timelog-sinks)
  (goto-char (point-min))
  (kill-all-local-variables)
  (use-local-map timelog-menu-map)
  (setq buffer-read-only t)
  (setq major-mode 'Account-menu)
  (setq mode-name "Account Menu")
  (message "Choose an account. SPC:select  N:next  P:prev"))
