;;;;;;;;;;;;;;;;;;;;
;;       dee      ;;
;; a really small ;;
;;   text editor  ;;
;;;;;;;;;;;;;;;;;;;;

;; use build.bat
;; and fonz.cfg

;; build history
;; -------------
;; 001 - first build, w/buf init        472 bytes
;; 002 - remake as type FF/2000          26 bytes
;; 003 - add HOME clear screen           29 bytes
;; 004 - replace halt w/ listen          32 bytes
;; 005 - DELETE key erases buf pos1      47 bytes
;; 006 - working text editor             75 bytes
;; 007 - caught ctrl-s for save          98 bytes
;; 008 - added quit routine             114 bytes

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

buf:    .res 2                  ;; reserve it first

;;;;;;;;;;;;;;;;;;
;; code section ;;
;;;;;;;;;;;;;;;;;;

.segment        "STARTUP"

Start:

.segment        "CODE"

AppStart:                       ;; entry point

;;;;;;;;;;;;;;;;;
;; prepare buf ;;
;;;;;;;;;;;;;;;;;
lda     #0                      ;; load accum with NUL
sta     buf                     ;; store NUL in 1st byte (init)
sta     buf+1                   ;; store NUL in 2nd byte (init)
                                ;; - we don't really need this but
                                ;; - keeping it for safety

;; store the letter A in buf pos 0
;; verified that program correctly
;; displays nothing if this is
;; disabled
lda     #'A'
sta     buf

;; clear screen before showing doc
JSR     $FC58                   ;; same as HOME command

;; output buf to screen
lda     buf                     ;; load char at 1st pos
beq     done                    ;; if not NUL, go to next
ora     #$80                    ;; high bit 7 for text output
jsr     $FDED                   ;; screen output ROM routine
done:

;;;;;;;;;;;;;;;;;;;;
;; listening loop ;;
;;;;;;;;;;;;;;;;;;;;
listen:

jsr     $FD0C                   ;; wait for key ROM routine

;cmp    #$93                    ;; CTRL-S (save) ?
;cmp    #$8C                    ;; CTRL-L (load) ?
cmp     #$91                    ;; CTRL-Q (quit) ?
beq     quit                    ;; go to quit routine

cmp     #$FF                    ;; DELETE key pressed ?
beq     delete                  ;; if so, branch to delete routine

and     #$7F                    ;; remove high bit
cmp     #$20                    ;; below ASCII space ?
bcc     listen                  ;; if yes, ignore and loop

cmp     #$7F                    ;; ASCII DELETE or higher ?
bcs     listen                  ;; if yes, ignore and loop

tax                             ;; save printable key char in xreg
jmp     write                   ;; go to write routine

;;;;;;;;;;;;;;;;;;;;
;; delete routine ;;
;;;;;;;;;;;;;;;;;;;;
delete:

lda     #0                      ;; load NUL
sta     buf                     ;; clear buf pos1 with NUL
jsr     $FC58                   ;; clear screen
                                ;; - buf now contains NUL,NUL
jmp     listen                  ;; back to listening loop

;;;;;;;;;;;;;;;;;;;;;;;;
;; write char routine ;;
;;;;;;;;;;;;;;;;;;;;;;;;
write:

stx     buf                     ;; store xreg in buf pos1
jsr     $FC58                   ;; clear screen
                                ;; buf now contains char,NUL

;; this is the same code from
;; output buf to screen above
;; we'll make a reusable later
lda     buf                     ;; retrieve character
ora     #$80                    ;; high bit 7 for text output
jsr     $FDED                   ;; screen output ROM routine

jmp     listen                  ;; back to listening loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; save routine - testing first ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; if this works then we know   ;;
;; that the control-s works     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
save:

lda     #'@'                    ;; @ is our save-test char
sta     buf                     ;; store @ in buf pos1
jsr     $FC58                   ;; clear screen
lda     buf                     ;; reload @ - it's in buf
ora     #$80                    ;; high bit 7 for text output
jsr     $FDED                   ;; screen output ROM routine
jmp     listen                  ;; back to listening loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; quit routine returns to ProDOS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
quit:
    jsr     $BF00               ;; call ProDOS MLI
    .byte   $65                 ;; QUIT command
    .word   quit_params         ;; parameter block address

quit_halt:
    jmp     quit_halt           ;; in case quit doesn't work

quit_params:
    .byte   $04                 ;; 4 params to follow
    .byte   $00                 ;; quit type: 0 = normal
    .word   $0000               ;; reserved (not optional)
    .byte   $00                 ;; reserved (not optional)
    .word   $0000               ;; reserved (not optional)