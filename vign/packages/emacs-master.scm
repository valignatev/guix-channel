(define-module (vign packages emacs-master)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages web)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public emacs-git
  (let ((commit "d57bb0c323c326518d9cc974dc794f9e23a51917")
        (revision "0"))
    (package (inherit emacs)
      (name "emacs-git")
      (version (git-version "27" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                       (url "https://git.savannah.gnu.org/git/emacs.git")
                       (commit commit)
                       (recursive? #t)))
                (file-name (git-file-name name version))
                (patches (search-patches
                           "emacs-fix-scheme-indent-function.patch"
                           "emacs-source-date-epoch.patch"))
                (sha256
                  (base32 "0biv77p80kc1fwyc3fsi2343na6x9xp0pw9q6fv3vggna7rvwlbi"))
                (modules (origin-modules (package-source emacs)))
                (snippet
                  ;; Delete the bundled byte-compiled elisp files and
                  ;; generated autoloads.
                  '(with-directory-excursion "lisp"
                    (for-each delete-file
                              (append (find-files "." "\\.elc$")
                                      (find-files "." "loaddefs\\.el$")))

                    ;; Make sure Tramp looks for binaries in the right places on
                    ;; remote Guix System machines, where 'getconf PATH' returns
                    ;; something bogus.
                    (substitute* "net/tramp-sh.el"
                                 ;; Patch the line after "(defcustom tramp-remote-path".
                                 (("\\(tramp-default-remote-path")
                                  (format #f "(tramp-default-remote-path ~s ~s ~s ~s "
                                          "~/.guix-profile/bin" "~/.guix-profile/sbin"
                                          "/run/current-system/profile/bin"
                                          "/run/current-system/profile/sbin")))

                    ;; Make sure Man looks for C header files in the right
                    ;; places.
                    (substitute* "man.el"
                      (("\"/usr/local/include\"" line)
                       (string-join
                         (list line
                               "\"~/.guix-profile/include\""
                               "\"/var/guix/profiles/system/profile/include\"")
                         " ")))
                    #t))))
      (arguments
        (substitute-keyword-arguments (package-arguments emacs)
          ((#:configure-flags cf)
           `(append ,cf '("--with-cairo" "--enable-link-time-optimization")))
          ((#:phases phases)
           `(modify-phases ,phases
             (add-before 'reset-gzip-timestamps 'make-compressed-files-writable
                         (lambda _
                           (for-each make-file-writable
                                     (find-files %output ".*\\.t?gz$"))
                           #t))
             (add-after 'glib-or-gtk-wrap 'restore-emacs-pdmp
               (lambda* (#:key outputs target #:allow-other-keys)
                 (let* ((libexec (string-append (assoc-ref outputs "out")
                                                "/libexec"))
                        (pdmp (find-files libexec "^emacs\\.pdmp$"))
                        (pdmp-real (find-files libexec "^\\.emacs\\.pdmp-real$")))
                   (for-each (lambda (wrapper real)
                               (delete-file wrapper)
                               (rename-file real wrapper))
                             pdmp pdmp-real)
                   #t)))))))
      (inputs
        `(("jansson" ,jansson)
          ,@(package-inputs emacs)))
      (native-inputs
        `(("autoconf" ,autoconf)
          ("perl" ,perl)
          ("python" ,python-3)
          ("rc" ,rc)
          ,@(package-native-inputs emacs))))))

emacs-git
