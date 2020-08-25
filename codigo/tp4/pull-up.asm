;
; ejercicio 4
;
; Author : cristian Simonelli
;


.include "m328pdef.inc"

.def dummyreg = r21

.cseg 
.org 0x0000
            jmp		configuracion
.org INT0addr
            jmp     isr_int0

.org INT_VECTORS_SIZE
configuracion:
; Inicializacion stack pointer
                ldi     dummyreg,low(RAMEND)
                out     spl,dummyreg
                ldi     dummyreg,high(RAMEND)
                out     sph,dummyreg
                
                ldi     dummyreg,0xfb	; Port D 2
                out     DDRD,dummyreg
                ldi     dummyreg,0x04	; Pullups 2
                out     PORTD,dummyreg
                ldi     dummyreg,0xff	; Port b OUTPUT
                out     DDRB,dummyreg
                ldi     dummyreg,(1 << ISC01) ;0x02	; IE0 falling edge (ISC01=1;ISC00=0)
                sts     EICRA,dummyreg
                ldi     dummyreg,(1 << INT0) ;0x01	; turn IE0 on
                out     EIMSK,dummyreg


                cbi     PORTB, 1
                sbi     PORTB, 0
                
                sei

main:

                jmp main
                

isr_int0:
                push    r20
                cbi     PORTB, 0                    ; turn led 0 off
                ldi     r20,   10                   ; Load the counter
loop:           call    switch_led                  ; Switch led1 state
                call    delay                       ; delay half second aprox
                dec     r20                         ; dec counter
                brne    loop                        ; if is not 0 loop again 
                cbi     PORTB, 1                    ; Turn led 1 off, because if counter is set in a odd number
                                                    ;  led will remain on after the execution of this proc
                sbi     PORTB, 0                    ; turn led 0 off
                pop     r20                         ; restore r20
                reti



 ; turns on the led 1 if it is turned off and vice versa 
switch_led:
                push   r16                          ; Save the r16 value in the stack
                push   r17                          ; Save the r16 value in the stack
                in     r16, PORTB                   ; Read port b
                ldi    r17, 0x02                    ; load 0000 0010
                eor    r16, r17                     ; switch state of bit 2 in r16
                out    PORTB, r16                   ; load portb with the bit switched
                pop    r17                          ; restore r17
                pop    r16                          ; restore r16
                ret

; Delay function from tp1
delay:                                              ; Delay procedure
                push        r20                     ; Save the r20 value in the stack 
                push        r21                     ; Save the r21 value in the stack
                push        r22                     ; Save the r22 value in the stack
                ldi         r22, 40                 ; 
loop1:          ldi         r21, 255                ;
loop2:          ldi         r20, 255                ;
loop3:          dec         r20                     ; decrement r20 by 1
                brne        loop3                   ; If r20 had reached 0, z flag would have been seted
                                                    ; and we will jump to loop 3
                dec         r21                     ; The same as above
                brne        loop2
                dec         r22
                brne        loop1
                pop         r22                     ; Set r22, r21, r20 to the same value that
                pop         r21                     ; it had before entere this proc
                pop         r20
                ret                                 