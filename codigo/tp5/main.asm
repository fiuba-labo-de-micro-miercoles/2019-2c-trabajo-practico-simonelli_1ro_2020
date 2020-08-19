.include "m328pdef.inc"                             ; Valid definitions to 238p

.org 0x000                                          ; The next instruction has to be written to add 0x0000

                rjmp       config                   ; Relative jump to main
.org 0x002A
			    rjmp       adc_isr

.org INT_VECTORS_SIZE                               ; inter vector
                                                    
config:
				 
                ldi         r20, HIGH(RAMEND)       ; Load r20 with the last ram address higher byte
                out         sph, r20                ; Load higher byte in sp with r20
                ldi         r20, LOW(RAMEND)        ; Load r20 with the last ram address lower byte
                out         spl, r20                ; Load lower byte in sp with r20

                ldi         r20, 0x3f
                out         PORTB, r20              ; Set the b port pin 
                out         DDRB, r20               ; Set the same port pin as output and input all others

                ldi         r22, 0xFE
                out         DDRC, r22
				
                ldi         r22, 0xaf
                sts         ADCSRA, r22             ; start conversion 
                ldi         r22, 0x60
                sts         ADMUX, r22

                sei
               
main:     		
                jmp         main     


adc_isr:
                lds         r16, ADCH
                out         PORTB, r16
                reti