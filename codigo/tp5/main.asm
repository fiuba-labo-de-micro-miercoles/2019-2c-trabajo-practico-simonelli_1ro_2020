.include "m328pdef.inc"                             ; Valid definitions to 238p

.equ init_mask = 0x40                               ; pin connected to the input switch 
.equ end_mask = 0x01                                ; pin connected to the input switch 

.org 0x000                                          ; The next instruction has to be written to add 0x0000

                rjmp        main                    ; Relative jump to main

.org INT_VECTORS_SIZE                               ; inter vector
                                                    
main:

                ldi         r20, HIGH(RAMEND)       ; Load r20 with the last ram address higher byte
                out         sph, r20                ; Load higher byte in sp with r20
                ldi         r20, LOW(RAMEND)        ; Load r20 with the last ram address lower byte
                out         spl, r20                ; Load lower byte in sp with r20

                ldi         r20, 0x3f               ; Set port d.0 d.1 d.2 d.3 d.4 d.5 as output 
                out         DDRD, r20               ; 
                
                ldi         r22, 0xfb               ; Port c.2 as input
                out         DDRC, r22               ;

                ldi         r22, (1 << ADLAR | 0 << MUX1)
                sts         ADMUX, r22

                ldi         r22, ( 1 << ADEN | 1 << ADSC)
                sts         ADCSRA, r22



                
loop:
                lds         r22, ADCSRA             ; Reads adcsra
                ori         r22, (1 << ADSC)        ; set adsc
                sts         ADCSRA, r22             ;
                lds         r16, ADCH               ; reads adc value
                out         PORTD, r16              ; write this value iun portb
                jmp         loop     


adc_isr:
                lds         r16, ADCH               ; reads adc value
                lsr         r16                     ; 63/255 aprox 4
                lsr         r16                     ; divide by 4
                andi        r16, 0x3f
                in          r17, PORTD
                andi        r17, 0xc0
                and         r16, r17
                out         PORTD, r16              ; write this value iun portb
                reti

