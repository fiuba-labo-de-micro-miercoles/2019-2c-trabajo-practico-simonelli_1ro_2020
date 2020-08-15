;
; tp8.asm
;
; Created: 14/08/2020 20:13:45
; Author : cristian
;


.include "m328pdef.inc"

.def dummyreg = r21
.equ FOSC   = 16000000
.equ BAUD    = 9600
.equ UBRRVAL = FOSC/(BAUD*16)-1

.cseg 
.org 0x0000
            jmp		configuracion


.org INT_VECTORS_SIZE
configuracion:
; ram init
                ldi     dummyreg,low(RAMEND)
                out     spl,dummyreg
                ldi     dummyreg,high(RAMEND)
                out     sph,dummyreg
   
; port init                
                ldi     dummyreg,0xff	                                   ; Port D 2/3 as inputs
                out     DDRB,dummyreg                                      ;


; baudrate
				ldi     dummyreg, LOW(UBRRVAL)
				sts     UBRR0L, dummyreg
				ldi     dummyreg, HIGH(UBRRVAL)
				sts     UBRR0H, dummyreg

; Enable receiver and transmitter
				ldi     dummyreg, (1 << RXEN0 | 1 << TXEN0) 
				sts     UCSR0B,dummyreg

; Set frame format: 8data, 1stop bit 
				ldi     dummyreg, ( 1 << UCSZ01 | 1 << UCSZ00) 
				sts     UCSR0C,dummyreg
				

				
main:			
				call	delay
				call	delay
				call	delay
				ldi	ZH, high(2*greeting)
				ldi ZL, low(2*greeting)
				call print
receive:		ldi	ZH, high(2*ask)
				ldi ZL, low(2*ask)
				call print
				call USART_Receive
				mov r17, r16
				subi r17, '0'
				call switch_led ; en r17
				jmp receive

				
print:
         		lpm r16, Z+
				cpi r16, 0
				breq exit
				call USART_Transmit
				jmp print
exit:			ret


USART_Transmit:
				; Wait for empty transmit buffer
				lds  r17, UCSR0A
				andi r17, (1 << UDRE0)
				breq USART_Transmit
				; Put data (r16) into buffer, sends the data 
				sts UDR0,r16
				ret


USART_Receive:
				; Wait for data to be received
				lds r17, UCSR0A
				andi r17, (1 << RXC0)
				breq USART_Receive
				; Get and return received data from buffer
				lds r16, UDR0
				ret






delay:                                              ; Delay procedure
                push        r20                     ; Save the r20 value in the stack 
                push        r21                     ; Save the r21 value in the stack
                push        r22                     ; Save the r22 value in the stack
                ldi         r22, 82                 ; 82 * 255 * 255 aprox 8000000/3
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


 ; turns on the led 1 if it is turned off and vice versa 
switch_led:
                push   r16                          ; Save the r16 value in the stack
				push   r18
				ldi    r18, 1
shift:			cpi    r17, 1
				breq   write
                lsl    r18
				dec    r17
				jmp    shift
write:          in     r16, PORTB                   ; Read port b
                eor    r16, r18                     ; switch state of bit 2 in r16
                out    PORTB, r16                   ; load portb with the bit switched
				pop    r18
                pop    r16                          ; restore r16
                ret



greeting: .db	"*** Hola Labo de Micro ***", 13, 0
ask:      .db   "Escriba 1, 2, 3 o 4 para controlar los LEDs", 13, 0, 0