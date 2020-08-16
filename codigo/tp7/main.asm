;
; ejercicio 7
;
; Author : cristian Simonelli
;


.include "m328pdef.inc"

.def dummyreg = r21

.cseg 
.org 0x0000
            jmp		configuracion
.org OVF1addr
            jmp     isr_timovf1

.org INT_VECTORS_SIZE
configuracion:
; ram init
                ldi     dummyreg,low(RAMEND)
                out     spl,dummyreg
                ldi     dummyreg,high(RAMEND)
                out     sph,dummyreg
   
; port init                
                ldi     dummyreg,0xf3	                                   ; Port D 2/3 as inputs
                out     DDRD,dummyreg                                      ;
                ldi     dummyreg,0x0c	                                   ; Pullups 2/3
                out     PORTD,dummyreg                                     ;

; timer init
                ldi     dummyreg,  (1 << TOIE1)                            ; set overflow interruption
                sts     TIMSK1 , dummyreg                                  ;
                ldi     dummyreg, (1 << CS10 | 1 << CS11 )                              ; set prescaler 
                sts     TCCR1B,  dummyreg                                  ;

; pwm init
                ldi     dummyreg, ( 1 << COM0B1 | 1 << WGM01 | 1 << WGM00) ; fast pwm non inverted mode
                out     TCCR0A, dummyreg                                   ;
                ldi     dummyreg, (1 << CS00)                              ; Timer 0 on, no prescaler
                out     TCCR0B, dummyreg                                   ;
                ldi     dummyreg, 0x01                                     ; compare TCNT0 matchs to 1
                out     OCR0B, dummyreg                                    ;
                
                sei                                                        ; turn interruptions on

main:
                jmp main



; Polling every that timer1 overflows to prevent switch bounces
isr_timovf1:
                in      r25, PIND                                          ; get PIND                         
                mov     r26, r25                                           ; preserv PIND value
                andi    r26, 0x04                                          ; is portd.2 presed ?
                breq    led_up                                             ;    is so, encrease led's brigh  
                mov     r26, r25                                           ; portd.2 was no presed
                andi    r26, 0x08                                          ; is portd.3 presed ?
                breq    led_down                                           ;    is so, decrease led's brigh  
exit_isr:       reti

; The idea behind this is to change the value that tcntc in compared with				
led_up:
                in      r24, OCR0B                                         ; get OCR0B original value    
                lsl     r24                                                ; multiply this by 2
                brcs    exit_isr                                           ; is carry seted? if this is the case, dont update the value
                out     OCR0B, r24                                         ; if not, set the new OCR0B value
                reti                                                       ;

led_down:
                in      r24, OCR0B                                         ; get OCR0B original value  
                lsr     r24                                                ; divided this by 2
                breq    exit_isr                                           ; if this is 0 dont update the value
                out     OCR0B, r24                                         ; update the value
                reti
