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
(require 'cl-lib)  ;; Common List utilities needed for other cl-*` functions
(setq use-package-always-ensure t
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
(setq use-short-answers t)                      ; Modern (fset 'yes-or-no-p 'y-or-n-p)
(setq compilation-ask-about-save nil)           ; Save buffers without prompting
(setq truncate-partial-width-windows nil)       ; Wrap horizontally-split
(setq enable-recursive-minibuffers t)
;; Given enable-recursive-minibuffers, a new minibuffer command can be started
;; while another one is still waiting for input (e.g. find-file). The nested
;; prompt looks identical to the outer one, so it's easy to lose track of how
;; many are open. This mode prefixes the prompt with the nesting depth
;; (something like "[2]"), to indicate there's an unfinished prompt underneath.
(minibuffer-depth-indicate-mode 1)

(setq split-height-threshold nil)
(column-number-mode 1)                       ; Show column numbers in mode line
(line-number-mode 1)
(blink-cursor-mode 1)
(show-paren-mode 1)
(global-auto-revert-mode 1)
(winner-mode 1)  ; C-c + <left/right> to get back to previous window layout
(repeat-mode 1)  ; M-g n, then n/p to repeat
(cua-mode 1)

;; Keep Customize out of init.el
(setq custom-file (expand-file-name "custom.el" ak-state-dir))
(load custom-file 'noerror 'nomessage)

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
  (setq vundo-glyph-alist vundo-unicode-symbols))

(use-package recentf
  :ensure nil
  :init (recentf-mode 1)
  :custom
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

(use-package abbrev :ensure nil :diminish)  ; no idea who turns it on
(use-package eldoc  :ensure nil :diminish)  ; no idea who turns it on

;; ----------------------------------------------------------------------------
;; Completion & Editing (Company + Ido)
;; ----------------------------------------------------------------------------
;; (use-package ido
;;   :ensure nil
;;   :config
;;   (ido-mode 'buffers)
;;   (setq ido-enable-flex-matching t
;;         ido-default-file-method 'selected-window
;;         ido-default-buffer-method 'selected-window))

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
  (setq vertico-resize t          ; Grow and shrink minibuffer dynamically
        vertico-cycle t))         ; Go back to top when hitting the bottom

; get Jinx completions into Vertico
(with-eval-after-load 'vertico
  (require 'vertico-multiform)
  (add-to-list 'vertico-multiform-categories
               '(jinx grid (vertico-grid-annotate . 20) (vertico-count . 4)))
  (vertico-multiform-mode))

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

;; 4. Enhanced Search and Navigation Commands
;; This provides the "Swiper-like" experience for Vertico
;; Claude version
;; (use-package consult
;;   :bind (("C-x b" . consult-buffer)       ; replaces switch-to-buffer
;;          ("M-s l" . consult-line)
;;          ("M-s r" . consult-ripgrep)
;;          ("M-g g" . consult-goto-line)    ; works now that M-g is a prefix again
;;          ("M-g i" . consult-imenu)
;;          ("M-y"   . consult-yank-pop)))
(use-package consult
  :disabled
  :bind (;; Replace standard buffer/file switching with rich preview versions
         ("C-x b" . consult-buffer)                ; Enhanced buffer list
         ("M-y" . consult-yank-pop)                ; Interactive kill-ring (paste history)

         ;; Search tools (The Ivy/Swiper equivalents)
         ("C-s" . consult-line)                    ; Interactive line search in current buffer
         ("M-s r" . consult-ripgrep)               ; Search through project using ripgrep
         ("M-g g" . consult-goto-line))            ; Go to line with live preview
)

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

(use-package jinx
  :diminish
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

;; Get a message instead of an error if jinx is unavaialble
(defun ak-enable-jinx ()
  (with-demoted-errors "jinx: %S" (jinx-mode 1)))

;; Programming mode tweaks
(setopt compilation-scroll-output t)

(defun ak-prog-mode-setup ()
  "Per-buffer settings for programming modes."
  (setq-local tab-width 2
              indent-tabs-mode nil
              fill-column 80)
  (turn-on-auto-fill)
  (diminish 'auto-fill-function)
  (subword-mode 1)
  (diminish 'subword-mode)
  (company-mode 1))
(add-hook 'prog-mode-hook #'ak-prog-mode-setup)

;; Bound once in the shared map. A mode's own map overrides prog-mode-map.
(keymap-set prog-mode-map "<tab>"   #'company-indent-or-complete-common) ; temporary, until migrate away from company
(keymap-set prog-mode-map "C-<f10>" #'compile)

(defun ak-c-indent-after-paste (&rest _)
  "Re-indent the surrounding defun after pasting in a CC Mode buffer."
  (when (derived-mode-p 'c-mode 'c++-mode 'objc-mode 'java-mode)
    (with-demoted-errors "c-indent-defun: %S"
      (c-indent-defun))))
(advice-add 'cua-paste :after #'ak-c-indent-after-paste)

(with-eval-after-load 'cc-mode
  (keymap-set c-mode-base-map "RET" #'c-context-line-break))

(use-package css-mode
  :ensure nil
  :custom (css-indent-offset 2))

;; Trim trailing whitespace only on lines I edited, everywhere except
;; for Markdown, because in Markdown adding two or more spaces means <br>
(use-package ws-butler
  :diminish
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
