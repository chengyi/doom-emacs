;;; tools/gtags/config.el -*- lexical-binding: t; -*-

(defgroup gtags nil
  "Gtags related settings"
  :group 'programming)

(defcustom +gtags-enabled-modes '(c-mode c++-mode) "specify the path that gtags enable"
  :group 'gtags
  :type '(repeat symbol))

(advice-add! '(lsp!) :around
             (lambda (orig-fn &rest args)
               (if (and (projectile-project-root) (file-exists-p (concat (projectile-project-root) "GTAGS")))
                   t
                 (apply orig-fn args))))


(def-package! ggtags
  :config
  (map! :leader
        (:prefix-map ("c". "code")
          :desc "Find Symbol" "s" #'ggtags-find-other-symbol))
  (dolist (mode +gtags-enabled-modes)
    (add-hook! mode
      (ggtags-mode 1)
      (set-lookup-handlers! mode
         :definition #'ggtags-find-definition
         :references #'ggtags-find-reference))))
