;; -*- lexical-binding: t; -*-

;; Platfrom detection
(defconst ak-mac-p (eq system-type 'darwin))
(defconst ak-linux-p (eq system-type 'gnu/linux))

;; Package Archives & Bootstrapping
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Prefer official curated releases over rolling Git snapshots
(setq package-archive-priorities
      '(("gnu"    . 30)
        ("nongnu" . 20)
        ("melpa"  . 10)))

(package-initialize)
;; Built-in use-package settings
(require 'use-package)
(setq use-package-always-ensure t
      use-package-expand-minimally t)

;; Some packages store files next to init.el. Make it stop.
(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "etc/" ak-state-dir)
        no-littering-var-directory ak-state-dir))

;; Automatic Garbage Collection Management (gcmh)
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
(setq use-short-answers t)                      ; Modern (fset 'yes-or-no-p 'y-or-n-p)
(setq compilation-ask-about-save nil)           ; Save buffers without prompting
(setq enable-recursive-minibuffers t)
(setq truncate-partial-width-windows nil)       ; Wrap horizontally-split windows
(setq line-number-mode t)
(setq column-number-mode t)                     ; Show column numbers in mode line
(setq split-height-threshold nil)
(blink-cursor-mode 1)
(show-paren-mode 1)
(global-auto-revert-mode 1)
(winner-mode 1)  ; C-c + <left/right> to get back to previous window layout
(cua-mode 1)

;; Keep Customize out of init.el
(setq custom-file (expand-file-name "custom.el" ak-state-dir))
(load custom-file 'noerror 'nomessage)

;; Strips trailing whitespace across all visited files on save
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; Window navigation
(windmove-default-keybindings 'meta)  ; navigate windows with M-<arrows>
(setq windmove-wrap-around t)

;; Font configuration (handles standalone GUI and emacsclient daemon frames)
(defun ak-apply-frame-fonts (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (when (and ak-linux-p (display-graphic-p))
      (set-face-attribute 'default nil :font "Ubuntu Mono:pixelsize=15")
      (set-face-attribute 'mode-line nil :font "Ubuntu Mono:pixelsize=13"))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'ak-apply-frame-fonts)
  (ak-apply-frame-fonts))

;; ----------------------------------------------------------------------------
;; UI & Utilities
;; ----------------------------------------------------------------------------
(use-package diminish)

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1)
  :custom
  (history-delete-duplicates t)
  (savehist-save-minibuffer-history t)
  (savehist-file (expand-file-name "history" ak-state-dir)))

(use-package which-key
  :ensure nil ; Built-in in Emacs 30
  :config
  (which-key-mode 1))

(use-package zenburn-theme
  :config
  (load-theme 'zenburn t))

(global-set-key [(control shift z)] #'undo-redo) ; with cua-mode, C-z isundo
(use-package vundo
  :bind ("C-x u" . vundo)
  :config
  ;; Optional: Use prettier unicode characters to draw the tree lines
  (setq vundo-glyph-alist vundo-unicode-symbols))

(use-package recentf
  :ensure nil
  :init (recentf-mode 1)
  :custom
  (recentf-save-file (expand-file-name "recentf" ak-state-dir))
  (recentf-max-saved-items 500)
  (recentf-max-menu-items 60)
  :bind (([(meta f12)] . recentf-open-files)))

(use-package ibuffer
  :ensure nil
  :bind (("C-x C-b" . ibuffer))
  :config
  (setq ibuffer-default-sorting-mode 'filename/process))

(use-package uniquify
  :ensure nil
  :custom
  (uniquify-buffer-name-style 'post-forward-angle-brackets))

(use-package ffap
  :ensure nil
  :config
  (ffap-bindings)
  (setq ffap-url-fetcher #'browse-url-at-point))

;; Dired navigation (C-x C-j to jump to current directory)
(use-package dired-x
  :ensure nil
  :after dired
  :demand t
  :bind ("C-x C-j" . dired-jump))

;; Git interface & change navigation
(use-package magit
  :bind (("C-x C-z" . magit-status)))

(use-package diff-hl
  :hook ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode         . diff-hl-dired-mode))   ; optional: markers in Dired too
  :init
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

(use-package goto-chg
  :bind (("C-x C-/" . goto-last-change)))

(use-package jsonrpc
  :demand t)

(use-package abbrev :ensure nil :diminish)  ; no idea who turns it on
(use-package eldoc  :ensure nil :diminish)  ; no idea who turns it on

;; ----------------------------------------------------------------------------
;; Completion & Editing (Company + Ido)
;; ----------------------------------------------------------------------------
(use-package ido
  :ensure nil
  :config
  (ido-mode 'buffers)
  (setq ido-enable-flex-matching t
        ido-default-file-method 'selected-window
        ido-default-buffer-method 'selected-window))

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

(use-package company
  :diminish company-mode
  :bind (:map company-active-map
              ("<tab>" . company-complete-common-or-cycle)
              ("TAB"   . company-complete-common-or-cycle))
  :custom
  (company-transformers '(ak-delete-dabbrev-dups company-sort-by-occurrence))
  :config
  (setf (nth (cl-position 'company-capf company-backends) company-backends)
        '(company-capf company-dabbrev-code)))

(use-package company-quickhelp
  :after company
  :config
  (company-quickhelp-mode 1))

;; Spelling
(use-package spell-fu
  :disabled  ;; let me see if I can make hunspell work
  :ensure t
  :hook (prog-mode . spell-fu-mode)
  :config
  ;; 1. Use XDG Cache Directory (~/.cache/spell-fu/)
  (require 'xdg)
  (setq spell-fu-directory
        (expand-file-name "spell-fu" (xdg-cache-home)))
  ;; 2. Restrict checks strictly to code comments and strings
  (setq spell-fu-faces-include
        '(font-lock-comment-face
          font-lock-doc-face
          font-lock-string-face))
  ;; 3. Enable camelCase and snake_case sub-word splitting
  (setq spell-fu-subword-mode t))

;; sudo apt-get install hunspell hunspell-en-us
;; sudo port install hunspell hunspell-en_US   (MacPorts)
(use-package ispell
  :ensure nil
  :custom
  (ispell-program-name (executable-find "hunspell"))
  (ispell-dictionary "american"))

(use-package flyspell
  :ensure nil
  :diminish
  :hook ((text-mode . flyspell-mode)           ; prose: text, markdown, org
         (prog-mode . flyspell-prog-mode))     ; code: comments and strings only
  :bind (:map flyspell-mode-map                ; rebind from C-. to C-'
              ("C-."  . nil)
              ("C-'"  . flyspell-auto-correct-word))
  :custom
  (flyspell-persistent-highlight nil)          ; only highlight the last error found
  (flyspell-issue-welcome-flag nil)
  (flyspell-issue-message-flag nil)
  (flyspell-duplicate-distance 0))

;; Programming hooks
(add-hook 'prog-mode-hook
          (lambda ()
            (setq tab-width 2
                  indent-tabs-mode nil
                  fill-column 80
                  compilation-scroll-output t)
            (turn-on-auto-fill)
            (diminish 'auto-fill-function)
            (subword-mode 1)
            (diminish 'subword-mode)
            (company-mode 1)
            (local-set-key [tab] #'company-indent-or-complete-common)
            (local-set-key (kbd "RET") #'newline-and-indent)
            (local-set-key [C-f10] #'compile)
            (local-set-key [M-down] #'next-error)
            (local-set-key [M-up] (lambda () (interactive) (next-error -1)))))

(add-hook 'css-mode-hook (lambda () (setq css-indent-offset 2)))

(add-hook 'c-mode-common-hook
          (lambda ()
            (local-set-key (kbd "RET") #'c-context-line-break)
            (local-set-key "\C-v" (lambda () (interactive)
                                    (yank)
                                    (c-indent-defun)))))

;; ----------------------------------------------------------------------------
;; Languages & Formats (Markdown, Dot, Org)
;; ----------------------------------------------------------------------------
(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :custom
  (markdown-command "pandoc"))

(use-package flycheck
  :init
  (global-flycheck-mode 1))

(use-package graphviz-dot-mode
  :mode "\\.dot\\'")

(defun ak-org-setup ()
  "Prose-friendly display for Org buffers."
  (variable-pitch-mode 1)
  (visual-line-mode 1)
  (diminish 'visual-line-mode)
  (diminish 'buffer-face-mode))        ; the minor mode variable-pitch-mode enables

(use-package org
  :ensure nil
  :hook (org-mode . ak-org-setup)
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c b" . org-switchb))
  :custom-face
  (org-table ((t (:inherit fixed-pitch))))
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
                           ("go" . "http://go/%s")))
  :config
  ;; Show "-" list markers as bullets (from zzamboni.org/post/beautifying-org-mode-in-emacs/)
  (font-lock-add-keywords
   'org-mode
   '(("^ *\\([-]\\) "
      (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•")))))))

(use-package tex
  :ensure auctex                       ; the package is auctex, the feature is tex
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

(use-package org-bullets
  :hook (org-mode . org-bullets-mode))

(use-package real-auto-save
  :diminish real-auto-save-mode
  :hook (org-mode . real-auto-save-mode)
  :custom
  (real-auto-save-interval 30))

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

(defun ak-match-paren (arg)
  "Go to matching parenthesis or insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

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

(global-set-key "\C-a" #'chrisk-beginning-of-line)
(global-set-key [home] #'chrisk-beginning-of-line)
(global-set-key "%" #'ak-match-paren)
(global-set-key "\M-g" #'goto-line)
(global-set-key [(control tab)] #'other-window)
(global-set-key [(control shift iso-lefttab)] (lambda () (interactive) (other-window -1)))

;; Local additions
(load (expand-file-name "local" "~/dot-configs/emacs.d") 'noerror 'nomessage)
