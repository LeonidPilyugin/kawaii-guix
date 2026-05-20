(define-module (kawaii packages lutris)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages python)
  #:use-module (gnu packages glib)
  #:use-module (guix-science-nonfree packages cuda-modules)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages base))

(define-public lutris
  (package
   (name "lutris")
   (version "0.5.13")
   (source (origin
	    (method git-fetch)
	    (uri (git-reference
		  (url "https://github.com/lutris/lutris")
		  (commit (string-append "v" version))))
	    (sha256 (base32 "178765i7y4wc2pgjk14hf4z4pmq884xbq6hrgqm14gi4n9ynpjvr"))))
   (build-system gnu-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
		     (delete 'configure)
		     (delete 'check)
		     (delete 'build)
		     (replace 'install
			      (lambda* (#:key inputs outputs #:allow-other-keys)
				       (let* ((out (assoc-ref outputs "out"))
					      (src (assoc-ref inputs "source")))
					 (mkdir-p (string-append out "/bin"))
					 (invoke "ln" "-sf" (string-append src "/bin/lutris") (string-append out "/bin/lutris"))
					 )))
		     (replace 'patch-dot-desktop-files
			      (lambda* (#:key inputs outputs #:allow-other-keys)
				       (let* ((out (assoc-ref outputs "out"))
					      (src (assoc-ref inputs "source")))
					 (mkdir-p (string-append out "/share/applications"))
					 (map (lambda (icondir)
						(mkdir-p (string-append out "/share/icons/hicolor/" icondir "/apps"))
						(invoke "ln" "-sf" (string-append src "/share/icons/hicolor/" icondir "/apps/lutris.png")
						      (string-append out "/share/icons/hicolor/" icondir "/apps/lutris.png")))
					      '("16x16"
						"22x22"
						"24x24"
						"32x32"
						"48x48"
						"64x64"
						"128x128"
						"scalable"))
					 (invoke "ln"
						 "-sf"
						 (string-append src "/share/lutris")
						 (string-append out "/share/lutris"))
					 (mkdir-p (string-append out "/metainfo"))
					 (invoke "ln" "-sf" (string-append src "/metainfo/net.lutris.Lutris.metainfo.xml")
					       (string-append out "/metainfo/net.lutris.Lutris.metainfo.xml"))
					 (mkdir-p (string-append out "/man/man1"))
					 (invoke "ln" "-sf" (string-append src "/man/man1/lutris.1")
					       (string-append out "/man/man1/lutris.1"))
					 )))
		     )))
   (inputs `(("python" ,python)
	     ("python-pyyaml", python-pyyaml)
	     ("python-pygobject", python-pygobject)
	     ;; Add more dependencies
	     ;; @see https://github.com/lutris/lutris/blob/master/INSTALL.rst
	     ))
   (native-inputs `(("tar" ,tar)))
   (home-page "https://lutris.net")
   (synopsis "Open gaming platform for Linux")
   (description "Lutris is an open gaming platform for Linux that provides a unified interface for installing, configuring, and launching games.")
   (license gpl3+)))
