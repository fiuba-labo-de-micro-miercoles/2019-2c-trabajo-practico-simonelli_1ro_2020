;
; ejercicio 6
;
; Author : cristian Simonelli
;


.include "m328pdef.inc"

.def dummyreg = r21
.def prescaler = r22
.def timer_on = r23
.def post_value = r19
.def input = r18

.equ TIMER_COUNT = 0xf9e6                                  ; 1 second aprox

.cseg 
.org 0x0000
            jmp     configuracion
.org OVF1addr
            jmp     isr_timovf1

.org INT_VECTORS_SIZE
configuracion:
; Inicializacion stack pointer
                ldi     dummyreg,low(RAMEND)
                out     spl,dummyreg
                ldi     dummyreg,high(RAMEND)
                out     sph,dummyreg
; port config                
                ldi     dummyreg,0xf3	                  ; Port D 2/3 as input
                out     DDRD,dummyreg                     ;
                ldi     dummyreg,0xff	                  ; Port b as output
                out     DDRB,dummyreg                     ;

; timer 1 config
                ldi     dummyreg, high(63974)
                sts     TCNT1H,  dummyreg
                ldi     dummyreg, low(63974)
                sts     TCNT1L,  dummyreg

                ldi     dummyreg, 0
                sts     tccr1a, dummyreg

                sei

main:
                ldi     zl, low(i00)                      ; Loads Z with the first position of the table
                ldi     zh, high(i00)                     ; Multiply by 2 is not necessary in this case
                                                          ;   icall is world addressed
                call    read_input                        ; reads input, treates bounce, stores data in input var
                add     zl, input                         ; Ads tableposition + (input selection)
                ldi     dummyreg, 0                       ;   ( see table definition )
                adc     zh, dummyreg                      ;
                icall                                     ; calls whatever z is pointing to
                sts     tccr1b, prescaler                 ; Sets new prescaler info
                sts     TIMSK1 , timer_on                 ; Sets new timer status (on or off)
                jmp     main                              ; loop

; Each entry in this table weights 8 bytes (4 worlds) and represents an user selection
; After execute any of this entries both prescaler and time_on will be loaded
i00:            ldi     timer_on, 0                       ; time
                cbi     PORTB, 1
                ret
                nop
i01:            ldi     prescaler, ( 1<<CS10 | 1<<CS11 )  ; 64 prescaler 
                ldi     timer_on,  ( 1 << TOIE1 )         ; time
                ret
                nop
i10:            ldi     prescaler, ( 1<<CS12 )            ; 256 prescaler 
                ldi     timer_on,  ( 1 << TOIE1)          ; time
                ret
                nop
i11:            ldi     prescaler, ( 1<<CS10 | 1<<CS12 )  ; time
                ldi     timer_on,  ( 1 << TOIE1)          ; 1024 prescaler 
                ret

; timer 1 overflow isr
isr_timovf1:

                call    toggle_led                        ; Switch led1 state
                ldi     r24, high(TIMER_COUNT)            ; Sets value into tcnt1 that makes 
                sts     TCNT1H,  r24                      ; timer 1 overflows every 1 second aprox
                ldi     r24, low(TIMER_COUNT)             ;
                sts     TCNT1L,  r24                      ;
                reti

; turns on the led 1 if it is turned off and vice versa 
toggle_led:
                push    r16                               ; Save the r16 value in the stack
                push    r17                               ; Save the r16 value in the stack
                in      r16, PORTB                        ; Read port b
                ldi     r17, 0x02                         ; load 0000 0010
                eor     r16, r17                          ; switch state of bit 2 in r16
                out     PORTB, r16                        ; load portb with the bit switched
                pop     r17                               ; restore r17
                pop     r16                               ; restore r16
                ret

read_input:
                in      input, PIND                    ; Read port D
                call    delay                          ; Delay waiting for portd to change (debounce)
                in      post_value, PIND               ; Read port D
                cp      input, post_value              ; If this values are differente, 
                brne    read_input                     ;    could indicate that this is bouncing
                andi    input, 0x0c                    ; this is actually unnecessary, but clear info
                ret


; Delay function from tp1 (ligth version)
delay:                                                 ; Delay procedure
                push    r20                            ; Save the r20 value in the stack 
                push    r22                            ; Save the r22 value in the stack
                ldi     r22, 40                        ; 
loop1:          ldi     r20, 40                        ;
loop2:          dec     r20                            ; decrement r20 by 1
                brne    loop2                          ; If r20 had reached 0, z flag would have been seted
                                                       ;   and we will jump to loop 2
                dec     r22                            ; The same as above
                brne    loop1     
                pop     r22                            ; it had before entere this proc
                pop     r20     
                ret                                    ; go back to main
