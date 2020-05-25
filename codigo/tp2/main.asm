; There is a switch conected between ground and pin PORTB pin 0
; When the switch is presed, the led is turned on, when the switch
; is released the led is turned off.
; Pull up version.
.include "m328pdef.inc"                             ; Valid definitions to 238p

.equ pin_led = 5                                    ; the built in led is the pin 13 (5th pin in B port)
.equ pin_button = 0x01                              ; pin conected to the input switch 
.equ portb_conf = 0x20

.org 0x000                                          ; The next instruction has to be written to add 0x0000

                rjmp        main                    ; Relative jump to main
.org INT_VECTORS_SIZE                               ; inter vector
                                                    
main:
                ldi         r20, HIGH(RAMEND)       ; Load r20 with the last ram address higher byte
                out         sph, r20                ; Load higher byte in sp with r20
                ldi         r20, LOW(RAMEND)        ; Load r20 with the last ram address lower byte
                out         spl, r20                ; Load lower byte in sp with r20

                ldi         r20, portb_conf         ; Set port b conf
                out         DDRB, r20               ; Set potb b conf
				ldi         r20, pin_button         ; Set pullup resistor for the input pin
				out         PORTB, r20              ; Set pullup resistor for the input pin

				ldi         r21, pin_button         ; Set r21 a mask in order to read only one bit
read:			in          r20, PINB               ; Read portb
				and         r20, r21                ; and with the mask
                breq        led_on                  ; if z flag is seted the port was low, so the switch is pushed
         		cbi         PORTB, pin_led          ; led off
				jmp         read                    ; goto red
led_on:         sbi         PORTB, pin_led          ; led on
                jmp         read                    ; goto red
