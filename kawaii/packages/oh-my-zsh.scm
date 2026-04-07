(define-module (kawaii packages zsh)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix git))

(define-public oh-my-zsh
  (let ((rev "80fa5e137672a529f65a05e396b40f0d133b2432"))
    (package
      (name "oh-my-zsh")
      (version "20240905")
      (source
       (origin (method git-fetch)
               (uri (git-reference
                     (url "https://github.com/ohmyzsh/ohmyzsh")
                     (commit rev)))
               (file-name (git-file-name name version))
               (sha256 (base32 "1s4srg6gk9r0z7yrd9ar3164af11ildxnmk6q8p5dpkwq9j1r7iq"))))
      (build-system copy-build-system)
      (home-page "https://ohmyz.sh/")
      (synopsis "Oh My Zsh configuration framework")
      (description
       "This package provides Oh My Zsh configuration framework for zsh.")
      (license license:expat-0)
      (arguments (list #:install-plan
                       #~(cons (list "oh-my-zsh.sh" "share/zsh/plugins/oh-my-zsh/oh-my-zsh.zsh")
                               (map (lambda (d) `(,d "share/zsh/plugins/oh-my-zsh/"))
				    '("cache" "custom""lib" "log" "plugins"
				      "templates" "themes""tools"))))))))

(define-public kawaii-oh-my-zsh
  (package
   (name "kawaii-oh-my-zsh")
   (version "1.7")
   (source
    (origin (method git-fetch)
            (uri (git-reference
                  (url "https://github.com/LeonidPilyugin/kawaii-oh-my-zsh")
                  (commit "v1.7")))
            (file-name (git-file-name name version))
            (sha256 (base32 "09yhhr59fmx39a1scnzlvcrrbnqf4a2v89idzkmwp7i7vsaxk43f"))))
   (build-system copy-build-system)
   (synopsis "Kawaii zsh theme")
   (description "This package provides kawaii zsh theme.")
   (license license:expat-0)
   (arguments
     (list
       #:install-plan
         ("files/kawaii.zsh-theme" "share/zsh/themes/kawaii.zsh-theme")))))
