(define-module (kawaii packages sing-box)
  ;; Utilities
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  ;; Guix origin methods
  #:use-module (guix git-download)
  ;; Guix build systems
  #:use-module (guix build-system go)
  ;; Guix packages
  #:use-module (gnu packages base)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages linux))


(define* (go-mod-vendor #:key go)
  (lambda* (src hash-algo hash #:optional name #:key (system (%current-system)))
    (define nss-certs
      (module-ref (resolve-interface '(gnu packages nss)) 'nss-certs))

    (gexp->derivation
     (or name "vendored-go-dependencies")
     (with-imported-modules %default-gnu-imported-modules
       #~(begin
           (use-modules (guix build gnu-build-system)
                        (guix build utils))
           ;; Support Unicode in file name.
           (setlocale LC_ALL "C.UTF-8")
           ;; For HTTPS support.
           (setenv "SSL_CERT_DIR" #+(file-append nss-certs "/etc/ssl/certs"))

           ((assoc-ref %standard-phases 'unpack) #:source #+src)
           (invoke #+(file-append go "/bin/go") "mod" "vendor")
           (copy-recursively "vendor" #$output)))
     #:system system
     #:hash-algo hash-algo
     #:hash hash
     ;; Is a directory.
     #:recursive? #t
     #:env-vars '(("GOCACHE" . "/tmp/go-cache")
                  ("GOPATH" . "/tmp/go"))
     ;; Honor the user's proxy and locale settings.
     #:leaked-env-vars '("GOPROXY"
                         "http_proxy" "https_proxy"
                         "LC_ALL" "LC_MESSAGES" "LANG"
                         "COLUMNS")
     #:local-build? #t)))

(define-public sing-box
  (package
    (name "sing-box")
    (version "1.11.15")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/SagerNet/sing-box")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1i5zfafbc21m0hn0sysn2pqpkp0v84dzlz2haxli3pm4y7fdb8xs"))))
    (build-system go-build-system)
    (arguments
     (list
      #:tests? (not (%current-target-system)) ;TODO: Run test suite.
      #:go go-1.23
      #:install-source? #f
      #:import-path "./cmd/sing-box"
      #:build-flags
      #~(list "-tags" (string-join
                       '("with_gvisor"
                         "with_quic"
                         "with_wireguard"
                         "with_utls"
                         "with_reality_server"
                         "with_clash_api"
                         "with_ech"
                         "with_acme"
                         "with_dhcp"))
              "-mod=readonly"
              "-modcacherw"
              "-v"
              "-trimpath"
              "-buildmode=pie"
              (string-append
               "-ldflags="
               " -X github.com/sagernet/sing-box/constant.Version="
               #$(package-version this-package)))
      #:modules
      '((ice-9 match)
        ((guix build gnu-build-system) #:prefix gnu:)
        (guix build go-build-system)
        (guix build utils))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda args
              (unsetenv "GO111MODULE")
              (apply (assoc-ref gnu:%standard-phases 'unpack) args)
              (copy-recursively
               #+(this-package-native-input "vendored-go-dependencies")
               "vendor")))
          (replace 'install-license-files
            (assoc-ref gnu:%standard-phases 'install-license-files))
          (add-after 'unpack 'set-tailscale-default-wireguard-port
            (lambda _
              ;; See also: https://tailscale.com/kb/1082/firewall-ports
              ;; https://github.com/tailscale/tailscale/blob/51c11a864b1241d1cf1a736fbc94b0f8c76da563/cmd/tailscaled/tailscaled.go#L102
              (substitute* "vendor/github.com/sagernet/tailscale/tsnet/tsnet.go"
                (("s\\.Port") "41641"))))
          (add-after 'install 'install-extras
            (lambda _
              (let ((sing-box
                     (or (which "sing-box")
                         (in-vicinity #$output "bin/sing-box"))))
                (map
                 (match-lambda
                   ((shell . path)
                    (let ((file (in-vicinity #$output path)))
                      (mkdir-p (dirname file))
                      (with-output-to-file file
                        (lambda ()
                          (invoke sing-box "completion" shell))))))
                 '(("bash" . "etc/bash_completion.d/sing-box")
                   ("fish" . "share/fish/vendor_completions.d/sing-box.fish")
                   ("zsh"  . "share/zsh/site-functions/_sing-box")))))))))
    (native-inputs
     (append
      (list (origin
              (method (go-mod-vendor #:go go-1.23))
              (uri (package-source this-package))
              (file-name "vendored-go-dependencies")
              (sha256
               (base32
                "0h3m4rfkwdcm22f8vbdl3idki46nxfmynagvy7s00lycylz1f809"))))
      (if (%current-target-system)
          (list this-package)
          '())))
    (home-page "https://sing-box.sagernet.org/")
    (synopsis "Universal proxy platform")
    (description
     "@command{sing-box} is a customizable and univsersal proxy platform that
can be used to create network proxy servers, clients and transparent proxies.")
    (license license:gpl3+)))
