(define-module (emacs-master)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages web)
  #:use-module (guix git)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public emacs-master
  (package (inherit emacs)
    (name "emacs-master")
    (source (origin
             (method git-fetch)
             (uri (git-checkout (url "https://git.savannah.gnu.org/git/emacs.git")
                                (recursive? #t)))
             (file-name (string-append name "-master"))
             (sha256 #f)))
    (inputs
      `(("jansson" ,jansson)
        ,@(package-inputs emacs)))))
