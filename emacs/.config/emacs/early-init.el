;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;; Effectively disable GC during startup. GCMH in init.el re-enables it.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Prevent package.el from activating packages before init.el evaluates
(setq package-enable-at-startup nil)

; Put various tmp files (ie #foo#) in one place, instead scattered of all over
; the file system.  Don't use /tmp as it gets wiped on restarts on many systems.
(defconst ak-state-dir
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME")
                                 (expand-file-name "~/.local/state")))))

(make-directory ak-state-dir t)

;; Backups, Auto-saves & Auto-save-list (XDG state tmp dir)
(setq backup-directory-alist         `((".*" . ,ak-state-dir))
      auto-save-file-name-transforms `((".*" ,ak-state-dir t))
      auto-save-list-file-prefix     (expand-file-name ".saves-" ak-state-dir))

;; ELPA packages and GPG keyring locations (XDG state)
(setq package-user-dir (expand-file-name "elpa/" ak-state-dir)
      package-gnupg-dir (expand-file-name "gnupg/" ak-state-dir))

;; Redirect native-compilation cache (.eln files) to XDG directory
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" ak-state-dir)))

;; macOS Modifiers
(when (eq system-type 'darwin)
  ; If you want a mac-native behavior (Command-c/v/x for copy-paste, uncomment
  ; (cua-selection-mode t) below, and kill the progn that follows.  Emacs 24
  ; already defaults to M-c/v for copy/paste on a Mac, and cua-selection-mode
  ; is only needed for rectangle support (and delete-selection-mode, but that
  ; can be turned on separately with (delete-selection-mode 1).

  ;; !!! do not try it because ssh-from-work-via-X11 emacs will still use X11,
  ; i.e. not mac-native interpretations of Optoion and Command keys. Unless can
  ; change that too.
  ; (cua-selection-mode t)
  ;
  ; This gives more familiar bindings to those who cannot get Linux bindings
  (setq mac-command-modifier 'meta
        mac-option-modifier nil))

;; Suppress UI chrome before frame creation
(unless (eq system-type 'darwin)
  (push '(menu-bar-lines . 0) default-frame-alist))
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(width . 80) default-frame-alist)
(setq inhibit-startup-message t)
