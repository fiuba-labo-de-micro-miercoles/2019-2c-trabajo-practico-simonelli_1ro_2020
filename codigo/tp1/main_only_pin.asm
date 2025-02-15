.include "m328pdef.inc"                             ; Valid definitions to 238p

.equ pin_lead = 5                                   ; the built in led is the pin 13 (5th pin in B port)

.org 0x000                                          ; The next instruction has to be written to add 0x0000

                rjmp        main                    ; Relative jump to main
.org INT_VECTORS_SIZE                               ; inter vector
                                                    
main:
                ldi         r20, HIGH(RAMEND)       ; Load r20 with the last ram address higher byte
                out         sph, r20                ; Load higher byte in sp with r20
                ldi         r20, LOW(RAMEND)        ; Load r20 with the last ram address lower byte
                out         spl, r20                ; Load lower byte in sp with r20

                ldi         r20, 0x20               ; B pin 5 (00100000) as output
                out         DDRB, r20               ; B pin 5 (00100000) as output

led:            cbi         PORTB, pin_lead         ; Led loop turn off led
                call        delay                   ; Delay
                sbi         PORTB, pin_lead         ; Turn on led
                call        delay                   ; Delay
                jmp         led                     ; Loop 4 ever


delay:                                              ; Delay procedure
                push        r20                     ; Save the r20 value in the stack 
                push        r21                     ; Save the r21 value in the stack
                push        r22                     ; Save the r22 value in the stack
                ldi         r22, 82                 ; 82 * 255 * 255 aprox 16000000/3
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
                ret                                 ; go back to main

