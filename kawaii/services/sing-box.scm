(define-module (kawaii services sing-box)
  #:use-module (guix deprecation)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (kawaii packages sing-box)
  #:export (sing-box-service-type
            sing-box-service))

(define sing-box-shepherd-service
  (lambda (config)
    (list (shepherd-service
           (documentation "sing-box daemon.")
           (provision '(sing-box))
           (requirement '(networking))
           (start #~(make-forkexec-constructor
             (list #$(file-append sing-box "/bin/sing-box")
               "-D"
               "/tmp"
               "-C"
               "/etc/sing-box"
               "run")))
           (stop #~(make-kill-destructor))))))

(define sing-box-service-type
  (service-type
    (name 'sing-box)
    (description "sing-box daemon.")
    (extensions
      (list
        (service-extension
          shepherd-root-service-type
          sing-box-shepherd-service)))
    (default-value '())))
