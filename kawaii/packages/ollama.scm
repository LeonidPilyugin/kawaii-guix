(define-module (kawaii packages ollama)
  #:use-module (guix)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system go)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public ollama-nvidia
  (package
    (name "ollama-nvidia")
    (version "0.20.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
        (url "https://github.com/ollama/ollama.git")
        (commit "v0.20.0")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1ri83pc0v82r1pq7lm5v6qwkmab62nlwm23162p3zcg5smfqy0j1"))))
    (build-system cmake-build-system)
    (arguments
      (list
        #:configure-flags
        #~(list "-D CMAKE_CUDA_ARCHITECTURES=\"75;80;86;87;88;89;90;100;103;110;120;121;121-virtual\"")
        #:build-type "Release"
      #:phases
      #~(modify-phases %standard-phases
        (delete 'check)
        (delete 'validate-runpath)
        (add-after 'build 'build-go go-build))))
    (home-page "https://ollama.com")
    (synopsis "Get up and running with large language models")
    (description
     "Get up and running with large language models.
Run Llama 2, Code Llama, and other models. Customize and create your own.")
    (license license:expat)))

