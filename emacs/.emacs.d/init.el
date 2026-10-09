;; -*- lexical-binding: t; -*-

; No effort is made to preserve compatibility with older versions
(if (or (< emacs-major-version 26) (string-match "XEmacs" emacs-version))
    (error "Requires GNU emacs 26 or above"))

; load local customizations if any
(defun ak-load-local-library-if-present (file)
  (let ((fname (expand-file-name file user-emacs-directory)))
    (when (file-exists-p fname) (load-file fname))))
(ak-load-local-library-if-present "local.el")

(defun ak-load-source-controlled-library (file)
  (load-file (expand-file-name file (concat user-emacs-directory "ak-emacs"))))

(ak-load-source-controlled-library "package-installer.el")
; too heavy-weight, do not use for now
; (ak-load-source-controlled-library "ecb-cedit.el")

(defconst ak-mac-os-x (string-match "apple-darwin" system-configuration))
(defconst ak-linux (string-match "linux-gnu" system-configuration))

(require 'diminish)
(require 'which-key)

; --------------- turn silly things off
(fset 'yes-or-no-p 'y-or-n-p)          ; no "yes" / "no" prompts
(setq inhibit-startup-message t)
(blink-cursor-mode t)
(setq compilation-ask-about-save nil)  ; save all buffers before compiling

; --------------- markdown
(setq markdown-command "pandoc")

; --------------- orgmode
(setq org-agenda-files '("~/orgmode"))
(setq org-directory '("~/orgmode"))
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-switchb)
(setq org-link-abbrev-alist '(("cl" . "http://cl/%s")
                              ("b" . "http://b/%s")
                              ("go" . "http://go/%s")))
(setq org-hide-leading-stars t)
(setq org-pretty-entities t)
(setq org-hide-emphasis-markers t)
(setq org-support-shift-select t)
(setq org-return-follows-link t)
(setq real-auto-save-interval 30)
(setq org-replace-disputed-keys t)
;; from https://zzamboni.org/post/beautifying-org-mode-in-emacs/
(font-lock-add-keywords 'org-mode
                        '(("^ *\\([-]\\) "
                           (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))
(require 'org-bullets)
(require 'real-auto-save)
(add-hook 'org-mode-hook
          (lambda ()
            (org-bullets-mode 1)ß
            (variable-pitch-mode 1)
            (visual-line-mode 1)
            ; annoyingly global, use real-auto-save instead
            ; (auto-save-visited-mode 1)
            (real-auto-save-mode t)
            (diminish 'real-auto-save-mode)
            (diminish 'visual-line-mode)
            (diminish 'buffer-face-mode) ; did not trace where this mode comes from
            ))
(defun ak-org-theme-customize ()
  (custom-theme-set-faces
   'user
   '(org-table                 ((t (:inherit fixed-pitch))))
   ))

; --------------- autosave

; Put autosave files (ie #foo#) in one place, instead scattered of all over the
; file system.  Don't use /tmp as it gets wiped on restarts on many systems.
; Don't use NFS (~/) on corp workstations to keep saves fast.
(defconst durable-tmp-dir
  (let ((dir (concat "/usr/local/google/home/" (user-login-name) "/tmp/")))
    (if (file-exists-p dir) (concat dir "emacs/")
      (concat user-emacs-directory "tmp/"))))
(make-directory durable-tmp-dir t)

; from www.emacswiki.org/emacs/AutoSave
(setq backup-directory-alist         `((".*" . ,durable-tmp-dir)))
(setq auto-save-file-name-transforms `((".*"   ,durable-tmp-dir t)))

; --------------- customize visual settings

(setq truncate-partial-width-windows nil) ; wrap horizontally-split windows
(setq line-number-mode t)                 ; have line numbers and
(setq column-number-mode t)               ; column numbers in the mode line
(scroll-bar-mode -1)                      ; no scroll bars
(tool-bar-mode -1)                        ; no tool bar with icons
(show-paren-mode 1)                       ; highlight matching parens
(unless ak-mac-os-x
  ; on mac, there's always a menu bar drown, don't have it empty
  (menu-bar-mode -1))                     ; C-mouse-3 to access menu

;; set-face-attribute does not work when called directly in daemon mode.  setq
;; default-frame-list works but does not let me modify the mode line.  This more
;; complicated solution lets me have everything.  See https://superuser.com/questions/579349/how-to-make-emacsclient-uses-differnt-themes-in-terminal-and-x-window
(defun ak-set-font ()
  (when (and ak-linux window-system)
    (set-face-attribute 'default nil :font "Ubuntu Mono:pixelsize=15")
    (set-face-attribute 'mode-line nil :font "Ubuntu Mono:pixelsize=13")))
(if (daemonp)
    (add-hook 'after-make-frame-functions
              '(lambda (frame) (select-frame frame) (ak-set-font)))
  (ak-set-font))
;; other fonts: used to use "7x13" with old display, but that needed
;;                (set-face-attribute face nil :weight 'normal)
;; because emacs 25 changes AVERAGE_WEIGHT part of 7x13 font spec from 70 to 80
;; making bold characters take more space. Probably a bug in emacs. That removed
;; bold from all faces.
;;
;; also http://www.handcoding.com/archives/2006/03/30/bitstream-vera-sans-mono-is-a-sweet-programming-font/
;; and https://github.com/adobe-fonts/source-code-pro

(when ak-mac-os-x
;  (set-face-attribute 'default nil
;                      :family "Menlo" :height 110 :weight 'normal)
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
  ; out of their muscle memory, even when using emacs on a Mac.
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier nil)
)
(cua-mode t)
;; need this? was added by customize on Mac (cua-mode t nil (cua-base))

; see https://github.com/bbatsov/zenburn-emacs/issues/89
; and http://www.emacswiki.org/emacs/ELPA#toc4
(add-hook 'after-init-hook
          '(lambda ()
             (load-theme 'zenburn t)
             (ak-org-theme-customize)
))
; (load-theme 'solarized-dark t)

;; Not planning to use Ruby at this point
;;
;; ; --------------- Ruby config
;;
;; (add-to-list 'auto-mode-alist '("Capfile" . ruby-mode))
;; (add-to-list 'auto-mode-alist '("Gemfile" . ruby-mode))
;; (add-to-list 'auto-mode-alist '("Rakefile" . ruby-mode))
;; (add-to-list 'auto-mode-alist '("\\.rake\\'" . ruby-mode))
;; (add-to-list 'auto-mode-alist '("\\.ru\\'" . ruby-mode))

;; ; run a single test buffer
;; ; (from http://www.viget.com/extend/emacs-24-rails-development-environment-from-scratch-to-productive-in-5-minu/)
;; (defun is-rails-project ()
;;   (when (textmate-project-root)
;;     (file-exists-p (expand-file-name "config/environment.rb"
;;                                      (textmate-project-root)))))
;; (defun run-rails-test-or-ruby-buffer ()
;;   (interactive)
;;   (if (is-rails-project)
;;       (let* ((path (buffer-file-name))
;;              (filename (file-name-nondirectory path))
;;              (test-path (expand-file-name "test" (textmate-project-root)))
;;              (command (list ruby-compilation-executable "-I" test-path path)))
;;         (pop-to-buffer (ruby-compilation-do filename command)))
;;     (ruby-compilation-this-buffer)))

;; ; textmate wants to be a global minor mode, but I only use a few commands
;; ; out of it, and it's keymap is evil - it is different on Mac vs Linux.  So
;; ; disable the minor mode, and only pull in the functions that I actually use -
;; ; textmate-project-root is used by code above, textmate-goto-file is given a key
;; ; binding below.  textmate-goto-symbol also looks interesting, maybe I should
;; ; bind a key for it too.
;; (textmate-mode 0)

; --------------- customize various modes
(global-undo-tree-mode)
(diminish 'undo-tree-mode)
(global-set-key [(control shift z)] 'redo)
; (global-set-key "\C-?" 'redo)  ; control shift _, but cannot make it work

(setq
 ; nxhtml-global-minor-mode t  ; show nxhtml menu (is it on by default?)
 mumamo-chunk-coloring 1     ; color submode chunks of depth > 1
 nxhtml-skip-welcome t)

; (autoload 'dot-mode "dot-mode" nil t)
(eval-after-load 'dot-mode
  '(progn
     ; rebind dot-mode-execute from C-. to M-.
     (define-key dot-mode-map [(control \.)] nil)
     (define-key dot-mode-map [(meta \.)] 'dot-mode-execute)))
;; dot-mode is broken in emacs 24 because it uses obsolete make-local-hook
;; (global-set-key "\M-." (lambda () (interactive) (dot-mode 1)
;;                       (message "Dot mode activated.")))

; Install mode-compile to give friendlier compiling support (for Ruby in
; particular). (think about how to integrate it with google-compile?)
(autoload 'mode-compile "mode-compile"
  "Command to compile current buffer file based on the major mode" t)
(global-set-key "\C-cc" 'mode-compile)
(autoload 'mode-compile-kill "mode-compile"
  "Command to kill a compilation launched by `mode-compile'" t)
(global-set-key "\C-ck" 'mode-compile-kill)

; whenever an external process changes a file underneath emacs, and there
; was no unsaved changes in the corresponding buffer, just revert its
; content to reflect what's on-disk.
(global-auto-revert-mode 1)

; M-x shell is a nice shell interface to use, let's make it colorful.  If
; you need a terminal emulator rather than just a shell, consider M-x term
; instead.
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(require 'ido)
(ido-mode 'buffers)
; (ido-mode 'both)  ;; this enables ido-find-file which I do not like
(setq ido-enable-flex-matching t)
; allow for viewing a file in two different buffers
(setq ido-default-file-method 'selected-window)
(setq ido-default-buffer-method 'selected-window)
; from https://github.com/dimitri/emacs-kicker/blob/master/init.el
; --> figure out if makes sense (says "ido for minibuffer completion")
;; (setq ido-use-filename-at-point 'guess)
;; (setq ido-show-dot-for-dired t)

; ibuffer config
; (global-set-key (kbd "C-x C-b") 'ido-switch-buffer)

;; better IDO, also ivy-xref better xref?  But need to spend time configuring it
;; see https://www.reddit.com/r/emacs/comments/51lqn9/helm_or_ivy/
;; and https://github.com/purcell/emacs.d/blob/master/lisp/init-ivy.el
; (require 'ivy)
; (ivy-mode 1)
; (setq xref-show-xrefs-function 'ivy-xref-show-xrefs)

(global-set-key (kbd "C-x C-b") 'ibuffer)
(setq ibuffer-default-sorting-mode 'filename/process)

(require 'savehist)
(savehist-mode)                         ; save minubuffers history
(setq history-delete-duplicates t)
; (eval-after-load 'rinari
;  ; run something like
;  ;   ctags-exuberant -a -e -f TAGS --tag-relative -R app lib vendor
;  ; to create a tag file
;  '(progn (setq rinari-tags-file-name "TAGS")))

(add-hook 'write-file-hooks #'delete-trailing-whitespace)

(require 'ffap)   ; find file at point
; rebind C-x C-f and others to the ffap bindings
(ffap-bindings)
(setq ffap-url-fetcher 'browse-url-at-point)

(load "dired-x")   ; provide some dired goodies and dired-jump at C-x C-j

; Customize buffer names when several buffers visit identically-named files
(require 'uniquify)
;; (setq uniquify-min-dir-content 1)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

; recentf
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-saved-items 500)
(setq recentf-max-menu-items 60)

; turn on which-func, but do not show it in the mode-line (only in title bar)
(which-function-mode t)
(delete (assoc 'which-function-mode mode-line-format) mode-line-format)

;;   sudo apt-get install hunspell hunspell-en-us
;;   sudo port install hunspell hunspell-en_US
(setq-default ispell-program-name (executable-find "hunspell"))
(setq ispell-really-hunspell t)
(setq ispell-dictionary "american")

(setq-default flyspell-persistent-highlight nil)  ; only highlight the last
                                                  ; error found
(setq-default flyspell-issue-welcome-flag nil)
(setq-default flyspell-issue-message-flag nil)
(setq-default flyspell-duplicate-distance 0)
(add-hook
 'flyspell-mode-hook
 '(lambda ()
    (diminish 'flyspell-mode)
    ; rebind flyspell-auto-correct-word from C-. to C-'
    (define-key flyspell-mode-map [(control \.)] nil)
    (define-key flyspell-mode-map [(control \')] 'flyspell-auto-correct-word)))

; Enable tab-completion
(defun ak-indent-or-expand (arg)
  "Either indent according to mode, or expand the word preceding
point."
  (interactive "*P")
  (if (and
       (or (bobp) (= ?w (char-syntax (char-before))))
       (or (eobp) (not (= ?w (char-syntax (char-after))))))
      ; (dabbrev-expand arg)
      (company-indent-or-complete-common)
; hippie-emacs is broken at least in the multi-tty branch I am using at
; the moment in that it does not cycle through completion candidates
; on multiple applications (TAB key presses)
;      (hippie-expand arg)
; see also http://www.emacswiki.org/emacs/TabCompletion and auto-complete mode
    (indent-according-to-mode)))

;; (setq hippie-expand-try-functions-list
;;       '(try-complete-file-name-partially
;;         try-complete-file-name
;;         try-expand-all-abbrevs
;; ;       try-expand-list
;;         try-expand-line
;;         try-expand-dabbrev
;;         try-expand-dabbrev-all-buffers
;;         try-expand-dabbrev-from-kill
;;         try-complete-lisp-symbol-partially
;;         try-complete-lisp-symbol))

(add-hook 'text-mode-hook       'flyspell-mode)

(setq ak-prog-mode-hooks
      (list 'c-mode-common-hook
            'sh-mode-hook
            'python-mode-hook
            'ruby-mode-hook
            'emacs-lisp-mode-hook
            'cperl-mode-hook
            'autoconf-mode-hook
            'autotest-mode-hook
            'makefile-mode-hook
            'css-mode-hook))

(add-hook 'c-mode-common-hook
          '(lambda ()
             ; even smarter RET for c-modes
             (local-set-key (kbd "RET") 'c-context-line-break)
             ; When I yank a piece of code ( known as paste in Windows lingo )
             ; into an existing function, I like to have it indent itself to the
             ; proper level automatically. This simple macro runs yank ( C-y )
             ; followed by an indent current function. ( C-c C-q )
             (local-set-key "\C-v" 'do-smart-yank)
             (fset 'do-smart-yank "\C-y\C-c\C-q")))

(add-hook 'css-mode-hook
          '(lambda () (setq css-indent-offset 2)))

(require 'company)
(define-key company-active-map (kbd "<tab>")
  'company-complete-common-or-cycle)
(define-key company-active-map (kbd "TAB")
  'company-complete-common-or-cycle)
; capf (completion-at-point-functions) are usually based on tags or LSP, which
; invariably miss some words in the buffer, especially in presence of
; syntactical errors.  Replace company-capf with a single backend that combines
; company-capf and company-dabbrev-code.  Maybe company-dabbrev would be more
; useful?  Evaluate after using it for a while (but then see
; https://github.com/company-mode/company-mode/issues/60)
;
; another way to achieve this; have not played with it much
;  https://emacs.stackexchange.com/questions/30690/code-auto-completion-with-ivy
(setf (nth (cl-position 'company-capf company-backends) company-backends)
      '(company-capf company-dabbrev-code))
; Delete dabbrev matches that are the same as capf.  We know capf matches
; include arguments (e.g. "foo(var1)" for capf vs just "foo" for dabbrev);
; we also know the lists are sorted. So eliminate elements that follow their
; prefixes and that have '(' as the very next character after the prefix
(defun ak-delete-dabbrev-dups (list)
  (let ((tail list) last)
    (while (cdr tail)
      (let ((first (car tail)) (second (cadr tail)) changed)
        (if (string-prefix-p first second)
            (if (string= first second)
                (let ((f (seq-filter
                          (lambda (el)
                            (not (eq 'company-dabbrev-code
                                     (get-text-property 0 'company-backend el))))
                          (list first second))))
                  ; will need to adjust code below if this ever stops being true
                  (cl-assert (equal 1 (length f)))
                  (setcar tail (elt f 0))
                  (setcdr tail (cddr tail))
                  (setq changed t))
              ; 40 is ?( but the literal paren confuses the editor
              (if (eq 40 (elt second (length first)))
                  (progn
                    (setcar tail second)
                    (setcdr tail (cddr tail))
                    (setq changed t)))))
        (if (not changed)
            (setq last tail
                  tail (cdr tail)))))
    list))
(add-to-list 'company-transformers 'ak-delete-dabbrev-dups)
; and now sort by relevance
(add-to-list 'company-transformers 'company-sort-by-occurrence)

(diminish 'company-mode)
(diminish 'abbrev-mode)  ; no idea who turns it on
(diminish 'eldoc-mode)    ; no idea who turns it on

;; google-maybe-delete-trailing-whitespace does this better
;; (add-hook 'before-save-hook
;;           '(lambda () (when (derived-mode-p 'prog-mode)
;;                         (message "foo")
;;                         (delete-trailing-whitespace))))
;  common hook function for all programming language modes
(add-hook 'prog-mode-hook
          '(lambda ()
             (setq tab-width 2)
             (setq indent-tabs-mode nil)  ; don't replace spaces with tabs
             (setq fill-column 80)
             (setq compilation-scroll-output t)
             (turn-on-auto-fill)                       ; automatic line breaking
             (diminish 'auto-fill-function)
             (flyspell-prog-mode)
             (subword-mode 1)
             (diminish 'subword-mode)
             (local-set-key [C-f10]      'compile)
             (company-mode 1)
             (local-set-key [tab]       'company-indent-or-complete-common)
             (local-set-key "\M-p"      'textmate-goto-file)
             (local-set-key (kbd "RET") 'newline-and-indent)
             (local-set-key [M-down]    'next-error)
             (local-set-key [M-up]      '(lambda () (interactive)
                                           (next-error -1)))
             ))
;; cc-mode does not derive from prog-mode anymore, see
;; https://sourceforge.net/p/cc-mode/mailman/message/35449588/
; (add-hook 'c-mode-common-hook (lambda () (run-hooks 'prog-mode-hook)))

; allow bringing up a search-and-replace using the history mechanism in
; MiniBuffer)
(setq enable-recursive-minibuffers t)

; attempt to reuse windows instead of splitting
; --> does not work very well in emacs 24.x anymore

(setq split-height-threshold nil)
; (setq split-width-threshold nil)
; and such appear to be the right ways to tune this, see
; http://lists.gnu.org/archive/html/help-gnu-emacs/2011-02/msg00350.html
;
; --> display-buffer in emacs 24 is much more complex and overriding
; display-buffer-function does not seem to work cleanly anymore (in particular,
; in emacs 23, display-buffer-function was not called at all on opening new
; files, whereas in emacs 24 it is called, and with override below, new files
; are always open in lru window, which is not the desired effect (should be the
; current window).  But emacs 24 seems to behave sensibly even without this
; override; the biggest ill effect of not having it is that gtags searches do
; not seem to be picking LRU windows, which needs to be investigated.
;; (setq display-buffer-function
;;       '(lambda (buffer-or-name not-this-window)
;;       (message "%s" buffer-or-name)
;;       (if (null (get-buffer-window buffer-or-name))
;;           (progn (if (one-window-p t)
;;                      (split-window (get-largest-window) nil t))
;;                  (set-window-buffer (get-lru-window) buffer-or-name)))
;;       (get-buffer-window buffer-or-name)))

; --------------- random utilities

(defun ak-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))
(setq ak-frame-width 80)
(defun ak-single ()
  (interactive)
  (delete-other-windows)
  (set-frame-width (selected-frame) ak-frame-width))
(defun ak-double ()
  (interactive)
  (delete-other-windows)
  (set-frame-width (selected-frame) (+ 3 (* 2 ak-frame-width)))
  (split-window-horizontally)
  (balance-windows))

(defun ak-triple ()
  (interactive)
  (delete-other-windows)
  (set-frame-width (selected-frame) (+ 6 (* 3 ak-frame-width)))
  (split-window-horizontally)
  (split-window-horizontally)
  (balance-windows))

(defun ak-mac-height ()
  (interactive)
  (set-frame-height (selected-frame) 65))

; Go to the first character on the line
(defun chrisk-beginning-of-line ()
  (interactive)
  (let ((start (point)))
    (back-to-indentation)
    (if (= start (point)) (beginning-of-line))))

(global-set-key (kbd "C-x C-z") 'magit-status)
(global-set-key (kbd "C-x C-/") 'goto-last-change)
(global-set-key [(control shift iso-lefttab)]
  '(lambda () (interactive (other-window -1))))
(global-set-key [(control tab)] 'other-window)
(global-set-key "\M-g" 'goto-line)
;; Smart paste
(global-set-key [(meta f12)] 'recentf-open-files)
(global-set-key "\C-a" 'chrisk-beginning-of-line)
(global-set-key [home] 'chrisk-beginning-of-line)
(global-set-key "%" 'ak-match-paren)             ; parenthesis matching

(winner-mode 1)   ; C-c + <left/right> to get back to previous window layout
(windmove-default-keybindings 'meta) ; navigate windows with M-<arrows>
(setq windmove-wrap-around t)
