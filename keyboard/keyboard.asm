;------------ASM Программа декодирования скан кодов АТ клавиатуры в ключи управления игровой платой----------------
// Проимпортировано из Atmel Studio 4 в Atmel Studio 6.0.1996 - Service Pack 2. 23 февраля 2018г.
// Микроконтроллер Attiny2313
// Внешний кварц 16MHz
// dat AT клавиатуры подключен на PD3
// clk AT клавиатуры подключен на PD2 внешнее прерывание 0 (INT0)
// программа считывает коды клавиш по прерыванию от импульсов clk AT клавиатуры (по спаду импульса)
// выводы управления платой : клавиши HOLD1 -  HOLD7	  - PB0-PB7 pins 12 - 19
//							  импульсы кредитов			  - PD4 pin 8
//							  импульс выплаты			  - PD6 pin 11
//							  импульс короткой статистики - PD5 pin 9
//							  импульс длинной статистики  - PD5 pin 9
// UART RXD (PD0 - pin 2), TXD (PD1 - pin 3) подключен к конвертору TTL-RS232, 
// поразумевается параллельное соединение нескольких процессоров между собой и к серверу
// для начисления/снятия кредитов и входа в длинную статистику. Вход в короткую статистику 
// производиться с клавиатуры.
// начисление кредитов в соответствии с полученными данными: 
// цифра 1 - 10 импульсов
// цифра 2 - 20 импульсов
// цифра 3 - 30 импульсов
// цифра 4 - 40 импульсов
// цифра 5 - 50 импульсов
// цифра 6 - 1 импульс
// цифра 7 - 5 импульс
// разработано 27 ноября 2009г.
// Snibler
;--------макроасемблер-------------------------------
.include "tn2313def.inc"
.def temp=r16		;
.def rab=r17		;контейнер для полученного AT кода, установки регистров конфигурации
.def AT_bits=r18	;число прочитанных бит АТ кода
.def mark_1=r19		;маркер для отпускания кнопки
.def mark_2=r20		;маркер для отпускания кнопки
.def counter=r21	;счетчик принятых посылок через UART
.def comport=r22	;контейнер для команды или данных полученных через UART
.def answer=r23		;ответ серверу
.equ CPU		='0';№ клиента 1
.equ coinA		='k';команда начисления кредитов
.equ stop_coinA	='s';команда останова начисления кредитов
.equ payout		='p';команда выплаты
.equ longstat	='l';команда длинной статистики
.equ kwait_short=700;(1000)	;65535 max numb потух кредит <40(50)ms
.equ kwait_long=800	;(2000)	;65535 max numb горит кредит <50(100)ms
.equ hold1=0x16		;скан код клавиши 1			включает 0-й вывод порта В
.equ hold2=0x1E		;скан код клавиши 2			включает 1-й вывод порта В
.equ hold3=0x26		;скан код клавиши 3			включает 2-й вывод порта В
.equ hold4=0x25		;скан код клавиши 4			включает 3-й вывод порта В
.equ hold5=0x2E		;скан код клавиши 5			включает 4-й вывод порта В
.equ hold6=0x29		;скан код клавиши Space		включает 5-й вывод порта В
.equ hold7=0x11		;скан код клавиши Alt(L)	включает 6-й вывод порта В
.equ hold8=0x12		;скан код клавиши Shift(L)	включает 7-й вывод порта В
.equ release=0xF0	;скан код отпускания клавиши выключает все выводы порта В
.equ stat1=0x1B		;скан код клавиши S			записывает 1-й код доступа к статистике
.equ stat2=0x2C		;скан код клавиши T			записывает 2-й код доступа к статистике
.equ stat3=0x5A		;скан код клавиши ENTER		подает импульс на 5-й вывод порта D (открытие статистики)
;-----------Начало програмного кода-------------------------------------------------
.cseg						;выбор сегмента програмного кода
.org 0x0000					;установка текущего адреса на 0
;--------Переопределение векторов прерываний-----------
start:	
	rjmp init			;Переход на начало программы
	rjmp read_AT_code	;INT0  Внешнее прерывание 0
	reti				;INT1  Внешнее прерывание 1
	reti				;ICP1  Таймер/счетчик 1, захват
	reti 				;OC1A  Таймер/счетчик 1, совпадение, канал А
	reti 				;OVF1  Таймер/счетчик 1, прерывание по переполнению
	reti				;OVF0  Таймер/счетчик 0, прерывание по переполнению
	rjmp UART_comand	;URXC0 Прерывание UART прием завершен
	reti				;UDRE0 Прерывание UART регистр данных пуст
	reti				;UTXC0 Прерывание UART передача завершена
	reti				;ACI   Прерывание по компаратору
	reti 				;PCINT Прерывание по изменению на любом контакте
	reti				;OC1B  Таймер/счетчик 1. Совпадение, канал В
	reti				;OC0A  Таймер/счетчик 0. Совпадение, канал А
	reti				;OC0B  Таймер/счетчик 0. Совпадение, канал В
	reti				;USI_START  USI готовность к старту
	reti				;USI_OVF    USI переполнение
	reti				;ERDY       EEPROM готовность
	reti				;WDT        Переполнение охранного таймера
;------Модуль инициализации------------------------
init: 
;-----Инициализация стека--------------------------
	ldi temp, RAMEND	;выбор адреса вершины стека
	out SPL, temp		;запись его в регистр стека
;-----Инициализация портов ввода вывода------------
	ldi temp, 0b11111111;
	out DDRB, temp		;data direction register of port B на вход(0) и выход(1)
	ldi temp, 0b11111111
	out PORTB, temp		;включаем подтягивающий резистор

	ldi temp, 0b1110000	;
	out DDRD, temp		;порт D частично на вход и выход
	ldi temp, 0b1111111
	out PORTD, temp		;включаем подтягив. резистор
;---------Инициализация таймера----------------------
	ldi temp, 0x5		;конфигурируем таймер clk i/o /1024
	out TCCR0B, temp	;для таймера 0 clkI/O/1024 (From prescaler)
	out TCCR1B, temp	;для таймера 1 clkI/O/1024 (From prescaler)
;---------Определение маски прерываний---------------
	ldi temp, 0x40
	out GIMSK, temp		;Разрешаем Внешнее прерывание 0
;---------Инициализация компаратора-----------------
	ldi temp, 0x80		;выключение компаратора
	out ACSR, temp
	ldi temp, 0x02		;генерим прерывание по спадающей вершине на int0
	out MCUCR, temp
;--------обнуление рабочих регистров--------
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
;---------Инициализация USART----------------------
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
	sei					;Разрешаем глобальные прерывания
	cpi rab, 0			;пришел ли байт данных от клавы
	breq main
	cpi AT_bits, 10		;все ли биты прочитаны
	breq received_command
	rjmp main
;-------Проверка на совпадение полученного АТ кода-----
received_command:	
	cli					;запрещаем глобальные прерывания
	cpi rab, release	;клавиша отпущена?
	breq rel
	cpi rab, hold1		;нажата клавиша hold1
	breq h1
	cpi rab, hold2		;нажата клавиша hold2
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
;------код отпускания клавиши--------
rel:	
	clr Zl
	clr Zh
	cpi mark_2, 1
	breq m1
	ldi mark_1, 1
m2:	ser temp
	out PORTB, temp		;установка высокого уровня всех выходов порта В
	clr rab
	rjmp main
m1:	clr mark_2
	rjmp m2
;------код нажатия клавиши----------
h1:	cbi PORTB, 0	;установка низкого уровня 0-го выхода порта
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
st1:mov Zl, rab	;записываем 1-й ключ доступа к статистике
	rjmp main
st2:mov Zh, rab	;записываем 2-й ключ доступа к статистике
	rjmp main
st3:cpi Zl, stat1;проверка первого ключа
	brne m9
	cpi Zh, stat2;проверка второго ключа
	brne m9
;-------импульс на короткую статистику с клавиатуры------
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
	rjmp success_answer			;успешное выполнение операции статистики
m9:rjmp main

;-------Программа обработки прерывания по clk от клавиатуры---------------
read_AT_code:
	push temp
	cpi AT_bits, 0		;ждем бита "start"
	brne start_bits
	sbic pind, 3			;пропускаем если сброшен бит данных "start"
	rjmp exit
start_bits:	
	cpi AT_bits, 0		;ждем первого бита данных
	breq next_bit
	cpi AT_bits, 9		;если достигли "parity bit"
	breq next_bit
	cpi AT_bits, 10		;если достигли бита "stop"
	brsh full			
	in temp, pind		;читаем данные с выводов порта D
	bst temp, 3			;сохраняем 3-й бит порта в Т
	bld rab, 7			;загружаем бит из Т в старший бит регистра rab
	cpi AT_bits, 8		;если дошли до последнего бита данных - больше не сдвигаем
	breq last_data_bit
	lsr rab				;сдвигаем биты регистра rab вправо
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
reti					;возврат из прерывания по clk от клавиатуры

;-------Программа обработки прерывания по UART прием завершен---------------
UART_comand:
	cli
	push temp
	push rab
	push Zh
	push Zl
	in comport, UDR			;Читаем данные из буфера UART в контейнер
	sbis UCSRA, 0			;пропустить если включен мультипроцессорный режим
	rjmp command			;если выключен мультипроцессорный режим, перейти к обработке данных
	cpi comport, CPU			;проверить выбран ли этот процессор
	brne quit				;если не этот проц то выйти из прерывания
	ldi rab, (0<<U2X|0<<MPCM);Asynchronous Normal mode (U2X = 0), Multi-processor Communication Mode off
	out UCSRA, rab
quit:rjmp stop				;выйти из прерывания
command:
	cpi comport, payout		;пришла комманда выплаты?
	breq pay_out
	cpi comport, longstat	;пришла комманда длинной статистики?
	breq long_stat
	cpi comport, coinA		;пришла комманда начисления кредитов?
	breq credit_count
	cpi comport, stop_coinA	;пришла комманда закончить начисление кредитов?
	breq credit				;начисление кредитов
	cpi counter, 1			;если это не команда проверяем на цифру
	brsh check1
	rjmp stop				;выйти из прерывания
check1:
	cpi comport, 58			;если цифра <= 9 проверяем дальше
	brlo check2
	rjmp stop				;выйти из прерывания
check2:
	cpi comport, 48			;если цифра >= 0 переходим к подсчету кредитов
	brsh credit_count
	rjmp stop				;выйти из прерывания
credit_count:
	inc counter
	subi comport, 48			;вычтем ASCII "0"
	cpi counter, 1			;еще не цифра если тут впервые
	breq stop				;выйти из прерывания
	cpi comport, 1			
	brne m3
	adiw X, 10				;добавляем 10 кредитов
	rjmp stop				;выйти из прерывания
m3:cpi comport, 2
	brne m4
	adiw X, 20				;добавляем 20 кредитов
	rjmp stop				;выйти из прерывания
m4:cpi comport, 3
	brne m5
	adiw X, 30				;добавляем 30 кредитов
	rjmp stop				;выйти из прерывания
m5:cpi comport, 4
	brne m6
	adiw X, 40				;добавляем 40 кредитов
	rjmp stop				;выйти из прерывания
m6:cpi comport, 5
	brne m7
	adiw X, 50				;добавляем 50 кредитов
	rjmp stop				;выйти из прерывания
m7:cpi comport, 6
	brne m8
	adiw X, 1				;добавляем 1 кредит
	rjmp stop				;выйти из прерывания
m8:cpi comport, 7
	brne stop
	adiw X, 5				;добавляем 5 кредитов
	rjmp stop				;выйти из прерывания
;-------подсчет кредитов окончен переходим к их зачислению---------
credit:
	clr counter
	cpi Xh, 0
	brne start_imp_credit
	cpi Xl, 0
	breq success_answer	;успешное выполнение операции набивки кредита
start_imp_credit:
	cbi PORTD, 4			;формирование импульса 
	rcall wait_long		;кредита
	sbi PORTD, 4			;
	rcall wait_short	;
	sbiw X, 1			;вычесть из слова 1 (кредит-1)
	rjmp credit
pay_out:
	cbi PORTD, 6
	rcall wait_long		;импульс на
	rcall wait_long		;выплату
	rcall wait_long		;
	rcall wait_long		;
	sbi PORTD, 6
	rjmp success_answer	;успешное выполнение операции выплаты
long_stat:
	cbi PORTD, 5			
	rcall wait_long		;импульс на
	rcall wait_long		;статистику
	sbi PORTD, 5			
	clr Zl
	clr Zh
;---------успешное выполнение команды полученной по UART--------------
success_answer:
	ldi rab, (0<<U2X|1<<MPCM);Asynchronous Normal mode (U2X = 0), Multi-processor Communication Mode on
	out UCSRA, rab
	ldi ZL, low(ok*2)		;вычисляем адрес где хранится
	ldi ZH, high(ok*2)		;начало ok записи
next:
	lpm YL, Z+				;Извлекаем адреса из таблицы
	lpm YH, Z				;и помещаем в Y
	lpm answer, Z			;Извлекаем код из таблицы
	cpi answer, 29			;если равен 29(пробел) заканчиваем передачу
	breq stop
	rcall USART_Transmit	;передача
	rjmp next
stop:
	clr comport
	clr answer
	pop Zl
	pop Zh
	pop rab
	pop temp
	reti					;возврат из прерывания по UART прием завершен
;---------------------------------------------------------------------------
USART_Transmit:
	sbis UCSRA, UDRE		; Wait for empty transmit buffer
	rjmp USART_Transmit
	out UDR, answer			; Put data (rab) into buffer, sends the data
	ret
;---------------------------------------------------------------------------
;-----массив байтовых данных--------------
ok: .db 0,'o','k',29		;ok

;-----------Задержка короткая-------------
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
;---------Задержка длинная---------------
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