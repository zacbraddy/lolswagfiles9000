;;; $DOOMDIR/config.el - *- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font(font-spec :family "JetBrains Mono" :size 20 :slant 'italic))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-outrun-electric)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Projectile settings
(setq projectile-project-search-path '("~/Projects/"))

;; Attempt at wrapping lines in folders rather than having them display off screen
(setq-default visual-line-mode)
(setq-default global-visual-line-mode)

;; Show time in the bottom corner
(display-time)
(setq display-time-day-and-date t)

;; Yaml-mode settings
(setq +format-on-save-enabled-modes '(not yaml-mode))

;; Markdown-mode settings
(setq markdown-split-window-direction 'Right)

;; tabnine company mode settings
(add-to-list 'company-backends #'company-tabnine)
(setq company-idle-delay 0)
(setq company-show-numbers t)

;; PlantUML settings

(setq plantuml-jar-path(expand-file-name "~/plantuml.jar"))
(setq plantuml-default-exec-mode 'jar)
(add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.puml\\'" . plantuml-mode))
(with-eval-after-load 'flycheck
  (require 'flycheck-plantuml)
  (flycheck-plantuml-setup))

;; vterm settings so you can install libvterm
(setq vterm-module-cmake-args "-DUSE_SYSTEM_LIBVTERM=yes")

(setq tab-width 2)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external * .el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.

(defun enable-minor-mode(my-pair)
  "Enable minor mode if filename match the regexp.  MY-PAIR is a cons cell (regexp . minor-mode)."
  (if (buffer-file-name)
      (if (string-match(car my-pair) buffer-file-name)
          (funcall(cdr my-pair)))))

(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.svelte?\\'" . prettier-js-mode))))


(map! (:when(featurep! :lang python)
       (:map elpy-mode-map :leader
        "r" 'elpy-shell-send-region-or-buffer)))

(setq flycheck-python-flake8-executable "python3")
(setq flycheck-python-pycompile-executable "python3")
(setq flycheck-flake8rc ".flake8")
;; I don't want to use pylint right now but might want to in the future
(setq flycheck-python-pylint-executable "python3")
(setq-default flycheck-disabled-checkers '(python-pylint))

;;(add-hook 'python-mode-hook 'anaconda-mode)
(add-hook 'python-mode-hook 'lsp)
(add-hook 'python-mode-hook 'python-black-on-save-mode)
(add-hook 'python-mode-hook (lambda() (add-hook 'before-save-hook 'py-isort-before-save)))

;; BEGIN COPY PASTA FROM https://github.com/flycheck/flycheck/issues/1762#issuecomment-749789589
;; Add buffer local Flycheck checkers after LSP for different major modes.
(defvar-local my-flycheck-local-cache nil)
(defun my-flycheck-local-checker-get (fn checker property)
  ;; Only check the buffer local cache for the LSP checker, otherwise we get
  ;; infinite loops.
  (if (eq checker 'lsp)
      (or (alist-get property my-flycheck-local-cache)
          (funcall fn checker property))
    (funcall fn checker property)))
(advice-add 'flycheck-checker-get
            :around 'my-flycheck-local-checker-get)
(add-hook 'lsp-managed-mode-hook
          (lambda ()
            (when (derived-mode-p 'python-mode)
              (setq my-flycheck-local-cache '((next-checkers . (python-flake8)))))))
;; END COPY PASTA

(setq elpy-rpc-python-command "python3")

(elpy-enable)

(add-hook 'js2-mode-hook 'prettier-js-mode)

(exec-path-from-shell-initialize)
(setq multi-term-program "/bin/zsh")

(yas/initialize)
;; (yas/load-directory "~/.emacs.d/snippets")

(global-undo-tree-mode)
(evil-set-undo-system 'undo-tree)
