;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (kawaii licenses)
  #:export (nonfree artistic-1.0 cc-by-nd4.0))

;; Guix does not export the license record constructor.
(define license (@@ (guix licenses) license))

(define* (nonfree uri #:optional (comment ""))
  "Return a nonfree license, whose full text can be found
at URI, which may be a file:// URI pointing the package's tree."
  (license "Nonfree"
           uri
           (string-append
            "This a nonfree license.  Check the URI for details.  "
            comment)))

(define artistic-1.0
  (license "Artistic 1.0"
           "https://opensource.org/license/artistic-1-0/"
           "Artistic License 1.0"))

(define cc-by-nd4.0
  (license "CC-BY-ND 4.0"
           "http://creativecommons.org/licenses/by-nd/4.0/"
           "Creative Commons Attribution-NoDerivatives 4.0 International"))


