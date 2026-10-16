;; -*- lexical-binding: t; -*-

(when (< emacs-major-version 31) (error "Requires GNU Emacs 31 or above"))

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
(when (native-comp-available-p)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" ak-state-dir)))

;; Workaround for the GCC driver bundled in Emacs.app: it derives
;; -mmacosx-version-min from the kernel version, and gets an invalid value on
;; macOS releases with year-based numbers (kernel 27 gives "18.0"). Pass the
;; real macOS version explicitly. Remove once the Emacs build bundles a GCC
;; whose gcc/config/darwin-driver.cc knows about macOS 27. The fix is already
;; in, as of 10/13/2026,
;; https://gnu.googlesource.com/gcc.git/+/refs/heads/trunk/gcc/config/darwin-driver.cc
;; has "macOS 27 aligned version number with Darwin27" comment.
(when (and (eq system-type 'darwin)
           (string-match "\\`\\([0-9]+\\)" operating-system-release)
           (>= (string-to-number (match-string 1 operating-system-release)) 26))
  (let ((ver (car (ignore-errors (process-lines "sw_vers" "-productVersion")))))
    (when (and ver (string-match "\\`[0-9]+\\.[0-9]+" ver))   ; "27.0.1" -> "27.0"
      (require 'comp)
      (add-to-list 'native-comp-driver-options
                   (concat "-mmacosx-version-min=" (match-string 0 ver))))))

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
