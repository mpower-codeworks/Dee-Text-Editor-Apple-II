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
;; 002 - remake as type FF/2000		 26 bytes
;; 003 - add HOME clear screen		 29 bytes
;; 004 - replace halt w/ listen		 32 bytes
;; 005 - DELETE key erases buf pos 0	 47 bytes
;; 006 - working text editor		 75 bytes
;; 007 - caught ctrl-s for save		 98 bytes
;; 008 - added quit routine		114 bytes
;; 009 - added save file routine	181 bytes
;; 010 - start with a blank doc		176 bytes
;; 011 - added load file routine	247 bytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let's get going, shall we? ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.setcpu		"6502"		;; enhanced not needed
.segment	"BSS"

;;;;;;;;;;;;;;;;;;;;;;;;;
;; ProDOS needs a 1024 ;;
;; byte buffer for I/O ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

io_buffer:
.res    1024            	;; ProDOS I/O workspace

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; doc buffer "buf" one ;;
;; usable byte and one  ;;
;; CR                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

buf:    .res 2                  ;; reserve it first

;;;;;;;;;;;;;;;;;;
;; code section ;;
;;;;;;;;;;;;;;;;;;

.segment	"STARTUP"

Start:

.segment	"CODE"

AppStart:			;; entry point

;;;;;;;;;;;;;;;;;
;; prepare buf ;;
;;;;;;;;;;;;;;;;;

lda     #0              	;; load accum with NUL
sta     buf			;; store NUL in 1st byte (init)
				;; - this also means we are
				;; - starting the program
				;; - with a blank document

lda     #$0D            	;; load accum with CR line end
sta     buf+1			;; store CR in 2nd byte

;;;;;;;;;;;;;;;;;;;;;;;;;
;; cls before show doc ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

JSR	$FC58			;; same as HOME command

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output buf to screen ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

lda	buf			;; load char at 1st pos
beq     done			;; if NUL, go to next
ora     #$80			;; high bit 7 for text output
jsr     $FDED			;; screen output ROM routine
done:

;;;;;;;;;;;;;;;;;;;;
;; listening loop ;;
;;;;;;;;;;;;;;;;;;;;
;;  bne/jmp used  ;;
;; for long jumps ;;
;;  b/c range err ;;
;;;;;;;;;;;;;;;;;;;;

listen:

jsr 	$FD0C       		;; wait for key ROM routine

cmp    	#$93			;; CTRL-S (save) ?
beq	save			;; go to save file routine

cmp     #$8C			;; CTRL-L (load) ?
bne     check_quit		;; if not, check next key
jmp     load			;; go to load file routine

check_quit:

cmp     #$91			;; CTRL-Q (quit) ?
bne     check_delete		;; if not, check next key
jmp     quit			;; go to quit routine

check_delete:

cmp     #$FF        		;; DELETE key pressed ?
beq     delete			;; if so, branch to delete routine

and     #$7F			;; remove high bit
cmp     #$20			;; below printable ASCII range ?
bcc     listen 			;; if yes, ignore and loop

cmp     #$7F			;; ASCII DEL ($7F) or higher ?
bcs     listen			;; if yes, ignore and loop

tax				;; save printable key char in xreg
jmp 	write      		;; go to write routine

;;;;;;;;;;;;;;;;;;;;
;; delete routine ;;
;;;;;;;;;;;;;;;;;;;;

delete:

lda     #0			;; load NUL
sta     buf			;; clear buf pos1 with NUL 
jsr     $FC58			;; clear screen
				;; - buf now contains NUL,CR
jmp     listen			;; back to listening loop

;;;;;;;;;;;;;;;;;;;;;;;;
;; write char routine ;;
;;;;;;;;;;;;;;;;;;;;;;;;

write:

stx	buf			;; store xreg in buf pos 0
jsr     $FC58			;; clear screen
				;; buf now contains char,CR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this is the same code from  ;;
;; output buf to screen above  ;;
;; we'll make a reusable later ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lda     buf			;; retrieve character
ora     #$80			;; high bit 7 for text output
jsr     $FDED			;; screen output ROM routine

jmp     listen			;; back to listening loop

;;;;;;;;;;;;;;;;;;;;;;;
;; save file routine ;;
;;;;;;;;;;;;;;;;;;;;;;;
;; this took forever ;;
;;;;;;;;;;;;;;;;;;;;;;;

save:

jsr     $BF00			;; call ProDOS MLI
.byte   $C0             	;; CREATE command
.word   create_params   	;; parameter block address

bcc     create_ok        	;; check carry clear
cmp     #$47             	;; file already exists ?
beq     create_ok        	;; yes, acceptable
jmp     listen           	;; other error, silent abort

create_ok:
jsr     $BF00           	;; call ProDOS MLI
.byte   $C8             	;; OPEN command
.word   open_params     	;; parameter block address

bcc     open_ok         	;; OPEN succeeded ?
jmp     listen          	;; OPEN failed, abort

open_ok:
lda     open_params+5   	;; reference number returned
sta     close_params+1  	;; give ref num to CLOSE
sta     write_params+1   	;; give ref num to WRITE

jsr     $BF00           	;; call ProDOS MLI
.byte   $CB             	;; WRITE command
.word   write_params    	;; parameter block address


jsr     $BF00           	;; call ProDOS MLI
.byte   $CC             	;; CLOSE command
.word   close_params    	;; parameter block address

jmp     listen          	;; back to listening loop

create_params:
.byte   $07             	;; 7 params to follow
.word   filename       		;; filename address
.byte   $C3            		;; read/write access
.byte   $04             	;; TXT file type
.word   $0000           	;; auxiliary type 
.byte   $01             	;; standard file
.word   $0000           	;; creation date (not optional)
.word   $0000           	;; creation time (not optional)

filename:
.byte   1			;; one byte only!
.byte   "A"			;; file named "A" for the fonz

open_params:
.byte   $03             	;; 3 params to follow
.word   filename        	;; point to filename "A"     (2 bytes)
.word   io_buffer       	;; ProDOS requires 1024 byte (2 bytes)
				;; - I/O buffer address
.byte   $00             	;; ref num (returned)        (1 byte)

close_params:
.byte   $01             	;; 1 param to follow
.byte   $00             	;; ref num (placeholder)

write_params:
.byte   $04             	;; 4 params to follow
.byte   $00             	;; ref num (placeholder)
.word   buf             	;; point to doc
.word   $0002           	;; request 2 bytes
.word   $0000           	;; bytes actually transferred
				;; - ProDOS auto fills it in

;;;;;;;;;;;;;;;;;;;;;;;
;; load file routine ;;
;;;;;;;;;;;;;;;;;;;;;;;
;;  should probably  ;;
;;   add printable   ;;
;;    char checker   ;;
;;       later       ;;
;;        :=)        ;;
;;;;;;;;;;;;;;;;;;;;;;;

load:

jsr     $BF00			;; call ProDOS MLI
.byte   $C8             	;; OPEN command
.word   open_params     	;; parameter block address

bcc     load_open_ok         	;; OPEN succeeded ?
jmp     listen          	;; OPEN failed, abort

load_open_ok:
lda     open_params+5   	;; reference number returned
sta     close_params+1  	;; give ref num to CLOSE
sta     read_params+1		;; give ref num to READ

jsr     $BF00			;; call ProDOS MLI
.byte   $CA			;; READ command
.word	read_params		;; parameter block address

bcc     read_ok			;; check carry clear
jmp     load_display_done	;; READ failed, skip display

read_ok:

jsr     $FC58			;; HOME
lda	buf			;; load char at 1st pos
beq     load_display_done	;; if NUL, go to load_display_done
ora     #$80			;; high bit 7 for text output
jsr     $FDED			;; screen output ROM routine

load_display_done:

jsr     $BF00           	;; call ProDOS MLI
.byte   $CC             	;; CLOSE command
.word   close_params    	;; parameter block address

jmp     listen          	;; back to listening loop

read_params:
.byte   $04             	;; 4 params to follow
.byte   $00             	;; ref num (placeholder)
.word   buf             	;; store in buf
.word   $0002           	;; request 2 bytes
.word   $0000           	;; bytes actually transferred
				;; - ProDOS auto fills it in

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; quit routine returns to ProDOS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

quit:

jsr     $BF00			;; call ProDOS MLI
.byte   $65			;; QUIT command
.word   quit_params		;; parameter block address

quit_halt:
jmp     quit_halt		;; in case quit doesn't work

quit_params:
.byte   $04			;; 4 params to follow
.byte   $00			;; quit type: 0 = normal
.word   $0000			;; reserved (not optional)
.byte   $00			;; reserved (not optional)
.word   $0000			;; reserved (not optional)



; __...____________________          ,
;`(\ [ mpower-codeworks|__|) ___..--"_`--.._____
;  `"""""""""""""""""| |""` [_""_-___________"_/
;                    | |   /..../`'-._.-'`
;                ____| |__/::..'_
;               |\ ".`"` '_____//\
;               `"'-.   """""  \\/
;                    `""""""""""`