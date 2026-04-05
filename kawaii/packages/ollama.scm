(define-module (kawaii packages ollama)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build utils)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages cmake)
  #:use-module ((guix licenses) #:prefix license:))

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
    (build-system trivial-build-system)
    (arguments
      `(#:modules ((guix)
                   (guix config)
                   (guix utils)
                   (guix licenses)
                   (guix packages)
                   (guix memoization)
                   (guix build utils)
                   (gnu packages golang)
                   (gnu packages cmake))
        #:builder
        (begin
          (use-modules
            (guix)
            (guix config)
            (guix utils)
            (guix packages)
            (guix licenses)
            (guix memoization)
            (guix build utils)
            (gnu packages golang)
            (gnu packages cmake))
          (invoke #+(file-append cmake-minimal "/bin/cmake")
            "-B" "build" "-D" "CMAKE_BUILD_TYPE=Release"
            "-D" "CMAKE_CUDA_ARCHITECTURES=\"50;52;53;60;61;62;70;72;75;80;86;87;89;90;90a\"")
          (invoke #+(file-append cmake-minimal "/bin/cmake" "--build" "build"))
          (invoke go-1.23 "build" ".")
          (setenv "DESTDIR" %outputs)
          (invoke #+(file-append cmake-minimal "/bin/cmake")
            "--install" "ollama/build" "--component" "CUDA"))))

    (home-page "https://ollama.com")
    (synopsis "Get up and running with large language models")
    (description
     "Get up and running with large language models.
Run Llama 2, Code Llama, and other models. Customize and create your own.")
    (license license:expat)))

