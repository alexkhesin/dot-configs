;; -*- lexical-binding: t; -*-

(when (< emacs-major-version 30) (error "Requires GNU Emacs 30 or above"))

;; Effectively disable GC during startup. gcmh (init.el) takes over afterwards.
(let ((orig gc-cons-threshold))
  (setq gc-cons-threshold most-positive-fixnum)
  (add-hook 'emacs-startup-hook
            (lambda ()
              ;; Only restore if gcmh didn't load, so GC isn't off for the whole session.
              (unless (bound-and-true-p gcmh-mode)
                (setq gc-cons-threshold orig)))))

;; Prevent package.el from activating packages before init.el evaluates
(setq package-enable-at-startup nil)
(setq package-native-compile t)

; Put various tmp files (ie #foo#) in one place, instead scattered of all over
; the file system.  Don't use /tmp as it gets wiped on restarts on many systems.
(defconst ak-state-dir
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME")
                                 (expand-file-name "~/.local/state")))))

(make-directory ak-state-dir t)

;; Redirect native-compilation cache (.eln files) to XDG directory
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" ak-state-dir)))

;; ELPA packages and GPG keyring locations (XDG state)
(setq package-user-dir (expand-file-name "elpa/" ak-state-dir)
      package-gnupg-dir (expand-file-name "gnupg/" ak-state-dir))

;; Suppress UI chrome before frame creation
(unless (eq system-type 'darwin)
  (push '(menu-bar-lines . 0) default-frame-alist))
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(setq inhibit-startup-message t)

(defvar ak-frame-width 80
  "Standard frame width in columns, used for new frames and by `ak-single' etc.")
(push (cons 'width ak-frame-width) default-frame-alist)
