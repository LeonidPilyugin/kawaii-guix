(define-module (kawaii packages)
  #:use-module (gnu packages)
  #:use-module (guix diagnostics)
  #:use-module (guix discovery)
  #:use-module (guix i18n)
  #:use-module (guix memoization)
  #:use-module (guix packages)
  #:use-module (guix ui)
  #:use-module (ice-9 match)
  #:export (%kawaii-package-module-path
            all-kawaii-packages))

(define %kawaii-root-directory
  ;; This is like %distro-root-directory from (gnu packages), with adjusted
  ;; paths.
  (letrec-syntax ((dirname* (syntax-rules ()
                              ((_ file)
                               (dirname file))
                              ((_ file head tail ...)
                               (dirname (dirname* file tail ...)))))
                  (try      (syntax-rules ()
                              ((_ (file things ...) rest ...)
                               (match (search-path %load-path file)
                                 (#f
                                  (try rest ...))
                                 (absolute
                                  (dirname* absolute things ...))))
                              ((_)
                               #f))))
    (try ("kawaii/packages/sing-box.scm" kawaii/ packages/))))

(define %kawaii-package-module-path
  `((,%kawaii-root-directory . "kawaii/packages")))

;; Adapted from (@ (gnu packages) all-packages).
(define all-kawaii-packages
  (mlambda ()
    "Return the list of all public packages, including replacements and hidden
packages, excluding superseded packages."
    ;; Note: 'fold-packages' never traverses the same package twice but
    ;; replacements break that (they may or may not be visible to
    ;; 'fold-packages'), hence this hash table to track visited packages.
    (define visited (make-hash-table))

    (fold-packages (lambda (package result)
                     (if (hashq-ref visited package)
                         result
                         (begin
                           (hashq-set! visited package #t)
                           (match (package-replacement package)
                             ((? package? replacement)
                              (hashq-set! visited replacement #t)
                              (cons* replacement package result))
                             (#f
                              (cons package result))))))
                   '()
                   (all-modules %kawaii-package-module-path #:warn warn-about-load-error)
                   ;; Dismiss deprecated packages but keep hidden packages.
                   #:select? (negate package-superseded))))
