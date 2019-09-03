;;; core/cli/patch-macos.el -*- lexical-binding: t; -*-

(defcli! patch-macos ()  ; DEPRECATED
  "Patches Emacs.app to respect your shell environment.

WARNING: This command is deprecated. Use 'doom env' instead.

A common issue with GUI Emacs on MacOS is that it launches in an environment
independent of your shell configuration, including your PATH and any other
utilities like rbenv, rvm or virtualenv.

This patch fixes this by patching Emacs.app (in /Applications or
~/Applications). It will:

  1. Move Contents/MacOS/Emacs to Contents/MacOS/RunEmacs
  2. And replace Contents/MacOS/Emacs with the following wrapper script:

     #!/user/bin/env bash
     args=\"$@\"
     pwd=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\"; pwd -P)\"
     exec \"$SHELL\" -l -c \"$pwd/RunEmacs $args\"

This ensures that Emacs is always aware of your shell environment, regardless of
how it is launched.

It can be undone with the --undo or -u options.

Alternatively, you can install the exec-path-from-shell Emacs plugin, which will
scrape your shell environment remotely, at startup. However, this can be slow
depending on your shell configuration and isn't always reliable."
  :hidden t
  (doom-patch-macos (or (member "--undo" args)
                        (member "-u" args))
                    (doom--find-emacsapp-path)))


;;
;; Library

(defun doom--find-emacsapp-path ()
  (or (getenv "EMACS_APP_PATH")
      (cl-loop for dir in (list "/usr/local/opt/emacs"
                                "/usr/local/opt/emacs-plus"
                                "/Applications"
                                "~/Applications")
               for appdir = (concat dir "/Emacs.app")
               if (file-directory-p appdir)
               return appdir)
      (user-error "Couldn't find Emacs.app")))

(defun doom-patch-macos (undo-p appdir)
  "Patches Emacs.app to respect your shell environment."
  (unless IS-MAC
    (user-error "You don't seem to be running MacOS"))
  (unless (file-directory-p appdir)
    (user-error "Couldn't find '%s'" appdir))
  (let ((oldbin (expand-file-name "Contents/MacOS/Emacs" appdir))
        (newbin (expand-file-name "Contents/MacOS/RunEmacs" appdir)))
    (cond (undo-p
           (unless (file-exists-p newbin)
             (user-error "Emacs.app is not patched"))
           (copy-file newbin oldbin 'ok-if-already-exists nil nil 'preserve-permissions)
           (unless (file-exists-p oldbin)
             (error "Failed to copy %s to %s" newbin oldbin))
           (delete-file newbin)
           (message "%s successfully unpatched" appdir))

          ((file-exists-p newbin)
           (user-error "%s is already patched. Use 'doom patch-macos --undo' to unpatch it"
                       appdir))

          ((user-error "patch-macos has been disabled. Please use 'doom env refresh' instead")))))
