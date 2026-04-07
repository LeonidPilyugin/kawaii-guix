(define-module (kawaii packages llama-cpp)
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
            (add-after 'unpack 'fix-tests
              (lambda _
                ;; test-thread-safety downloads ML model from network,
                ;; cannot run in Guix build environment
                (substitute* '("tests/CMakeLists.txt")
                  (("llama_build_and_test\\(test-thread-safety.cpp.*")
                   "")
                  (("set_tests_properties\\(test-thread-safety.*")
                   "")
                  (((string-append "llama_build_and_test\\"
                                   "(test-state-restore-fragmented.cpp.*"))
                   "")
                  (("set_tests_properties\\(test-state-restore-fragmented.*")
                   "")
                  (("llama_build_and_test\\(test-llama-archs.cpp.*")
                   "")
                  (("set_tests_properties\\(test-download-model.*")
                   (string-append "set_tests_properties(test-download-model "
                                  " PROPERTIES DISABLED TRUE)"))
                  (("llama_build_and_test\\(test-chat.cpp.*")
                   "")
                  ;; error while handling argument "-m": expected value for
                  ;; argument
                  (("llama_build_and_test\\(test-arg-parser.cpp.*")
                   ""))
                ;; test-eval-callback downloads ML model from network, cannot
                ;; run in Guix build environment
                (substitute* '("examples/eval-callback/CMakeLists.txt")
                  (("COMMAND llama-eval-callback")
                   "COMMAND true llama-eval-callback")
                  (("download-model COMMAND")
                  "download-model COMMAND true"))
                ;; Help it find the test files it needs
                (substitute* "tests/test-chat.cpp"
                  (("\"\\.\\./\"") "\"../source/\""))))
            (add-after 'install 'remove-tests
              (lambda _
                (for-each delete-file
                          (find-files (string-append #$output "/bin")
                                      "^test-"))))
            ;; This phase and coreutils are needed to reduce the closure size
            ;; of this package. Remove them when not needed anymore.
            (add-after 'patch-shebangs 'fix-python-shebang
              (lambda* (#:key inputs #:allow-other-keys)
                (substitute* (string-append #$output
                                            "/bin/convert_hf_to_gguf.py")
                  (("^#!.*/bin/python3")
                   (string-append "#!" (search-input-file inputs "bin/env")
                                  " python3"))))))))
  (inputs (list coreutils ggml openssl cuda-12.8 nvda))
  (native-inputs (list python python-jinja2))))
