
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

;; Bootstrap `straight.el`
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Helm
(require 'helm-config)
(helm-mode 1)

(use-package org-roam
      :hook
      (after-init . org-roam-mode)
      :straight (:host github :repo "jethrokuan/org-roam")
      :custom
      (org-roam-directory "~/org/zk")
      :bind (:map org-roam-mode-map
              (("C-c n l" . org-roam)
               ("C-c n f" . org-roam-find-file)
               ("C-c n b" . org-roam-switch-to-buffer)
               ("C-c n g" . org-roam-show-graph))
              :map org-mode-map
              (("C-c n i" . org-roam-insert)
	       )))

(use-package company-org-roam
  :straight nil
  :after org-roam company org
  :config
  (company-org-roam-init))

(use-package deft
  :after org
  :bind
  ("C-c n d" . deft)
  :custom
  (deft-recursive t)
  (deft-use-filter-string-for-filename t)
  (deft-default-extension "org")
  (deft-directory "~/org/zk"))

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

(evil-define-key 'normal org-mode-map
  (kbd "RET") 'org-open-at-point-global)

;; Colorscheme
(load-theme 'base16-onedark t)

;; Change font face/size
(set-face-attribute 'default nil :font "Iosevka" :height 170)

;; Sort by relevancy
(setq apropos-sort-by-scores t)

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
 '(org-roam-completion-system (quote default))
 '(org-roam-directory "~/org/zk")
 '(package-selected-packages (quote (helm base16-theme))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
