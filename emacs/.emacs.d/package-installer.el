;; -*- lexical-binding: t; -*-
(require 'package)

(setq package-archives (nconc package-archives
      '(; unreachable on 2021-01-26 ("marmalade" . "https://marmalade-repo.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ; ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        )))

(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(setq package-selected-packages (nconc package-selected-packages
  '(graphviz-dot-mode    ; graphviz Dot language
    zenburn-theme
    ; auto-complete        ; complete as you type with overlays
    undo-tree            ; treat undo history as a tree
    auto-package-update  ; automatically update ELPA packages on startup
    ; ivy-xref
    company
    company-quickhelp
    org-bullets
    diminish
    which-key
    real-auto-save
    markdown-mode
 )))
(package-install-selected-packages)
(auto-package-update-maybe)

   ; dot-mode					 ; like ctrl+. in vi (repeat last cmd)
	 ; switch-window		 ; takes over C-x o
	 ; redo+
	 ; minibuf-isearch - still need?

   ; currently broken (does not compile)?	 (2013-10-30)
   ; magit										 ; git support
	 ; color-theme ;; not using anymore?
	 ; WTF is this?
	 ; emacs-goodies-el					 ; misc emacs add-ons

	 ;; Ruby stuff which I currently have no use for
	 ;; inf-ruby									; inferior ruby mode
	 ;; ruby-compilation					; run ruby process in compilation buffer
	 ;; ;; Rinari, textmate, ECB have all been mentioned as being useful
	 ;; ;; for Ruby/Rails. They all are heavyweight; textmate is the thinnest
	 ;; ;; of them and provides all of the functionality I need at the moment.
	 ;; textmate
	 ;; ;;; if rinari is ever turned on, nxhtml should be reinstalled as it
	 ;; ;;; seems to do things differently based on rinari's presense
	 ;; ; rinari									; ruby IDE
	 ;; ; ecb											; emacs code browser

	 ;; ; http://rinari.rubyforge.org/Rhtml-Setup.html#Rhtml-Setup
	 ;; ; says that nxhtml is better than rhtml
	 ;; nxhtml										; provides Mumamo among other HTML utils
	 ;; ; rhtml-mode							; major mode for RHTML (.html.erb) files
	 ;; yaml-mode
	 ;; ; psvn										; svn-status
	 ;; ; yasnippet								; textmate-like snippet mode
	 ;; ;; think about how to integrate it with google-compile?
	 ;; ; mode-compile								 ; mode-specific compile support
	 ;; rvm
