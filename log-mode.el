;;; log-mode.el --- Mode for viewing RFC 5424 logfiles -*- lexical-binding:t -*-

;; Copyright (C) 2026 FanoPlanes

;; Author: FanoPlanes <fanoplanes@tilde.team>
;; Package-Requires: ((emacs "24.3"))
;; Version: 0.1
;; Keywords: faces, convenience
;; URL: https://github.com/fanoplanes/log-mode
;; Created: 2026-06-15

;;  This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option) any
;; later version.
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Fundamental or Text mode isn't really useful for viewing
;; logfiles I set up basic syntax highlighting to push parts of header to the
;; background, highlight date, time, process name, errors and kernel messages.
;; I detect the length of prefix (HEADER and STRUCTURED-DATA from RFC 5424
;; https://www.rfc-editor.org/info/rfc5424/#section-6) and dynamically set up
;; the `wrap-prefix' variable to line up the `MSG' section properly.

;;; Code:

;;; Add ourselves to the auto-mode-alist asap.
;;;###autoload
(add-to-list 'auto-mode-alist '("/var/log" . log-mode) t)

(defvar log-mode-default-prefix-length
  42
  "Define prefix length if the prefix length detection mechanism fails.")

(defun log-mode--find-prefix-length (beg end)
  "Find length of the message prefix.
Given BEG and END, search using regex and return `wrap-prefix'.
Restore position of point after the fact."
  (let ((position (point)))
    (goto-char beg)
    (let ((found (or (re-search-forward
		      "^[^[:blank:]]+ [^[:blank:]]+ [^[:blank:]]+ "
		      end)
		     log-mode-default-prefix-length)))
      (goto-char position)
      (make-string (- found beg) #x20))))

(defun log-mode--get-prefix ()
  "Upon opening a buffer, `point' is in a general position.
Find start and end of line and call `log-mode--find-prefix-length' to return
`wrap-prefix'. Restore point position."
  (let ((position (point)))
    (forward-line 0)
    (let* ((beg (point))
           (end (progn (search-forward "\n") (point))))
      (goto-char position)
      (log-mode--find-prefix-length beg end))))

(defun log-mode-prefix-function (beg end)
  "Indent the region between BEG and END with visual filling."
  ;; Any change at the beginning of a line might change its wrap
  ;; prefix, which affects the whole line.  So we need to "round-up"
  ;; `end' to the nearest end of line.  We do the same with `beg'
  ;; although it's probably not needed.
  (goto-char end)
  (unless (bolp) (forward-line 1))
  (setq end (point))
  (goto-char beg)
  (forward-line 0)
  (setq beg (point))
  (while (< (point) end)
    (let ((lbp (point)))
      (put-text-property
       (point) (progn (search-forward "\n" end 'move) (point))
       'wrap-prefix
       (let ((pfx (log-mode--find-prefix-length
		   lbp (point))))
	 ;; Remove any `wrap-prefix' property that might have been
	 ;; added earlier.  Otherwise, we end up with a string
	 ;; containing a `wrap-prefix' string containing a
	 ;; `wrap-prefix' string ...
	 (remove-text-properties
	  0 (length pfx) '(wrap-prefix) pfx)
         (let ((dp (get-text-property 0 'display pfx)))
           (when (and dp (eq dp (get-text-property (1- lbp) 'display)))
             ;; There's a `display' property which covers not just the
             ;; prefix but also the previous newline.  So it's not
             ;; just making the prefix more pretty and could interfere
             ;; or even defeat our efforts (e.g. it comes from
             ;; `adaptive-fill-mode').
             (remove-text-properties
	      0 (length pfx) '(display) pfx)))
	 pfx))))
  `(jit-lock-bounds ,beg . ,end))

(defgroup log-mode-faces nil
  "Faces for log-mode."
  :group 'faces)

(defface log-mode-date-face
  '((t :inherit default
     :foreground "green"))
  "Face for displaying the date in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-T-face
  '((t :inherit default
     :foreground "white"))
  "Face for displaying the ISO 8601 \\'T\\' in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-time-face
  '((t :inherit default
     :foreground "gold"))
  "Face for displaying the time in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-microsecond-face
  '((t :inherit default
     :foreground "dark gray"))
  "Face for displaying microseconds in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-timezone-face
  '((t :inherit default
     :foreground "dim gray"))
  "Face for displaying timezone offsets in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-hostname-face
  '((t :inherit default
     :foreground "dark gray"))
  "Face for displaying the hostname in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-procid-face
  '((t :inherit default
     :foreground "red"))
  "Face for displaying the process ID in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-error-face
  '((t :inherit default
     :foreground "red"
     :inverse-video t
     :weight bold))
  "Face for displaying error messages in RFC 5424 log entries."
  :group 'log-mode-faces)

(defface log-mode-kernel-face
  '((t :inherit default
     :foreground "red"))
  "Face for displaying kernel messages in RFC 5424 log entries."
  :group 'log-mode-faces)

;;;###autoload
(define-generic-mode log-mode
  nil
  nil
  '(("^\\([0-9-]+\\)\\(T\\)\\([0-:]+\\)\\([.0-9]+\\)\\([.+0-:]*\\) \\([^[:blank:]]+\\) \\([^[:blank:]]+\\)"
     . ((1 'log-mode-date-face)
        (2 'log-mode-T-face)
        (3 'log-mode-time-face)
        (4 'log-mode-microsecond-face)
        (5 'log-mode-timezone-face)
        (6 'log-mode-hostname-face)
        (7 'log-mode-procid-face)))
    ("kernel - -.*$" 0 'log-mode-kernel-face t)
    (" - -.*\\(?:ERRORS?\\|FA\\(?:IL\\(?:ED\\|URE\\)\\|TAL\\)\\).*$"
     . (0 'log-mode-error-face t)))
  nil
  nil
  "Highlight logs, being aware of the RFC 5424 format.
Highlight kernel messages and error.")

(add-hook 'log-mode-hook (lambda ()
			   (progn
			     ;; HACK ATTACK!  We want to run after font-lock (so our
			     ;; wrap-prefix includes the faces applied by font-lock), but
			     ;; jit-lock-register doesn't accept an `append' argument, so
			     ;; we add ourselves beforehand, to make sure we're at the end
			     ;; of the hook (bug#15155).
			     (add-hook 'jit-lock-functions
				       #'log-mode-prefix-function 'append t)
			     (jit-lock-register #'log-mode-prefix-function))))
(add-hook 'log-mode-hook (lambda () (visual-line-mode 1)))
(add-hook 'log-mode-hook (lambda () (read-only-mode t)))

(provide 'log-mode)
;;; log-mode.el ends here
