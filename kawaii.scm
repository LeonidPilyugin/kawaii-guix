(define-module (kawaii))

;; Re-export commonly-used modules for system setup.

(eval-when (eval load compile)
  (begin
    (define %public-modules '((kawaii packages sing-box))

    (for-each (let ((i (module-public-interface (current-module))))
                (lambda (m)
                  ;; Ignore non-existent modules, so that we can split the
                  ;; channel without breaking this module in the future.
                  (and=> (false-if-exception (resolve-interface m))
                         (cut module-use! i <>))))
              %public-modules)))

