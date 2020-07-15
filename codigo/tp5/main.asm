; knight rider lights
.include "m328pdef.inc"                             ; Valid definitions to 238p

.equ init_mask = 0x40                               ; pin connected to the input switch 
.equ end_mask = 0x01                                ; pin connected to the input switch 

.org 0x000                                          ; The next instruction has to be written to add 0x0000

                rjmp        main                    ; Relative jump to main
.org 0x002A
			    rjmp       adc_isr

.org INT_VECTORS_SIZE                               ; inter vector
                                                    
main:
				 
                ldi         r20, HIGH(RAMEND)       ; Load r20 with the last ram address higher byte
                out         sph, r20                ; Load higher byte in sp with r20
                ldi         r20, LOW(RAMEND)        ; Load r20 with the last ram address lower byte
                out         spl, r20                ; Load lower byte in sp with r20

			    ldi         r22, 0xFE
				out         DDRC, r22
				
				ldi         r22, 0xaf
				sts         ADCSRA, r22             ; start conversion 
				ldi         r22, 0x60
				sts         ADMUX, r22

				sei

				lds         r22, ADCSRA
				ori         r22, 0x40
				sts         ADCSRA, r22             ; start conversion 
                ldi         r20, init_mask          ; Set b port with the bound value
right:          lsr         r20                     ; right shift ... 010000 -> 001000
                out         PORTB, r20              ; Set the b port pin 
                out         DDRB, r20               ; Set the same port pin as output and input all others 
                cpi         r20, end_mask           ; Compare with the bound value
                breq        left                    ; If bound value has been reached start to shift to the other side
                call        delay                   ; Delay
                jmp         right                   ; Go to right
left:			lsl         r20                     ; left shift... 000001 -> 000010
                cpi         r20, init_mask          ; Compare to the left bound value
                breq        right                   ; If bound value has been reached start to shift to the other side
                call        delay                   ; Delay
                out         PORTB, r20              ; Set the b port pin 
                out         DDRB, r20               ; Set the same port pin as output and input all others 
                jmp         left                    ; Goto left


adc_isr:
				lds         r16, ADCH
				reti

delay:                                              ; Delay procedure
                push        r20                     ; Save the r20 value in the stack 
                push        r21                     ; Save the r21 value in the stack
                push        r22                     ; Save the r22 value in the stack
				mov         r22, r16                 ;
loop1:          ldi         r21, 50                 ;
loop2:          ldi         r20, 100                ;
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
                ret                                 ; go back to main
