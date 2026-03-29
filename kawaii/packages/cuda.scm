;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (kawaii packages cuda)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build utils)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module (guix-science-nonfree build-system cuda)
  #:use-module ((guix-science-nonfree build-system utils)
                #:select (url-fetch/non-substitutable))
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((guix-science-nonfree licenses) #:prefix nonfree:)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-check)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-xyz)
  #:use-module (past packages linux)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (cuda-13))

(define* (make-cuda cuda-version cuda-origin
                    ;; Some CUDA versions are not compatible with
                    ;; newer Linux kernel headers (see
                    ;; https://github.com/Pang-Yatian/Point-MAE/issues/63
                    ;; and
                    ;; https://github.com/Pang-Yatian/Point-MAE/pull/64/files).
                    #:key (gcc gcc) (linux-headers #f))
  (let* ((cuda>=11? (version>=? cuda-version "11"))
         (cuda>=12.6? (version>=? cuda-version "12.6"))
         (cuda>=13? (version>=? cuda-version "13")))
    (package
      (name "cuda-toolkit")
      (version cuda-version)
      (source cuda-origin)
      (supported-systems '("x86_64-linux"))
      (build-system gnu-build-system)
      (arguments
       (list
        #:modules '((guix build utils)
                    (guix build gnu-build-system)
                    (ice-9 match)
                    (ice-9 ftw)
                    (srfi srfi-1)
                    (srfi srfi-34))

        ;; Let's not publish or obtain substitutes for that.
        #:substitutable? #f

        #:strip-binaries? #f            ;no need

        ;; XXX: This would check DT_RUNPATH, but patchelf populate DT_RPATH,
        ;; not DT_RUNPATH.
        #:validate-runpath? #f

        #:tests? (not cuda>=13?)

        #:phases
        #~(modify-phases %standard-phases
            (replace 'unpack
              (lambda* (#:key inputs #:allow-other-keys)
                (let ((source (assoc-ref inputs "source")))
                  (invoke "sh" source "--keep" "--noexec")
                  (chdir "pkg"))
                ;; CUDA 10 specifics.
                (unless #$cuda>=11?
                  ;; Fix compilation error.
                  (substitute* "builds/cuda-toolkit/include/cuda_fp16.hpp"
                    (("\\(::isinf") "(std::isinf")))
                ;; Remove things we have no use for.
                (when #$cuda>=11?
                  (with-directory-excursion "builds"
                    (for-each delete-file-recursively
                              '("nsight_compute" "nsight_systems" "cuda_gdb"))))
                ;; Fix glibc-2.41 incompatibility issue
                ;; https://forums.developer.nvidia.com/t/error-exception-specification-is-incompatible-for-cospi-sinpi-cospif-sinpif-with-glibc-2-41/323591?u=epk
                (let ((math-functions-file
                       (if #$cuda>=11?
                         (if #$cuda>=13?
                           "builds/cuda_cudart/targets/x86_64-linux/include/math_functions.h"
                           "builds/cuda_nvcc/targets/x86_64-linux/include/crt/math_functions.h")
                         "builds/cuda-toolkit/targets/x86_64-linux/include/crt/math_functions.h")))
                  (substitute* math-functions-file
                    (("extern __DEVICE_FUNCTIONS_DECL__ __device_builtin__ [floatdube]* *[cosin]*pif*\\([doublefat]* x\\)" line)
                     (string-append line " noexcept(true)"))))))
            (delete 'configure)
            (delete 'check)
            (replace 'build
              (lambda* (#:key inputs #:allow-other-keys)
                (define libc
                  (assoc-ref inputs "libc"))
                (define gcc-lib
                  (assoc-ref inputs "gcc:lib"))
                (define ld.so
                  (search-input-file inputs #$(glibc-dynamic-linker)))
                (define rpath
                  (string-join (list "$ORIGIN"
                                     (string-append #$output "/lib")
                                     (string-append #$output "/nvvm/lib64")
                                     (string-append libc "/lib")
                                     (string-append gcc-lib "/lib"))
                               ":"))

                (define (patch-elf file)
                  (make-file-writable file)
                  (format #t "Setting RPATH on '~a'...~%" file)
                  ;; RPATH should be modified before the interpreter. If
                  ;; done the other way around, it nukes the resulting
                  ;; binary.
                  (invoke "patchelf" "--set-rpath" rpath
                          "--force-rpath" file)
                  (unless (string-contains file ".so")
                    (format #t "Setting interpreter on '~a'...~%" file)
                    (invoke "patchelf" "--set-interpreter" ld.so
                            file)))

                (for-each (lambda (file)
                            (when (elf-file? file)
                              (patch-elf file)))
                          (find-files "."
                                      (lambda (file stat)
                                        (eq? 'regular
                                             (stat:type stat)))))))
            (replace 'install
              (lambda _
                (define (copy-from-directory directory)
                  (for-each (lambda (entry)
                              (define sub-directory
                                (string-append directory "/" entry))

                              (define target
                                (string-append #$output "/" (basename entry)))

                              (when (file-exists? sub-directory)
                                (copy-recursively sub-directory target)))
                            '("bin" "targets/x86_64-linux/lib"
                              "targets/x86_64-linux/include"
                              "nvvm/bin" "nvvm/include"
                              "nvvm/lib64")))
                (setenv "COLUMNS" "200") ;wide backtraces!
                (with-directory-excursion "builds"
                  (for-each copy-from-directory
                            (scandir "." (match-lambda
                                           ((or "." "..") #f)
                                           (_ #t))))
                  ;; 'cicc' needs that directory.
                  (let ((libdevice (if #$cuda>=11?
                                       (if #$cuda>=13?
                                         "libnvvm/nvvm/libdevice"
                                         "cuda_nvcc/nvvm/libdevice")
                                       "cuda-toolkit/nvvm/libdevice/")))
                    (copy-recursively libdevice
                                      (string-append #$output "/nvvm/libdevice"))))

                ;; Install cputi (CUDA 10 specific).
                (unless #$cuda>=11?
                  (copy-recursively "cuda_cupti/extras/CUPTI" #$output))

                (with-directory-excursion #$output
                  (for-each (lambda (file)
                              (rename-file file
                                           (string-append #$output
                                                          "/lib/"
                                                          (basename file))))
                            (find-files "lib64"))
                  (rmdir "lib64"))
                ;; Many packages expect to find the stubs folder in
                ;; /lib64, as it seems it was the default in previous
                ;; CUDA versions. Some packages expect libraries to be
                ;; in lib64.
                (symlink (string-append #$output "/lib")
                         (string-append #$output "/lib64"))

                ;; Make sure the right version of GCC is used.
                (substitute* (string-append #$output
                                            "/bin/nvcc.profile")
                  (("^PATH\\s*\\+= " prefix)
                   (string-append prefix #$(this-package-input "gcc") "/bin:"))
                  (("^INCLUDES\\s*\\+= " prefix)
                   (string-append prefix
                                  "\"-I"
                                  #$(this-package-input "gcc")
                                  "/include\""
                                  (if #$linux-headers
                                      (string-append " \"-I"
                                                     #$(this-package-input "linux-headers")
                                                     "/include\"")
                                      ""))))

                ;; Fix CICC path for CUDA >= 12.6.
                (when #$cuda>=12.6?
                  (substitute* (string-append #$output "/bin/nvcc.profile")
                    (("nvvm/bin") "bin")))))
            (add-after 'install 'check
              ;; Attempt to build stuff from the CUDA samples
              ;; repository.
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (let* ((tmpdir (getenv "TMPDIR"))
                         (testdir (mkdtemp (string-append tmpdir
                                                          "/cuda-samples-XXXXXX")))
                         (samples (string-append #$(this-package-native-input "cuda-samples"))))
                    (copy-recursively samples
                                      testdir
                                      ;; Exclude specific tests.
                                      #:select? (lambda (file stat)
                                                  (let ((excluded (map (lambda (s)
                                                                         (string-append samples
                                                                                        "/Samples/"
                                                                                        s))
                                                                       '("conjugateGradientCudaGraphs"
                                                                         "cuSolverSp_LinearSolver"
                                                                         "cudaNvSci"
                                                                         "cudaTensorCoreGemm"
                                                                         "immaTensorCoreGemm"
                                                                         "matrixMulDrv"
                                                                         "memMapIPCDrv"
                                                                         "nvJPEG"
                                                                         "vectorAddMMAP"))))
                                                    (not
                                                     (find (lambda (f)
                                                             (string-prefix? f file))
                                                           excluded)))))

                    (setenv "CUDA_PATH" #$output)
                    ;; Restrict from Pascal to Turing architectures.
                    (setenv "SMS" "60 61 70 75")
                    (setenv "NVCC" (string-append #$output
                                                  "/bin/nvcc"))
                    ;; make all from trop directory is not used so
                    ;; subfolders can be selectively built.
                    (let* ((samples-directory (string-append
                                               testdir
                                               "/Samples"))
                           (failed
                            (filter-map
                             (lambda (directory)
                               (with-directory-excursion directory
                                 (guard (c ((invoke-error? c)
                                            (basename directory)))
                                   (display (string-append "Running make in "
                                                           (basename directory)
                                                           "\n"))
                                   ;; Force redefinition of NVCC
                                   ;; through the environment so the
                                   ;; host compiler is set using
                                   ;; nvcc.profile.
                                   (substitute* "Makefile"
                                     (("^NVCC * :=") "NVCC ?="))
                                   (invoke "make"
                                           "-j" (number->string (parallel-job-count)))
                                   #f)))
                             ;; Restrict to top level folders at
                             ;; SAMPLES-DIRECTORY that contain a
                             ;; Makefile.
                             (find-files samples-directory
                                         (lambda (name stat)
                                           (and (string=? samples-directory
                                                          (canonicalize-path
                                                           (dirname name)))
                                                (file-exists?
                                                 (string-append
                                                  name "/Makefile"))))
                                         #:directories? #t))))
                      (unless (null? failed)
                        (format #t "Failed samples:~%~a~%"
                                (string-join failed
                                             "\n"))
                        (exit #f))))))))))
      (native-inputs
       (list gnu-make
             (origin
               (method git-fetch)
               (uri (git-reference
                     (url "https://github.com/NVIDIA/cuda-samples")
                     ;; Oldest supported version.
                     (commit "v10.2")))
               (file-name "cuda-samples")
               (sha256
                (base32 "01p1innzgh9siacpld6nsqimj8jkg93rk4gj8q4crn62pa5vhd94")))
             patchelf
             python-wrapper))
      (inputs
       `(("gcc:lib" ,gcc "lib")
         ("gcc" ,gcc)
         ,@(if linux-headers
               `(("linux-headers" ,linux-headers))
               '())))
      (home-page "https://developer.nvidia.com/cuda-toolkit")
      (synopsis
       "Compiler for the CUDA language and associated run-time support")
      (description
       "This package provides the CUDA compiler and the CUDA run-time support
libraries for NVIDIA GPUs, all of which are proprietary.")
      (license (nonfree:nonfree "https://developer.nvidia.com/nvidia-cuda-license")))))

(define-syntax-rule (cuda-source url hash)
  ;; Visit
  ;; <https://developer.nvidia.com/cuda-10.2-download-archive?target_os=Linux&target_arch=x86_64&target_distro=Fedora&target_version=29&target_type=runfilelocal> or similar to get the actual URL.
  (origin
    (uri url)
    (sha256 (base32 hash))
    (method url-fetch/non-substitutable)))


(define-public cuda-13.1
  (make-cuda
    "13.1.1"
    (cuda-source
     "https://developer.download.nvidia.com/compute/cuda/13.1.1/local_installers/cuda_13.1.1_590.48.01_linux.run"
     "1r5qvyv0sb8rwb9rb040x46v8739iyj95cq4d11q29vj4cvk5zr4")
    #:gcc gcc-14))

(define-public cuda-13 cuda-13.1)
