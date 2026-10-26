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
;; 002 - remake as type FF/2000          26 bytes
;; 003 - add HOME clear screen           29 bytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let's get going, shall we? ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.setcpu         "6502"          ;; enhanced not needed
.segment        "BSS"

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; doc buffer "buf" one ;;
;; usable byte  and one ;;
;; null                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

buf:    .res 2                 ;; reserve it first

;;;;;;;;;;;;;;;;;;
;; code section ;;
;;;;;;;;;;;;;;;;;;

.segment        "STARTUP"

Start:

.segment        "CODE"

AppStart:                       ;; entry point

;; prepare buf
lda     #0                      ;; load accum with NUL
sta     buf                     ;; store NUL in 1st byte (init)
sta     buf+1                   ;; store NUL in 2nd byte (init)
                                ;; - we don't really need this but
                                ;; - keeping it for safety

;; hard code A in 1st pos as test
;; store the letter A in buf pos 0
lda     #'A'
sta     buf

;; clear screen before showing doc
JSR     $FC58                   ;; same as HOME command

;; output buf to screen (to show the change)
lda     buf                     ;; load char at 1st pos
beq     done                    ;; if not NUL, go to next
ora     #$80                    ;; high bit 7 for text output
jsr     $FDED                   ;; screen output ROM routine
done:

;;;;;;;;;;;;;;;;;;;;;
;; end of AppStart ;;
;;;;;;;;;;;;;;;;;;;;;
halt:
        jmp     halt