(define-module (kawaii packages ollama)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (nongnu packages nvidia)
  #:use-module (guix-science-nonfree packages cuda)
  #:use-module (gnu packages machine-learning))

(define-public llama-cpp-cuda
  (package
    (inherit llama-cpp)
    (name "llama-cpp-cuda")
    (arguments
      (list #:configure-flags
        	#~(list
          "-DBUILD_SHARED_LIBS=ON"
          "-DGGML_CUDA=ON"
          (string-append "-DCMAKE_CUDA_COMPILER=" #+(file-append cuda-12.8 "/bin/nvcc")))
      #:phases
          #~(modify-phases %standard-phases
          (delete 'check)
          (add-after 'install 'remove-tests
            (lambda _
              (for-each delete-file
                (find-files (string-append #$output "/bin") "^test-"))))
          (add-after 'patch-shebangs 'fix-python-shebang
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute*
                (string-append #$output "/bin/convert_hf_to_gguf.py")
                (("^#!.*/bin/python3")
                  (string-append "#!" (search-input-file inputs "bin/env") " python3"))))))))
    (inputs (list coreutils ggml openssl cuda-12.8 nvda))
    (native-inputs (list python python-jinja2))))
