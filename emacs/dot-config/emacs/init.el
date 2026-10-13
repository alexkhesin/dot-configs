;; -*- lexical-binding: t; byte-compile-warnings: (not noruntime);-*-

;; (not noruntime) above disables "function might not be defined at runtime"
;; warnings from flymake.

;; To silence flymake warnings about unknown variables and functions
(defvar ak-state-dir)
(defvar ak-frame-width)

;; Platfrom detection
(defconst ak-mac-p (eq system-type 'darwin))
(defconst ak-linux-p (eq system-type 'gnu/linux))

;; Package Archives & Bootstrapping
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Prefer official curated releases over rolling Git snapshots
(setopt package-archive-priorities
      '(("gnu"    . 30)
        ("nongnu" . 20)
        ("melpa"  . 10)))

(package-initialize)
;; Built-in use-package settings
(require 'use-package)
(require 'cl-lib)  ;; Common List utilities needed for other cl-*` functions
(setopt use-package-always-ensure t
        use-package-expand-minimally t)

;; Some packages store files next to init.el. Make it stop.
(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "etc/" ak-state-dir)
        no-littering-var-directory ak-state-dir)
  :config
  (no-littering-theme-backups))

;; Minimize GC interference with user activity: sets high GC threshold during
;; use and drops it down when idling.
(use-package gcmh
  :demand t
  :config
  (gcmh-mode 1))

;; Auto-update
(use-package auto-package-update
  :custom
  (auto-package-update-interval 7)
  (auto-package-update-prompt-before-update nil)
  (auto-package-update-hide-results t)
  :config
  (auto-package-update-maybe))

;; ----------------------------------------------------------------------------
;; Core Sensible Defaults
;; ----------------------------------------------------------------------------
(setopt use-short-answers t                  ; Modern (fset 'yes-or-no-p 'y-or-n-p)
        compilation-ask-about-save nil       ; Save buffers without prompting
        truncate-partial-width-windows nil   ; Wrap horizontally-split
        enable-recursive-minibuffers t
        split-height-threshold nil)

;; Given enable-recursive-minibuffers, a new minibuffer command can be started
;; while another one is still waiting for input (e.g. find-file). The nested
;; prompt looks identical to the outer one, so it's easy to lose track of how
;; many are open. This mode prefixes the prompt with the nesting depth
;; (something like "[2]"), to indicate there's an unfinished prompt underneath.
(minibuffer-depth-indicate-mode 1)

(setq-default indent-tabs-mode nil)   ; indent with spaces; modes that need tabs
                                      ; (Makefile) set their own
(column-number-mode 1)                ; Show column numbers in mode line
(line-number-mode 1)
(blink-cursor-mode 1)
(show-paren-mode 1)
(global-auto-revert-mode 1)
(winner-mode 1)  ; C-c + <left/right> to get back to previous window layout
(repeat-mode 1)  ; M-g n, then n/p to repeat
(cua-mode 1)

;; Keep Customize out of init.el
(setopt custom-file (expand-file-name "custom.el" ak-state-dir))
(load custom-file 'noerror 'nomessage)

;; Window navigation
(windmove-default-keybindings 'meta)  ; navigate windows with M-<arrows>
(setopt windmove-wrap-around t)

;; Font configuration (handles standalone GUI and emacsclient daemon frames)
(defun ak-apply-frame-fonts (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (when (and ak-linux-p (display-graphic-p))
      (set-face-attribute 'default nil :font "Ubuntu Mono:pixelsize=15")
      (set-face-attribute 'mode-line nil :font "Ubuntu Mono:pixelsize=13"))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'ak-apply-frame-fonts)
  (ak-apply-frame-fonts))

(use-package emacs
  :ensure nil
  :preface
  (defvar ak-minor-modes-always-shown '(flymake-mode)
    "Minor modes whose mode-line lighter stays visible")

  (defun ak-minor-mode-has-menu-p (mode)
    "Non-nil if minor MODE has a menu-bar menu of its own.
This is the lookup Emacs uses to build the collapsed-modes menu; modes without
one only offer \"Help\" and \"Turn off\"."
    (let ((map (cdr-safe (assq mode minor-mode-map-alist))))
      (and (keymapp map) (keymap-lookup map "<menu-bar>") t)))

  (defun ak-minor-modes-with-menus-only (orig-fn &rest args)
    "Call ORIG-FN with `minor-mode-alist' to enable modes worth showing."
    (let ((minor-mode-alist
           (seq-filter (lambda (item)
                         (let ((mode (car item)))
                           (and (boundp mode) (symbol-value mode)
                                (or (memq mode ak-minor-modes-always-shown)
                                    (ak-minor-mode-has-menu-p mode)))))
                       minor-mode-alist)))
      (apply orig-fn args)))
  :config
  ;; Drop minor modes that only offer "Help" and "Turn off".
  (advice-add 'mode-line--minor-modes :around #'ak-minor-modes-with-menus-only)
  ;; Hide the version-control indicator ("Git-main").
  (setq-default mode-line-format (remove '(vc-mode vc-mode) mode-line-format))

  ;; Collapse the remaining lighters into one "..." button, except
  ;; the always-shown ones.
  (setopt mode-line-collapse-minor-modes (cons 'not ak-minor-modes-always-shown)))

;; ----------------------------------------------------------------------------
;; UI & Utilities
;; ----------------------------------------------------------------------------

;; macOS: Command acts as Meta and Option stays native (for typing special
;; characters), to make it work the same whether it is locally launched emacs or
;; ssh-from-work-via-X11 emacs running on Linux but displaying on Mac.
(when ak-mac-p
  (setq mac-command-modifier 'meta
        mac-option-modifier nil))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1)
  :custom
  (history-delete-duplicates t)
  (savehist-save-minibuffer-history t))

(use-package which-key
  :ensure nil ; Built-in in Emacs 30
  :config
  (which-key-mode 1))

(use-package zenburn-theme
  :config
  (load-theme 'zenburn t))

(keymap-global-set "C-S-z" #'undo-redo) ; with cua-mode, C-z is undo
(use-package vundo
  :bind ("C-x u" . vundo)
  :config
  ;; Optional: Use prettier unicode characters to draw the tree lines
  (setopt vundo-glyph-alist vundo-unicode-symbols))

(use-package recentf
  :ensure nil
  :init (recentf-mode 1)
  :custom
  (recentf-max-saved-items 500)
  (recentf-max-menu-items 60)
  :bind ("M-<f12>" . recentf-open-files))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :config
  (setopt ibuffer-default-sorting-mode 'filename/process))

(use-package uniquify
  :ensure nil
  :custom
  (uniquify-buffer-name-style 'post-forward-angle-brackets))

(use-package ffap
  :ensure nil
  :config
  (ffap-bindings)
  (setopt ffap-url-fetcher #'browse-url-at-point))

;; Git interface & change navigation
(use-package magit
  :bind (("C-x C-z" . magit-status)))

(use-package diff-hl
  :hook ((magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode         . diff-hl-dired-mode))   ; optional: markers in Dired too
  :init
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

(use-package goto-chg
  :bind (("C-x C-/" . goto-last-change)))

;; ----------------------------------------------------------------------------
;; Completion & Editing
;; ----------------------------------------------------------------------------

;; Modern (as of 2026) set of packages to make completions look good. Vertico
;; controls how candidates are displayed and navigated. Orderless controls which
;; candidates match your input. Marginalia controls what extra information
;; accompanies each candidate. You can use any one without the others, but they
;; complement each other. For example, Vertico alone with default prefix
;; matching feels limited, and Orderless alone with the stock *Completions*
;; buffer works but looks plain.

;; 1. Vertico: The Vertical Minibuffer UI
(use-package vertico
  :init
  (vertico-mode 1)
  :config
  ;; Optional: Tweak minibuffer behavior
  (setopt vertico-resize t          ; Grow and shrink minibuffer dynamically
          vertico-cycle t)          ; Go back to top when hitting the bottom
  ; get Jinx completions into Vertico
  (require 'vertico-multiform)
  (setopt vertico-multiform-categories
          '((jinx grid (vertico-grid-annotate . 20) (vertico-count . 4))))
  (vertico-multiform-mode 1))

;; 2. Fuzzy/Component Matcher.
;; Allows typing terms in any order, separated by spaces (e.g., "init el"
;; matches "init.el")
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; 3. Rich descriptions in the minibuffer.
;; Adds file permissions, sizes, and command descriptions in the margins
(use-package marginalia
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle)) ; Toggle description styles dynamically
  :init
  (marginalia-mode))


(use-package corfu
  :custom
  (corfu-auto nil)  ;; we will enable it for prog modes separately
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init
  (global-corfu-mode)
  :config
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1))

;; Fallback completion sources, used when the mode's own source finds nothing.
(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;; Spelling
;; Get a message instead of an error if jinx is unavaialble
(defun ak-enable-jinx ()
  (with-demoted-errors "jinx: %S" (jinx-mode 1)))

(use-package jinx
  :hook ((text-mode prog-mode) . ak-enable-jinx)
  :bind (("M-$"   . jinx-correct)
         ("C-M-$" . jinx-languages)
         ;; M-$ is standard for jinx, but conflicts with system bindings for
         ;; MacOS. C-' is what I am used to, but it conflicts with org-mode
         ;; bindings. Installing it in jinx-mode-map makes it available in
         ;; org-mode too, but overriding its own binding,
         ;; org-cycle-agenda-files. I should find some other shortcut one day.
         :map jinx-mode-map
         ("C-'" . jinx-correct))
  :custom
  (jinx-languages "en_US"))

;; Programming mode tweaks
(setopt compilation-scroll-output t)

(defun ak-prog-mode-setup ()
  "Per-buffer settings for programming modes."
  (setq-local fill-column 80
              tab-always-indent 'complete ; TAB completes once the line is
                                          ; indented
              corfu-auto t)               ; automatic popups
  (turn-on-auto-fill)
  (subword-mode 1))
(add-hook 'prog-mode-hook #'ak-prog-mode-setup)

;; Bound once in the shared map. A mode's own map overrides prog-mode-map.
(keymap-set prog-mode-map "C-<f10>" #'compile)

;; To silence flymake warnings about unknown variables and functions
(declare-function c-indent-defun "cc-cmds")
(declare-function c-context-line-break "cc-cmds")
(defvar c-mode-base-map)

(defun ak-c-indent-after-paste (&rest _)
  "Re-indent the surrounding defun after pasting in a CC Mode buffer."
  (when (derived-mode-p 'c-mode 'c++-mode 'objc-mode 'java-mode)
    (with-demoted-errors "c-indent-defun: %S"
      (c-indent-defun))))

(with-eval-after-load 'cc-mode
  (advice-add 'cua-paste :after #'ak-c-indent-after-paste)
  (keymap-set c-mode-base-map "RET" #'c-context-line-break))

;; Trim trailing whitespace only on lines I edited, everywhere except
;; for Markdown, because in Markdown adding two or more spaces means <br>
(use-package ws-butler
  :config
  (dolist (mode '(markdown-mode gfm-mode))
    (add-to-list 'ws-butler-global-exempt-modes mode))
  (ws-butler-global-mode 1))

;; Save visited Org files in place every 30s (built-in; replaces real-auto-save)
(use-package files
  :ensure nil
  :custom
  (auto-save-visited-interval 30)
  (auto-save-visited-predicate (lambda () (derived-mode-p 'org-mode)))
  :config
  (auto-save-visited-mode 1))

;; ----------------------------------------------------------------------------
;; Languages & Formats (Markdown, Dot, Org)
;; ----------------------------------------------------------------------------

;; Indentation width is a per-mode setting; there is no global one.
;; (tab-width and indent-tabs-mode only govern tab characters.)
(use-package emacs
  :ensure nil
  :custom
  (python-indent-offset 2)
  (js-indent-level 2)
  (css-indent-offset 2)
  (sh-basic-offset 2)
  (sgml-basic-offset 2))

(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :custom
  (markdown-command "pandoc"))

;; Flymake: the built-in diagnostics framework (underlines and mode-line counters).
;; Eglot turns on flymake automatically for languages it manages, so this stanza
;; only matters for the ones it does not - currently just Elisp.
(use-package flymake
  :ensure nil
  :preface
  (defun ak-elisp-flymake ()
    "Enable Flymake in Emacs Lisp buffers, but drop complaints about docstrings."
    (remove-hook 'flymake-diagnostic-functions #'elisp-flymake-checkdoc t)
    (flymake-mode 1))
  (defun ak-flymake-child-env (orig-fn &rest args)
    "Run Flymake's `emacs -Q --batch' checker with our state dir as its home.
The child derives its eln-cache and elpa from $XDG_CONFIG_HOME/emacs, so point
that at the parent of `ak-state-dir'. Otherwise trampoline files keep appearing
in the directory that has init.el"
    (let ((process-environment
           (cons (concat "XDG_CONFIG_HOME="
                         (directory-file-name
                          (file-name-directory (directory-file-name ak-state-dir))))
                 process-environment)))
      (apply orig-fn args)))
  :custom
  ;; Flymake's Elisp checker runs a separate `emacs -Q --batch' process that
  ;; does not know about installed package or early-init.el. Give it our
  ;; load-path so it can find installed packages, which silences most "unknown
  ;; function" and "unknown variable" warnings in init.el.
  (elisp-flymake-byte-compile-load-path load-path)
  :init
  (advice-add 'elisp-flymake-byte-compile :around #'ak-flymake-child-env)
  :hook (emacs-lisp-mode . ak-elisp-flymake))

(use-package eglot
  :ensure nil
  :hook (((c-mode c++-mode python-mode) . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  :config
  (add-to-list 'eglot-server-programs
               '((python-ts-mode python-mode) . ("pyrefly" "lsp"))))

(use-package graphviz-dot-mode
  :mode "\\.dot\\'")

(defun ak-org-setup ()
  "Prose-friendly display for Org buffers."
  (variable-pitch-mode 1)
  (visual-line-mode 1))

(use-package org
  :ensure nil
  :hook (org-mode . ak-org-setup)
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c b" . org-switchb))
  :custom-face
  (org-table ((t (:inherit fixed-pitch))))
  (org-block ((t (:inherit fixed-pitch))))
  (org-code ((t (:inherit (shadow fixed-pitch)))))
  (org-verbatim ((t (:inherit (shadow fixed-pitch)))))
  (org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  (org-checkbox ((t (:inherit fixed-pitch))))
  (org-formula ((t (:inherit fixed-pitch))))
  :custom
  (org-directory "~/orgmode")          ; old value was a one-element list, which Org doesn't expect
  (org-agenda-files '("~/orgmode"))
  ;; Must be set before Org loads, which :custom guarantees here
  (org-replace-disputed-keys t)
  (org-support-shift-select t)         ; shift-arrow selection, matters with cua-mode
  (org-return-follows-link t)
  (org-hide-leading-stars t)
  (org-pretty-entities t)
  (org-hide-emphasis-markers t)
  ;; Corp short links; delete any you no longer use
  (org-link-abbrev-alist '(("cl" . "http://cl/%s")
                           ("b"  . "http://b/%s")
                           ("go" . "http://go/%s"))))

(use-package auctex :defer t)

(use-package tex
  :ensure nil
  :defer t
  :hook ((LaTeX-mode . visual-line-mode)   ; wrap long paragraphs
         (LaTeX-mode . LaTeX-math-mode)    ; ` prefix inserts math symbols
         (LaTeX-mode . turn-on-reftex))    ; C-c ( / C-c [ for labels and citations
  :custom
  ;; from your old config
  (TeX-auto-save t)
  (TeX-parse-self t)
  (LaTeX-includegraphics-read-file #'LaTeX-includegraphics-read-file-relative)
  (TeX-master t)                       ; single-file documents; use nil for multi-file projects
  ;; additions
  (TeX-save-query nil)                 ; save before compiling without asking
  (TeX-source-correlate-mode t)        ; SyncTeX: jump between source and PDF
  (TeX-source-correlate-start-server t)
  (TeX-error-overview-open-after-TeX-run t)
  (reftex-plug-into-AUCTeX t))

(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

(use-package which-func
  :ensure nil
  :custom
  (which-func-unknown "")
  (frame-title-format
   '("%b" (:eval (let ((fn (and (boundp 'which-func-table)
                                (hash-table-p which-func-table)
                                (gethash (selected-window) which-func-table))))
                   (if (and (stringp fn) (not (string-empty-p fn)))
                       (concat " [" fn "]")
                     "")))))
  :config
  (which-function-mode 1)
  (setq mode-line-misc-info
        (assq-delete-all 'which-function-mode mode-line-misc-info)))

;; ----------------------------------------------------------------------------
;; Custom Navigation & Window Utilities
;; ----------------------------------------------------------------------------
(defun chrisk-beginning-of-line ()
  (interactive)
  (let ((start (point)))
    (back-to-indentation)
    (if (= start (point)) (beginning-of-line))))

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

(defun ak-match-paren (arg)
  "Go to matching parenthesis or insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

(defun ak-other-window-backward ()
  (interactive)
  (other-window -1))

(keymap-global-set "C-a"    #'chrisk-beginning-of-line)
(keymap-global-set "<home>" #'chrisk-beginning-of-line)
(keymap-global-set "%"      #'ak-match-paren)
(keymap-global-set "C-<tab>" #'other-window)
(keymap-global-set "C-S-<iso-lefttab>" #'ak-other-window-backward) ; X11
(keymap-global-set "C-S-<tab>"         #'ak-other-window-backward) ; macOS and others

;; Local additions
(load (expand-file-name "local" "~/dot-configs/emacs.d") 'noerror 'nomessage)
