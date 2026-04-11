(define-module (kawaii services autossh)
  #:use-module (guix gexp)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages admin)
  #:use-module (gnu services)
  #:use-module (gnu services web)
  #:use-module (gnu system pam)
  #:use-module (gnu system shadow)
  #:use-module (guix deprecation)
  #:use-module (guix records)
  #:use-module (guix modules)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 vlist)

  #:export (autossh-service-type
            autossh-configuration
            autossh-service))

(define (autossh-file-name config file)
  "Return a path in /var/run/autossh/ that is writable
   by @code{user} from @code{config}."
  (string-append "/var/run/autossh/"
                 (autossh-configuration-user config)
                 "/" file))

(define-record-type* <autossh-configuration>
  autossh-configuration make-autossh-configuration
  autossh-configuration?
  (user            autossh-configuration-user
                   (default "autossh"))
  (poll            autossh-configuration-poll
                   (default 600))
  (first-poll      autossh-configuration-first-poll
                   (default #f))
  (gate-time       autossh-configuration-gate-time
                   (default 30))
  (log-level       autossh-configuration-log-level
                   (default 1))
  (max-start       autossh-configuration-max-start
                   (default #f))
  (message         autossh-configuration-message
                   (default ""))
  (port            autossh-configuration-port
                   (default "0"))
  (ssh-options     autossh-configuration-ssh-options
                   (default '())))


(define (autossh-shepherd-service config)
  (shepherd-service
   (documentation "Automatically set up ssh connections (and keep them alive).")
   (provision '(autossh))
   (requirement '(networking NetworkManager))
   (start #~(make-forkexec-constructor
             (list #$(file-append autossh "/bin/autossh")
                   #$@(autossh-configuration-ssh-options config))
             #:user #$(autossh-configuration-user config)
             #:group (passwd:gid (getpw #$(autossh-configuration-user config)))
             #:pid-file #$(autossh-file-name config "pid")
             #:log-file #$(autossh-file-name config "log")
             #:environment-variables
             '(#$(string-append "AUTOSSH_PIDFILE="
                                (autossh-file-name config "pid"))
               #$(string-append "AUTOSSH_LOGFILE="
                                (autossh-file-name config "log"))
               #$(string-append "AUTOSSH_POLL="
                                (number->string
                                 (autossh-configuration-poll config)))
               #$(string-append "AUTOSSH_FIRST_POLL="
                                (number->string
                                 (or
                                  (autossh-configuration-first-poll config)
                                  (autossh-configuration-poll config))))
               #$(string-append "AUTOSSH_GATETIME="
                                (number->string
                                 (autossh-configuration-gate-time config)))
               #$(string-append "AUTOSSH_LOGLEVEL="
                                (number->string
                                 (autossh-configuration-log-level config)))
               #$(string-append "AUTOSSH_MAXSTART="
                                (number->string
                                 (or (autossh-configuration-max-start config)
                                     -1)))
               #$(string-append "AUTOSSH_MESSAGE="
                                (autossh-configuration-message config))
               #$(string-append "AUTOSSH_PORT="
                                (autossh-configuration-port config)))))
   (respawn? #t)
   (respawn-limit #f)
   (stop #~(make-kill-destructor))))

(define (autossh-service-activation config)
  (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils))
        (define %user
          (getpw #$(autossh-configuration-user config)))
        (let* ((directory #$(autossh-file-name config ""))
               (log (string-append directory "/log")))
          (mkdir-p directory)
          (chown directory (passwd:uid %user) (passwd:gid %user))
          (call-with-output-file log (const #t))
          (chown log (passwd:uid %user) (passwd:gid %user))))))


(define autossh-service-type
  (service-type
   (name 'autossh)
   (description "Automatically set up ssh connections (and keep them alive).")
   (extensions
    (list (service-extension shepherd-root-service-type
                             (compose list autossh-shepherd-service))
          (service-extension activation-service-type
                             autossh-service-activation)))
   (default-value (autossh-configuration))))

