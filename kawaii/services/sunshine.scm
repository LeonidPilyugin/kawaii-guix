(define-module (kawaii services sunshine)
  #:use-module (srfi srfi-26)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu services)
  #:use-module (gnu services configuration)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services base)
  #:use-module (gnu system privilege)
  #:use-module (kawaii packages streaming)
  #:use-module (ice-9 match)
  #:export (sunshine-service-type
            sunshine-configuration))

(define-record-type* <sunshine-configuration>
  sunshine-configuration
  make-sunshine-configuration
  sunshine-configuration?
  (package sunshine-package
            (default sunshine)))


(define sunshine-privileged-programs
  (match-lambda
    (($ <sunshine-configuration> package)
     (list (privileged-program
                     (program (file-append package "/bin/sunshine"))
                     (capabilities "cap_sys_admin+p"))))))

(define sunshine-service-type
  (service-type
   (name 'sunshine)
   (default-value (sunshine-configuration))
   (extensions
    (list
          (service-extension profile-service-type
                             (compose list sunshine-package))
          (service-extension udev-service-type
                             (compose list sunshine-package))
          (service-extension privileged-program-service-type
                             sunshine-privileged-programs)))
   (description "Service type for sunshine streaming server. Requires privileged access.
     Add sunshine package to profile, udev rules and set privileged capabilities.")))
