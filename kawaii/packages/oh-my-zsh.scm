(define-module (kawaii packages oh-my-zsh)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages tmux)
  #:use-module (gnu packages ruby)
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
   (home-page "https://github.com/LeonidPilyugin/kawaii-oh-my-zsh")
   (arguments
     (list
       #:install-plan
         #~(list '("files/kawaii.zsh-theme" "share/zsh/plugins/oh-my-zsh/themes/"))))
   (inputs (list oh-my-zsh))))

(define-public kawaii-zsh-syntax-highlighting
  (package
    (inherit zsh-syntax-highlighting)
    (name "kawaii-zsh-syntax-highlighting")
    (native-inputs
     (list zsh coreutils grep oh-my-zsh))
    (arguments
     ;; FIXME: Tests have expected failures (easy way to skip just those tests?)
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'patch-paths
            (lambda _
              (substitute* "Makefile"
                (("/usr/local") #$output)
                (("share/\\$\\(NAME\\)") "share/zsh/plugins/oh-my-zsh/plugins/$(NAME)")
                (("env -i") "env -i PATH=$$PATH"))))
          (add-after 'patch-paths 'make-writable
            (lambda _
              (for-each make-file-writable
                        '("docs/highlighters.md"
                          "README.md"))))
          (add-before 'build 'add-all-md
            (lambda _
              (invoke "make" "all")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "make" "test" (string-append "ZSH=" #$zsh "/bin/zsh"))
                (invoke "make" "perf" (string-append "ZSH=" #$zsh "/bin/zsh"))))))))))


(define-public kawaii-zsh-autosuggestions
  (package
    (inherit zsh-syntax-autosuggestions)
    (name "kawaii-zsh-autosuggestions")
    (native-inputs
     (list ruby
           ruby-pry
           ruby-rspec
           ruby-rspec-wait
           tmux
           zsh
           oh-my-zsh))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-tests
            (lambda _
              ;; Failing tests since tmux-3.2a
              (delete-file "spec/options/buffer_max_size_spec.rb")))
          (delete 'configure)
          (replace 'check ; Tests use ruby's bundler; instead execute rspec directly.
            (lambda _
              (setenv "TMUX_TMPDIR" (getenv "TMPDIR"))
              (setenv "SHELL" (which "zsh"))
              (invoke "rspec")))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (zsh-plugins
                      (string-append out "/share/zsh/plugins/oh-my-zsh/plugins/zsh-autosuggestions")))
                (invoke "make" "all")
                (install-file "zsh-autosuggestions.zsh" zsh-plugins)))))))))

