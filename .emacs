
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(require 'package)
(setq package-check-signature nil)

(setq package-archives
  '(("gnu" . "http://elpa.gnu.org/packages/")
    ("melpa-stable" . "https://stable.melpa.org/packages/")))

(package-initialize)
(package-refresh-contents)

;; evil
(unless (package-installed-p 'evil)
  (package-install 'evil))

(require 'evil)
(evil-mode 1)

;; evil-leader
(unless (package-installed-p 'evil-leader)
  (package-install 'evil-leader))
(require 'evil-leader)
(global-evil-leader-mode)

(evil-leader/set-leader ";")
(evil-leader/set-key
  "r" 'revert-buffer)

;; Colorscheme
(load-theme 'base16-onedark t)

;; Change font face/size
(set-face-attribute 'default nil :font "Iosevka" :height 170)

;; Sort by relevancy
(setq apropos-sort-by-scores t)

;; Enable ido
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(setq ido-use-filename-at-point 'guess)
(setq ido-create-new-buffer 'always)
(ido-mode 1)

;; Start maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Stop cursor from blinking
(blink-cursor-mode 0)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ido-enable-flex-matching t)
 '(ido-mode (quote both) nil (ido))
 '(package-selected-packages (quote (base16-theme))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
