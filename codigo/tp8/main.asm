;
; tp8.asm
;
; Created: 14/08/2020 20:13:45
; Author : cristian
;

.include "m328pdef.inc"

.def dummyreg = r21
.equ FOSC   = 16000000                                                     ; Clock prequency
.equ BAUD    = 9600                                                        ; Baud/s for usart
.equ UBRRVAL = FOSC/(BAUD*16)-1                                            ; Value in UBRR (datashit)
.equ LOWERINPUTVALUE = '1'
.equ BIGGESTINPUTVALUE = '4'

.cseg 
.org 0x0000
                jmp		configuracion


.org INT_VECTORS_SIZE
configuracion:
; ram init
                ldi     dummyreg,low(RAMEND)                               ; inits stack pointer
                out     spl,dummyreg                                       ;
                ldi     dummyreg,high(RAMEND)                              ;
                out     sph,dummyreg                                       ;
   
; port init                
                ldi     dummyreg,0xff	                                   ; Port b as output
                out     DDRB,dummyreg                                      ;

; baudrate
                ldi     dummyreg, LOW(UBRRVAL)                             ; as it was calculated in the 
                sts     UBRR0L, dummyreg                                   ;  formula that is in the datasheet
                ldi     dummyreg, HIGH(UBRRVAL)                            ;
                sts     UBRR0H, dummyreg                                   ;

; Enable receiver and transmitter
                ldi     dummyreg, (1 << RXEN0 | 1 << TXEN0)                ; Enable transmission / reception
                sts     UCSR0B,dummyreg                                    ;

; Set frame format: 8data, 1stop bit 
                ldi     dummyreg, ( 1 << UCSZ01 | 1 << UCSZ00)             ; 8N1
                sts     UCSR0C,dummyreg                                    ;
				

				
main:			
                call    delay                                              ; Waiting time to connect to a program 
                call    delay                                              ;  that establishes a connection with 
                call    delay                                              ;  the micro controller
                call    print_greeting_msg                                 ; Pints a gretting
receive:        call    ask_for_input                                      ; Asks for input
                call    USART_Receive                                      ; Reads input, lets in r16
                call    trate_input                                        ; Transforms ascci input in a number, lets that in r17
                brts    error                                              ; input error
                call    toggle_led                                         ; Togle the led, reads the number from r17
                jmp     receive                                            ; asks for another input
error:          call    print_error_input_msg                              ; Shows error message
                jmp     receive                                            ; Asks for another input


; Prints the value pointed by z until 0 is reached
print:                  

                lpm     r16, Z+                                            ; Sets the value pointed to z to r16, and increments z
                cpi     r16, 0                                             ; Is the String end reached?
                breq    exit                                               ; Exits
                call    USART_Transmit                                     ; Sends the value stored in r16
                jmp     print                                              ; loops for the next character in the string
exit:           ret

; Checks that this is a validate input, and transform ascii to number
; if this fails sets the T flag in status reg, if not, clear T flag in status reg
trate_input:
                cpi     r16, LOWERINPUTVALUE                               ; Verifies that the input number is bigger than 
                brlt    input_error                                        ;   the lowest accepted 
                cpi     r16, BIGGESTINPUTVALUE + 1                         ; Verifies that the input number is lower than 
                brsh    input_error                                        ;   the bigger accepted
                mov     r17, r16                                           ; copyes r16 inbto r17
                subi    r17, '0'                                           ; Transfors an ascii into a number
                clt                                                        ; Clears t flag, the input was valid, and could be transfomed
                ret 
input_error:    set                                                        ; Sets t flag, the input was invalid
                ret

; prints greeting message
print_greeting_msg:
                ldi     ZH, high(2*greeting_msg)                           ; points greeting message
                ldi     ZL, low(2*greeting_msg)                            ;
                call    print                                              ; Prints
                ret

; Asks for a number
ask_for_input:
                ldi     ZH, high(2*ask_msg)                                ; points asking message
                ldi     ZL, low(2*ask_msg)                                 ; 
                call    print                                              ; Prints
                ret

; Prints an error 
print_error_input_msg:
                ldi     ZH, high(2*error_msg)                              ; Points err message
                ldi     ZL, low(2*error_msg)                               ;
                call    print                                              ; Prints
                ret

; Transmit the data stored in r16 using USART  (this example is taken from the datasheet)
USART_Transmit:
                ; Wait for empty transmit buffer
                lds      r17, UCSR0A
                andi     r17, (1 << UDRE0)
                breq     USART_Transmit
                ; Put data (r16) into buffer, sends the data 
                sts      UDR0,r16
                ret

; Receibe a byte and stores it in r16   (this example is taken from the datasheet)
USART_Receive:
                ; Wait for data to be received
                lds     r17, UCSR0A
                andi    r17, (1 << RXC0)
                breq    USART_Receive
                ; Get and return received data from buffer
                lds     r16, UDR0
                ret


 ; turns on the led 1 if it is turned off and vice versa 
toggle_led:
                push    r16                                                 ; Saves r16
                push    r18                                                 ; saves r18 
                ldi     r18, 1                                              ; Sets 1 into r18
shift:          cpi     r17, 1                                              ; if r17 has 1 stop shifting
                breq    write                                               ; Jmps to write into port b
                lsl     r18                                                 ; left shift
                dec     r17                                                 ; decrements r17 counter
                jmp     shift                                               ; shifts again
write:          in      r16, PORTB                                          ; Reads port b
                eor     r16, r18                                            ; switchs state on r16
                out     PORTB, r16                                          ; loads portb with the bit switched
                pop     r18                                                 ; restore r18
                pop     r16                                                 ; restore r16
                ret


; Delay function from tp1
delay:                                                                      ; Delay procedure
                push    r20                                                 ; Save the r20 value in the stack 
                push    r21                                                 ; Save the r21 value in the stack
                push    r22                                                 ; Save the r22 value in the stack
                ldi     r22, 82                                             ; 82 * 255 * 255 aprox 8000000/3
loop1:          ldi     r21, 255                                            ;
loop2:          ldi     r20, 255                                            ;
loop3:          dec     r20                                                 ; decrement r20 by 1
                brne    loop3                                               ; If r20 had reached 0, z flag would have been seted
                                                                            ;   and we will jump to loop 3
                dec     r21                                                 ; The same as above

                brne    loop2     
                dec     r22     
                brne    loop1     
                pop     r22                                                 ; Set r22, r21, r20 to the same value that
                pop     r21                                                 ; it had before entere this proc
                pop     r20     
                ret                                                         ; go back to main

greeting_msg: .db	"*** Hola Labo de Micro ***", 10, 13, 0, 0
ask_msg:      .db   "Escriba 1, 2, 3 o 4 para controlar los LEDs", 10, 13, 0
error_msg:    .db   "Error en la entrada", 10, 13, 0