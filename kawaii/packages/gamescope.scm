(define-module (kawaii packages gamescope)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system meson)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages stb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module ((guix licenses) #:prefix license:))

(define* (shika-override base
                             #:key
                             (name (package-name base))
                             (version (package-version base))
                             (commit (string-append "v" version))
                             (url (let ((uri (origin-uri (package-source base))))
                                    (if (git-reference? uri)
                                        (git-reference-url uri)
                                        uri)))
                             hash
                             (inputs (package-inputs base))
                             (native-inputs (package-native-inputs base))
                             (home-page (package-home-page base)))
  (package
    (inherit base)
    (version
     (if (string-prefix? "v" commit)
         version
         (git-version version "0" commit)))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (commit commit)
              (url url)))
       (file-name (git-file-name name version))
       (sha256
        (base32 hash))))
    (inputs inputs)
    (native-inputs native-inputs)
    (home-page home-page)))

(define-deprecated/alias shika-git-override shika-override)

(define-public reshade
  (package
    (name "reshade")
    (version "6.7.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/crosire/reshade")
              (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0d50jjz41zfrycwl2j0ywn9h031alzy1x1r5pw1pbybxm38l7acj"))))
    (build-system copy-build-system)
    (home-page "https://github.com/crosire/reshade")
    (synopsis
     "A generic post-processing injector for games and video software.")
    (description
     "This is a generic post-processing injector for games
and video software. It exposes an automated way to access
both frame color and depth information and a custom shader
language called ReShade FX to write effects like ambient
occlusion, depth of field, color correction and more which
work everywhere.")
    (license license:bsd-3)))

(define-public vkroots
  (let ((commit "5106d8a0df95de66cc58dc1ea37e69c99afc9540"))
    (package
      (name "vkroots")
      (version (git-version "0.0.0" "0" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
                (url "https://github.com/misyltoad/vkroots")
                (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0hrp0xqq93552ipw2bmryixgm1aywnz49xagsx5rwzg2d0hwa0aa"))))
      (build-system meson-build-system)
      (home-page "https://github.com/misyltoad/vkroots")
      (synopsis "A stupid simple method of making Vulkan layers, at home!")
      (description
       "Framework for writing Vulkan layers that takes all the
complexity/hastle away from you! It's so simple!")
      (license (list license:asl2.0 license:expat)))))

(define wlroots-for-gamescope
  (shika-override wlroots
                      #:version "0.18.0"
                      #:commit "54e844748029d4874e14d0c086d50092c04c8899"
                      #:url "https://github.com/misyltoad/wlroots"
                      #:hash
                      "0sxgs157nzm6bkfyzh4dnl9zajg2bq1m1kq09xpxi2lm8ran3g05"
                      #:home-page "https://github.com/misyltoad/wlroots"))

(define reshade-for-gamescope
  (shika-override reshade
                      #:version "6.1.1"
                      #:commit "696b14cd6006ae9ca174e6164450619ace043283"
                      #:url "https://github.com/misyltoad/reshade"
                      #:hash
                      "1zvhf3pgd8bhn8bynrsh725xn1dszsf05j8c9g6zabgv7vnz04a5"
                      #:home-page "https://github.com/misyltoad/reshade"))

(define spirv-headers-for-gamescope
  (shika-override spirv-headers
                      #:version "1.3.261"
                      #:commit "d790ced752b5bfc06b6988baadef6eb2d16bdf96"
                      #:hash
                      "1zzkqbqysiv52dk92i35gsyppnasln3d27b4rqv590zknk5g38is"))

(define openvr-for-gamescope
  (shika-override openvr
                      #:version "2.12.1"
                      #:commit "ff87f683f41fe26cc9353dd9d9d7028357fd8e1a"
                      #:hash
                      "0ds605hi4v5l7cly2dbydx20257dwjm216ig0vr6aswq37a8vl29"))

;; guix has 0.5.0 too but we will lock it
(define libliftoff-for-gamescope
  (shika-override libliftoff
                      #:version "0.5.0"
                      #:commit "8b08dc1c14fd019cc90ddabe34ad16596b0691f4"
                      #:hash
                      "163g8ndsbma7acy2k9mrnvlpb7yi4431hgkx1gygkafgwpq1ii1x"))

(define-public gamescope
  (package
    (name "gamescope")
    (version "3.16.22")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/ValveSoftware/gamescope")
              (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0yja2cgn2w0bmdp096523alz2ymp8jc1sfrgqnfkvjck8rnbr228"))))
    (build-system meson-build-system)
    (native-inputs (list bash-minimal pkg-config))
    (inputs (list eudev
                  glm
                  glslang
                  hwdata
                  libdecor
                  libdisplay-info
                  libx11
                  libxcomposite
                  libxcursor
                  libxdamage
                  libxext
                  libxkbcommon
                  libxmu
                  libxres
                  libxtst
                  libxxf86vm
                  luajit
                  pixman
                  sdl2
                  stb-image
                  stb-image-resize
                  stb-image-write
                  vkroots
                  vulkan-loader
                  wayland
                  wayland-protocols

                  openvr-for-gamescope
                  spirv-headers-for-gamescope
                  reshade-for-gamescope
                  libliftoff-for-gamescope
                  wlroots-for-gamescope))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'guix-fake-git
            (lambda _
              (let ((bin (string-append (getcwd) "/.fake-bin"))
                    (sh (string-append #$bash-minimal "/bin/sh")))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/git")
                  (lambda (p)
                    (format p "#!~a\nexec echo ~a\n" sh #$version)))
                (chmod (string-append bin "/git") #o755)
                (setenv "PATH"
                        (string-append bin ":" (getenv "PATH"))))))

          (add-after 'unpack 'inject-reshade
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((reshade (assoc-ref inputs "reshade"))
                    (spirv-headers (assoc-ref inputs "spirv-headers")))
                (copy-recursively reshade "src/reshade")
                (copy-recursively spirv-headers "thirdparty/SPIRV-Headers"))))

          (add-after 'inject-reshade 'use-guix-not-fallback
            (lambda* _
              (substitute* "meson.build"
                ;; we are pinning deps to same commits as upstream
                ;; so we don't have problem removing this note made for packagers
                (("'force_fallback_for=wlroots,libliftoff,vkroots',\n")
                 "")
                (("error\\('!!!\"force_fallback_for\".*\n")
                 ""))))

          (add-after 'use-guix-not-fallback 'use-guix-glm
            (lambda* _
              (substitute* "meson.build"
                (("glm_proj = subproject\\('glm'\\)\n")
                 "")

                (("glm_dep = glm_proj.get_variable\\('glm_dep'\\)\n")
                 "glm_dep = dependency('glm', required: true)\n"))))

          (add-after 'use-guix-glm 'use-guix-openvr
            (lambda* _
              (substitute* "meson.build"
                (("openvr_proj = cmake.subproject\\('openvr', options : openvr_var\\)\n")
                 "")

                (("openvr_dep = openvr_proj.dependency\\('openvr_api'\\)")
                 "openvr_dep = dependency('openvr', required:true)"))))

          (add-after 'use-guix-openvr 'use-guix-stb
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((stb-image (assoc-ref inputs "stb-image"))
                    (stb-image-resize (assoc-ref inputs "stb-image-resize"))
                    (stb-image-write (assoc-ref inputs "stb-image-write")))
                (substitute* "meson.build"
                  (("stb_proj = subproject\\('stb'\\)\n")
                   "")

                  (("stb_dep = stb_proj.get_variable\\('stb_dep'\\)\n")
                   (string-append
                    "stb_dep = declare_dependency(\n"
                    "  include_directories: [\n"
                    "    include_directories('" stb-image "/include'),\n"
                    "    include_directories('" stb-image-resize "/include'),\n"
                    "    include_directories('" stb-image-write "/include')\n"
                    "  ]\n"
                    ")\n")))))))))

    (home-page "https://github.com/ValveSoftware/gamescope")
    (synopsis "SteamOS session compositing window manager")
    (description
     "The micro-compositor formerly known as steamcompmgr")
    (license license:bsd-2)))
