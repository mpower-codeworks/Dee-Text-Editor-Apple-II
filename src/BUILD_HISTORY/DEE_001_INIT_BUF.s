;;;;;;;;;;;;;;;;;;;;
;;       dee      ;;
;; a really small ;;
;;   text editor  ;;
;;;;;;;;;;;;;;;;;;;;

;; use build.bat
;; and dee.cfg

;; build history
;; -------------
;; 001 - first build, w/buf init        472 bytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let's get going, shall we? ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.setcpu      "6502"             ;; enhanced not needed
.forceimport __STARTUP__        ;; linker needs startup code
.export      _main              ;; standard apple2 entry

.segment "BSS"

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; doc buffer "buf" one ;;
;; usable byte  and one ;;
;; null                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

buf:    .res 2                  ;; reserve it first

;;;;;;;;;;;;;;;;;;
;; code section ;;
;;;;;;;;;;;;;;;;;;

.segment "CODE"

_main:                          ;; entry point

;; prepare buf
lda     #0                      ;; load accum with NUL
sta     buf                     ;; store NUL in 1st byte (init)
sta     buf+1                   ;; store NUL in 2nd byte (init)

tax                             ;; return 0 (was already in accum)
rts                             ;; return from _main