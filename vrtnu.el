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
  "The position of the file that holds your user configuration for
accessing the VRT NU website."
  :type 'file
  :group 'vrtnu)

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

(defun vrtnu--prompt-date (&optional days)
  "Prompt user for a date.
Optional DAYS argument can be passed to restrict amount of days shown.
Default is 31."
  (let ((days '()))
    (dotimes (i (or days 31))
      (setf days (cons (time-subtract (current-time) (days-to-time i)) days)))
    (let* ((day-seq (nreverse (--annotate (format-time-string "%A - %d/%m/%Y" it) days)))
           (ivy-sort-functions-alist nil)
           (input (completing-read "Date: " (vrtnu--completion-table day-seq) nil t nil)))
      (cdr (assoc input day-seq)))))

(defun vrtnu--select-date-time ()
  "Select date-time for VRT news selection."
  (let* ((hours-alist '(("13u" . 13) ("update" . 18) ("19u" . 19) ("laat" . 23)))
         (date (decode-time (vrtnu--prompt-date 7)))
         (available-hours (--select (time-less-p (encode-time (-replace-at 2 (cdr it) date)) nil) hours-alist))
         (ivy-sort-functions-alist nil)
         (time (completing-read "Time: " (vrtnu--completion-table available-hours) nil t nil)))
    `(:date ,(encode-time date) :time ,time)))

;;;###autoload
(defun vrt-news ()
  "Play selected news from vrt.be/vrtnu."
  (interactive)
  (-let* (((&alist 'username user 'password pass)
           (with-current-buffer (find-file-noselect vrtnu-config-file)
             (goto-char (point-min))
             (read (buffer-string))))
          ((&plist :date date :time time) (vrtnu--select-date-time))
          (date-fmt (format-time-string "%Y%m%d" date))
          (news-url (format vrt--url-format time date-fmt))
          (mpv-default-options `(,(format "--ytdl-raw-options=username=%s,password=%s" user pass))))
    (mpv-play-url news-url)))

(provide 'vrtnu)
;;; vrtnu.el ends here
