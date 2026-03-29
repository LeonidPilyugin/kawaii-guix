;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (kawaii packages cuda)
  #:use-module (guix-science-nonfree packages cuda)
  #:use-module (gnu packages gcc)
  #:export (cuda-13))

(define-public cuda-13.1
  (make-cuda
    "13.1.1"
    (cuda-source
     ""https://developer.download.nvidia.com/compute/cuda/13.1.1/local_installers/cuda_13.1.1_590.48.01_linux.run""
     "1r5qvyv0sb8rwb9rb040x46v8739iyj95cq4d11q29vj4cvk5zr4")
    #:gcc gcc-15))

(define-public cuda-13 cuda-13.1)
