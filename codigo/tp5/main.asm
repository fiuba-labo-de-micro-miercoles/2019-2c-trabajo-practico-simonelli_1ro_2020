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
                
                ldi         r20, 0xfb               ; Port c.2 as input
                out         DDRC, r20               ;

                                                    ; Set channel 2, ADLAR (data in adch), Vcc as reference
                ldi         r20, (1 << ADLAR | 1 << MUX1  | 1 << REFS0)
                sts         ADMUX, r20
                                                    ; ADEN adc enable
                                                    ; ADCS start convertion
                                                    ; adpsx = 111 division factor in 128
                ldi         r20, ( 1 << ADEN | 1 << ADSC | 1 << ADPS2 | 1 << ADPS2 | 1 << ADPS2)
                sts         ADCSRA, r20
              
loop:
                call        convertion_start        ; Starts convertion
                call        convertion_wait         ; Waits the convertion to complete
                call        adc_read                ; let value in r16
                out         PORTD, r16              ; writes this value in portd
                
                jmp loop


convertion_wait:
                lds         r16, ADCSRA             ; polls ADIE until convertion is complete
                sbrs        r16, 4                  ; 
                jmp         convertion_wait         ; 
                ret

convertion_start:
                ldi         r16, (1 << ADSC)        ; Trigger convertion
                lds         r17, ADCSRA             ;
                or          r17, r16                ;
                sts         ADCSRA, r17             ;
                ret

adc_read:
                lds         r16, ADCH               ; reads adc value
                lsr         r16                     ; 63/255 aprox 4
                lsr         r16                     ; divide by 4
                ret

