;;; vrtnu.el --- Emacs support for the Belgian VRT NU news format.

;; Copyright (C) 2010-2020 detvdl

;; Author: Detlev Vandaele <detvdl@pm.me>
;; Maintainer: Detlev Vandaele <detvdl@pm.me>
;; Created: 9 March 2021

;; Version: 0.0.1
;; Package-Version: 0.0.1

;; Package-requires (dash mpv (emacs "27"))

;;; Commentary:
;;; Code:

;; -*- lexical-binding: t -*-

(require 'dash)
(require 'mpv)
(eval-when-compile (require 'cl))

(defgroup vrtnu nil
  "VRT NU for emacs.")

(defcustom vrtnu-config-file (locate-user-emacs-file ".vrtnu.eld")
  "The position of the file that holds your user configuration.
The file should contain your login information for accessing the VRT NU website.
This file should contain a keyword plist of the format
    (:username <username> :password <password>)"
  :type 'file
  :group 'vrtnu)

(defcustom vrtnu-date-prompt-range 7
  "The amount of days in the past to prompt for when using `vrt-news'.
Should be a positive integer."
  :type '(restricted-sexp
          :match-alternatives (natnump))
  :group 'vrtnu)

(defcustom vrt-date-prompt-format "%A - %d/%m/%Y"
  "Format string to use when prompting for a date in `vrt-news'.
Uses format described in `format-time-string'."
  :type 'string
  :group 'vrtnu)

(defconst vrtnu--available-hours-alist
  '(("13u" . 13)
    ("update" . 18)
    ("19u" . 19)
    ("laat" . 23)))

(defconst vrt--url-format "https://www.vrt.be/vrtnu/a-z/het-journaal/2021/het-journaal-het-journaal-%s-%s")

(defun vrtnu--completion-table (items)
  "Generate completion table from ITEMS collection that maintains order in function using `metadata'."
  (lexical-let ((items items))
    (function
     (lambda (string pred action)
       (if (eq action 'metadata)
           '(metadata (display-sort-function . identity)
                      (cycle-sort-function . identity))
         (complete-with-action action items string pred))))))

(defun vrtnu--date-completions (&optional days)
  "Completion table for available dates.
Optional DAYS argument can be passed to restrict amount of days shown.
Default is defined in `vrtnu-date-prompt-range'."
  (let* ((n (or days vrtnu-date-prompt-range))
         (day-seq (--annotate (format-time-string vrt-date-prompt-format it)
                              (--iterate (time-subtract it (days-to-time 1))
                                         (current-time)
                                         n))))
    day-seq))

(defun vrtnu--time-completions (&optional date)
  "Completion table for available times/hours for DATE.
If DATE is not set, (current-time) is used."
  (let* ((date (decode-time (or date (current-time))))
         (available-hours (--select (time-less-p
                                     (encode-time (-replace-at 2 (cdr it) date))
                                     nil)
                                    vrtnu--available-hours-alist)))
    available-hours))

;;;###autoload
(defun vrt-news ()
  "Play selected news from vrt.be/vrtnu."
  (interactive)
  (-let* (((&plist :username user :password pass)
           (with-current-buffer (find-file-noselect vrtnu-config-file)
             (goto-char (point-min))
             (read (buffer-string))))
          (date-completions (vrtnu--date-completions))
          (date (cdr (assoc (completing-read
                             "Date: "
                             (vrtnu--completion-table date-completions)
                             nil t nil)
                            date-completions)))
          (time (completing-read
                 "Time: "
                 (vrtnu--completion-table (vrtnu--time-completions date))
                 nil t nil))
          (news-url
           (format vrt--url-format time (format-time-string "%Y%m%d" date)))
          (mpv-default-options
           `(,(format "--ytdl-raw-options=username=%s,password=%s" user pass))))
    (mpv-play-url news-url)))

(provide 'vrtnu)
;;; vrtnu.el ends here
