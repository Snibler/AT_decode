;------------ASM ��������� ������������� ���� ����� �� ���������� � ����� ���������� ������� ������----------------
// ���������������� �� Atmel Studio 4 � Atmel Studio 6.0.1996 - Service Pack 2. 23 ������� 2018�.
// ��������������� Attiny2313
// ������� ����� 16MHz
// dat AT ���������� ��������� �� PD3
// clk AT ���������� ��������� �� PD2 ������� ���������� 0 (INT0)
// ��������� ��������� ���� ������ �� ���������� �� ��������� clk AT ���������� (�� ����� ��������)
// ������ ���������� ������ : ������� HOLD1 -  HOLD7	  - PB0-PB7 pins 12 - 19
//							  �������� ��������			  - PD4 pin 8
//							  ������� �������			  - PD6 pin 11
//							  ������� �������� ���������� - PD5 pin 9
//							  ������� ������� ����������  - PD5 pin 9
// UART RXD (PD0 - pin 2), TXD (PD1 - pin 3) ��������� � ���������� TTL-RS232, 
// �������������� ������������ ���������� ���������� ����������� ����� ����� � � �������
// ��� ����������/������ �������� � ����� � ������� ����������. ���� � �������� ���������� 
// ������������� � ����������.
// ���������� �������� � ������������ � ����������� �������: 
// ����� 1 - 10 ���������
// ����� 2 - 20 ���������
// ����� 3 - 30 ���������
// ����� 4 - 40 ���������
// ����� 5 - 50 ���������
// ����� 6 - 1 �������
// ����� 7 - 5 �������
// ����������� 27 ������ 2009�.
// Snibler
;--------�������������-------------------------------
.include "tn2313def.inc"
.def temp=r16		;
.def rab=r17		;��������� ��� ����������� AT ����, ��������� ��������� ������������
.def AT_bits=r18	;����� ����������� ��� �� ����
.def mark_1=r19		;������ ��� ���������� ������
.def mark_2=r20		;������ ��� ���������� ������
.def counter=r21	;������� �������� ������� ����� UART
.def comport=r22	;��������� ��� ������� ��� ������ ���������� ����� UART
.def answer=r23		;����� �������
.equ CPU		='0';� ������� 1
.equ coinA		='k';������� ���������� ��������
.equ stop_coinA	='s';������� �������� ���������� ��������
.equ payout		='p';������� �������
.equ longstat	='l';������� ������� ����������
.equ kwait_short=700;(1000)	;65535 max numb ����� ������ <40(50)ms
.equ kwait_long=800	;(2000)	;65535 max numb ����� ������ <50(100)ms
.equ hold1=0x16		;���� ��� ������� 1			�������� 0-� ����� ����� �
.equ hold2=0x1E		;���� ��� ������� 2			�������� 1-� ����� ����� �
.equ hold3=0x26		;���� ��� ������� 3			�������� 2-� ����� ����� �
.equ hold4=0x25		;���� ��� ������� 4			�������� 3-� ����� ����� �
.equ hold5=0x2E		;���� ��� ������� 5			�������� 4-� ����� ����� �
.equ hold6=0x29		;���� ��� ������� Space		�������� 5-� ����� ����� �
.equ hold7=0x11		;���� ��� ������� Alt(L)	�������� 6-� ����� ����� �
.equ hold8=0x12		;���� ��� ������� Shift(L)	�������� 7-� ����� ����� �
.equ release=0xF0	;���� ��� ���������� ������� ��������� ��� ������ ����� �
.equ stat1=0x1B		;���� ��� ������� S			���������� 1-� ��� ������� � ����������
.equ stat2=0x2C		;���� ��� ������� T			���������� 2-� ��� ������� � ����������
.equ stat3=0x5A		;���� ��� ������� ENTER		������ ������� �� 5-� ����� ����� D (�������� ����������)
;-----------������ ����������� ����-------------------------------------------------
.cseg						;����� �������� ����������� ����
.org 0x0000					;��������� �������� ������ �� 0
;--------��������������� �������� ����������-----------
start:	
	rjmp init			;������� �� ������ ���������
	rjmp read_AT_code	;INT0  ������� ���������� 0
	reti				;INT1  ������� ���������� 1
	reti				;ICP1  ������/������� 1, ������
	reti 				;OC1A  ������/������� 1, ����������, ����� �
	reti 				;OVF1  ������/������� 1, ���������� �� ������������
	reti				;OVF0  ������/������� 0, ���������� �� ������������
	rjmp UART_comand	;URXC0 ���������� UART ����� ��������
	reti				;UDRE0 ���������� UART ������� ������ ����
	reti				;UTXC0 ���������� UART �������� ���������
	reti				;ACI   ���������� �� �����������
	reti 				;PCINT ���������� �� ��������� �� ����� ��������
	reti				;OC1B  ������/������� 1. ����������, ����� �
	reti				;OC0A  ������/������� 0. ����������, ����� �
	reti				;OC0B  ������/������� 0. ����������, ����� �
	reti				;USI_START  USI ���������� � ������
	reti				;USI_OVF    USI ������������
	reti				;ERDY       EEPROM ����������
	reti				;WDT        ������������ ��������� �������
;------������ �������������------------------------
init: 
;-----������������� �����--------------------------
	ldi temp, RAMEND	;����� ������ ������� �����
	out SPL, temp		;������ ��� � ������� �����
;-----������������� ������ ����� ������------------
	ldi temp, 0b11111111;
	out DDRB, temp		;data direction register of port B �� ����(0) � �����(1)
	ldi temp, 0b11111111
	out PORTB, temp		;�������� ������������� ��������

	ldi temp, 0b1110000	;
	out DDRD, temp		;���� D �������� �� ���� � �����
	ldi temp, 0b1111111
	out PORTD, temp		;�������� ��������. ��������
;---------������������� �������----------------------
	ldi temp, 0x5		;������������� ������ clk i/o /1024
	out TCCR0B, temp	;��� ������� 0 clkI/O/1024 (From prescaler)
	out TCCR1B, temp	;��� ������� 1 clkI/O/1024 (From prescaler)
;---------����������� ����� ����������---------------
	ldi temp, 0x40
	out GIMSK, temp		;��������� ������� ���������� 0
;---------������������� �����������-----------------
	ldi temp, 0x80		;���������� �����������
	out ACSR, temp
	ldi temp, 0x02		;������� ���������� �� ��������� ������� �� int0
	out MCUCR, temp
;--------��������� ������� ���������--------
	clr temp
	clr rab
	clr AT_bits
	clr mark_1
	clr mark_2
	clr comport
	clr answer
	clr counter
	clr Xl
	clr Xh
;---------������������� USART----------------------
USART_Init: 
	cli
	ldi temp, 0x00			;Set baud rate 9600
	;ldi rab, 129			;20MHz
	ldi rab, 103			;16MHz
	out UBRRH, temp
	out UBRRL, rab
	ldi rab, (0<<U2X|1<<MPCM)			;Asynchronous Normal mode (U2X = 0), Multi-processor Communication Mode on
	out UCSRA, rab
	ldi rab, (1<<RXEN|1<<TXEN|1<<RXCIE)	;Enable receiver and transmitter, receive complete interrupt
	out UCSRB, rab
	ldi rab, (3<<UCSZ0)					; Set frame format: 8data
	out UCSRC, rab
;---------Main programm------------------------------
main:
	sei					;��������� ���������� ����������
	cpi rab, 0			;������ �� ���� ������ �� �����
	breq main
	cpi AT_bits, 10		;��� �� ���� ���������
	breq received_command
	rjmp main
;-------�������� �� ���������� ����������� �� ����-----
received_command:	
	cli					;��������� ���������� ����������
	cpi rab, release	;������� ��������?
	breq rel
	cpi rab, hold1		;������ ������� hold1
	breq h1
	cpi rab, hold2		;������ ������� hold2
	breq h2
	cpi rab, hold3
	breq h3
	cpi rab, hold4
	breq h4
	cpi rab, hold5
	breq h5
	cpi rab, hold6
	breq h6
	cpi rab, hold7
	breq h7
	cpi rab, hold8
	breq h8
	cpi rab, stat1
	breq st1	
	cpi rab, stat2
	breq st2
	cpi rab, stat3
	breq st3
	rjmp main	
;------��� ���������� �������--------
rel:	
	clr Zl
	clr Zh
	cpi mark_2, 1
	breq m1
	ldi mark_1, 1
m2:	ser temp
	out PORTB, temp		;��������� �������� ������ ���� ������� ����� �
	clr rab
	rjmp main
m1:	clr mark_2
	rjmp m2
;------��� ������� �������----------
h1:	cbi PORTB, 0	;��������� ������� ������ 0-�� ������ �����
	rjmp main
h2:	cbi PORTB, 1
	rjmp main
h3:	cbi PORTB, 2
	rjmp main
h4:	cbi PORTB, 3
	rjmp main
h5:	cbi PORTB, 4
	rjmp main
h6:	cbi PORTB, 5
	rjmp main
h7:	cbi PORTB, 6
	rjmp main
h8:	cbi PORTB, 7
	rjmp main
st1:mov Zl, rab	;���������� 1-� ���� ������� � ����������
	rjmp main
st2:mov Zh, rab	;���������� 2-� ���� ������� � ����������
	rjmp main
st3:cpi Zl, stat1;�������� ������� �����
	brne m9
	cpi Zh, stat2;�������� ������� �����
	brne m9
;-------������� �� �������� ���������� � ����������------
	cbi PORTD, 5			
	rcall wait_long			
	rcall wait_long			
	rcall wait_long
	rcall wait_long			
	rcall wait_long			
	rcall wait_long
	sbi PORTD, 5			
	clr Zl
	clr Zh
	clr rab
	rjmp success_answer			;�������� ���������� �������� ����������
m9:rjmp main

;-------��������� ��������� ���������� �� clk �� ����������---------------
read_AT_code:
	push temp
	cpi AT_bits, 0		;���� ���� "start"
	brne start_bits
	sbic pind, 3			;���������� ���� ������� ��� ������ "start"
	rjmp exit
start_bits:	
	cpi AT_bits, 0		;���� ������� ���� ������
	breq next_bit
	cpi AT_bits, 9		;���� �������� "parity bit"
	breq next_bit
	cpi AT_bits, 10		;���� �������� ���� "stop"
	brsh full			
	in temp, pind		;������ ������ � ������� ����� D
	bst temp, 3			;��������� 3-� ��� ����� � �
	bld rab, 7			;��������� ��� �� � � ������� ��� �������� rab
	cpi AT_bits, 8		;���� ����� �� ���������� ���� ������ - ������ �� ��������
	breq last_data_bit
	lsr rab				;�������� ���� �������� rab ������
next_bit:	
	inc AT_bits
	rjmp exit
last_data_bit:
	inc AT_bits
	cpi mark_1, 1
	brne exit
	ldi rab, release
	ldi mark_2, 1
	clr mark_1
	rjmp exit
full:clr AT_bits
exit:pop temp
reti					;������� �� ���������� �� clk �� ����������

;-------��������� ��������� ���������� �� UART ����� ��������---------------
UART_comand:
	cli
	push temp
	push rab
	push Zh
	push Zl
	in comport, UDR			;������ ������ �� ������ UART � ���������
	sbis UCSRA, 0			;���������� ���� ������� ������������������ �����
	rjmp command			;���� �������� ������������������ �����, ������� � ��������� ������
	cpi comport, CPU			;��������� ������ �� ���� ���������
	brne quit				;���� �� ���� ���� �� ����� �� ����������
	ldi rab, (0<<U2X|0<<MPCM);Asynchronous Normal mode (U2X = 0), Multi-processor Communication Mode off
	out UCSRA, rab
quit:rjmp stop				;����� �� ����������
command:
	cpi comport, payout		;������ �������� �������?
	breq pay_out
	cpi comport, longstat	;������ �������� ������� ����������?
	breq long_stat
	cpi comport, coinA		;������ �������� ���������� ��������?
	breq credit_count
	cpi comport, stop_coinA	;������ �������� ��������� ���������� ��������?
	breq credit				;���������� ��������
	cpi counter, 1			;���� ��� �� ������� ��������� �� �����
	brsh check1
	rjmp stop				;����� �� ����������
check1:
	cpi comport, 58			;���� ����� <= 9 ��������� ������
	brlo check2
	rjmp stop				;����� �� ����������
check2:
	cpi comport, 48			;���� ����� >= 0 ��������� � �������� ��������
	brsh credit_count
	rjmp stop				;����� �� ����������
credit_count:
	inc counter
	subi comport, 48			;������ ASCII "0"
	cpi counter, 1			;��� �� ����� ���� ��� �������
	breq stop				;����� �� ����������
	cpi comport, 1			
	brne m3
	adiw X, 10				;��������� 10 ��������
	rjmp stop				;����� �� ����������
m3:cpi comport, 2
	brne m4
	adiw X, 20				;��������� 20 ��������
	rjmp stop				;����� �� ����������
m4:cpi comport, 3
	brne m5
	adiw X, 30				;��������� 30 ��������
	rjmp stop				;����� �� ����������
m5:cpi comport, 4
	brne m6
	adiw X, 40				;��������� 40 ��������
	rjmp stop				;����� �� ����������
m6:cpi comport, 5
	brne m7
	adiw X, 50				;��������� 50 ��������
	rjmp stop				;����� �� ����������
m7:cpi comport, 6
	brne m8
	adiw X, 1				;��������� 1 ������
	rjmp stop				;����� �� ����������
m8:cpi comport, 7
	brne stop
	adiw X, 5				;��������� 5 ��������
	rjmp stop				;����� �� ����������
;-------������� �������� ������� ��������� � �� ����������---------
credit:
	clr counter
	cpi Xh, 0
	brne start_imp_credit
	cpi Xl, 0
	breq success_answer	;�������� ���������� �������� ������� �������
start_imp_credit:
	cbi PORTD, 4			;������������ �������� 
	rcall wait_long		;�������
	sbi PORTD, 4			;
	rcall wait_short	;
	sbiw X, 1			;������� �� ����� 1 (������-1)
	rjmp credit
pay_out:
	cbi PORTD, 6
	rcall wait_long		;������� ��
	rcall wait_long		;�������
	rcall wait_long		;
	rcall wait_long		;
	sbi PORTD, 6
	rjmp success_answer	;�������� ���������� �������� �������
long_stat:
	cbi PORTD, 5			
	rcall wait_long		;������� ��
	rcall wait_long		;����������
	sbi PORTD, 5			
	clr Zl
	clr Zh
;---------�������� ���������� ������� ���������� �� UART--------------
success_answer:
	ldi rab, (0<<U2X|1<<MPCM);Asynchronous Normal mode (U2X = 0), Multi-processor Communication Mode on
	out UCSRA, rab
	ldi ZL, low(ok*2)		;��������� ����� ��� ��������
	ldi ZH, high(ok*2)		;������ ok ������
next:
	lpm YL, Z+				;��������� ������ �� �������
	lpm YH, Z				;� �������� � Y
	lpm answer, Z			;��������� ��� �� �������
	cpi answer, 29			;���� ����� 29(������) ����������� ��������
	breq stop
	rcall USART_Transmit	;��������
	rjmp next
stop:
	clr comport
	clr answer
	pop Zl
	pop Zh
	pop rab
	pop temp
	reti					;������� �� ���������� �� UART ����� ��������
;---------------------------------------------------------------------------
USART_Transmit:
	sbis UCSRA, UDRE		; Wait for empty transmit buffer
	rjmp USART_Transmit
	out UDR, answer			; Put data (rab) into buffer, sends the data
	ret
;---------------------------------------------------------------------------
;-----������ �������� ������--------------
ok: .db 0,'o','k',29		;ok

;-----------�������� ��������-------------
wait_short:	
	ldi temp, 0
	out TCNT1H, temp
	out TCNT1L, temp
wt1:in temp, TCNT1L
	cpi temp, low(kwait_short)
	brlo wt1
	in temp, TCNT1H
	cpi temp, high(kwait_short)
	brlo wt1
	ret
;---------�������� �������---------------
wait_long:
	ldi temp, 0
	out TCNT1H, temp
	out TCNT1L, temp
wt2:in temp, TCNT1L
	cpi temp, low(kwait_long)
	brlo wt2
	in temp, TCNT1H
	cpi temp, high(kwait_long)
	brlo wt2
	ret