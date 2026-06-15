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
		      "^[^[:blank:]]+ [^[:blank:]]+ "
		      end)
		     log-mode-default-prefix-length)))
      (goto-char position)
      (if found (make-string (- found beg) #x20) nil))))

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
  '(("kernel - -.*$" . (0 'log-mode-kernel-face t))
    ("^\\([0-9-]+\\)\\(T\\)\\([0-:]+\\)\\([.0-9]+\\)\\([.+0-:]+\\) \\([^[:blank:]]+\\) \\([^[:blank:]]+\\)"
     . ((1 'log-mode-date-face append)
        (2 'log-mode-T-face append)
        (3 'log-mode-time-face append)
        (4 'log-mode-microsecond-face append)
        (5 'log-mode-timezone-face append)
        (6 'log-mode-hostname-face append)
        (7 'log-mode-procid-face)))
    (" - -.*\\(?:ERRORS?\\|FA\\(?:IL\\(?:ED\\|URE\\)\\|TAL\\)\\).*$"
     . (0 'log-mode-error-face t)))
  '("/var/log")
  (list (lambda () (setq-local wrap-prefix (log-mode--get-prefix)))
        (lambda () (visual-line-mode 1))
        (lambda () (read-only-mode nil)))
  "Highlight logs, being aware of the RFC 5424 format.
Highlight kernel messages and error.")

(provide 'log-mode)
;;; log-mode.el ends here
