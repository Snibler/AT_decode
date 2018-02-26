# AT_decode
Программа декодирует коды заданных клавиш АТ клавиатуры и эмулирует клавиши управления платой игрового автомата.

 Микроконтроллер Attiny2313А
 
 Внешний кварц 16MHz
 
 dat AT клавиатуры подключен на PD3 (pin 7)
 
 clk AT клавиатуры подключен на PD2 (pin 6) внешнее прерывание 0 (INT0)
 
 программа считывает коды клавиш по прерыванию от импульсов clk AT клавиатуры (по спаду импульса)
 
 выводы управления платой : клавиши HOLD1 -  HOLD7	  - PB0-PB7 pins 12 - 19
							  импульсы кредитов			      - PD4 (pin 8)
							  импульс выплаты			        - PD6 (pin 11)
							  импульс короткой статистики - PD5 (pin 9)
							  импульс длинной статистики  - PD5 (pin 9)
							  
 UART RXD (PD0 - pin 2), TXD (PD1 - pin 3) подключен к конвертору TTL-RS232, 
 
 поразумевается параллельное соединение нескольких процессоров между собой и к серверу
 
 для начисления/снятия кредитов и входа в длинную статистику. Вход в короткую статистику 
 
 производиться с клавиатуры.
 
 начисление кредитов в соответствии с полученными данными: 
 
 цифра 1 - 10 импульсов
 
 цифра 2 - 20 импульсов
 
 цифра 3 - 30 импульсов
 
 цифра 4 - 40 импульсов
 
 цифра 5 - 50 импульсов
 
 цифра 6 - 1 импульс
 
 цифра 7 - 5 импульс
 
 разработано 27 ноября 2009г.
