;
; ejercicio 6
;
; Author : cristian Simonelli
;


.include "m328pdef.inc"

.def dummyreg = r21
.def prescaler = r22
.def timer_on = r23

.cseg 
.org 0x0000
            jmp		configuracion
.org OVF1addr
			jmp     isr_timovf1

.org INT_VECTORS_SIZE
configuracion:
; Inicializacion stack pointer
                ldi     dummyreg,low(RAMEND)
                out     spl,dummyreg
                ldi     dummyreg,high(RAMEND)
                out     sph,dummyreg
                
                ldi     dummyreg,0xfc	; Port D 2/3
                out     DDRD,dummyreg
                ldi     dummyreg,0x03	; Pullups 2/3
                out     PORTD,dummyreg
                ldi     dummyreg,0xff	; Port b OUTPUT
                out     DDRB,dummyreg


				ldi     dummyreg, high(63974) ; esto no me suena
				sts     TCNT1H,  dummyreg     ; esta en overflow, para que comparo???
				ldi     dummyreg, low(63974)
				sts     TCNT1L,  dummyreg

				ldi     dummyreg, 0
				sts     tccr1a, dummyreg

                sei

main:
                in      dummyreg, PIND
				lsl     dummyreg
				lsl     dummyreg
				ldi     zl, low(i00)
				ldi     zh, high(i00)
				add     zl, dummyreg
				ldi     dummyreg, 0
				adc     zh, dummyreg
				icall
				sts     tccr1b, prescaler
				sts     TIMSK1 , timer_on               ; timer 1 overflow
				jmp     main





i00:			ldi     timer_on, 0                       ; time
				cbi     PORTB, 1
                ret
				nop
i01:			ldi     prescaler, ( 1<<CS10 | 1<<CS11 )  ; 64 prescaler 
				ldi     timer_on,  ( 1 << TOIE1 )         ; time
                ret
				nop
i10:			ldi     prescaler, ( 1<<CS12 )            ; 256 prescaler 
				ldi     timer_on,  ( 1 << TOIE1)          ; time
                ret
				nop
i11:			ldi     prescaler, ( 1<<CS10 | 1<<CS12 )  ; time
				ldi     timer_on,  ( 1 << TOIE1)          ; 1024 prescaler 
                ret
                



isr_timovf1:

                call    switch_led                  ; Switch led1 state
				ldi     r24, high(63974)
				sts     TCNT1H,  r24
				ldi     r24, low(63974)
				sts     TCNT1L,  r24
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

                     