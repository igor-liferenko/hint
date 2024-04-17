all:
	@echo NoOp

h:
	ctangle hint
	@make --no-print-directory hint

hint:
	avr-gcc -mmcu=atmega32u4 -DF_CPU=16000000UL -g -Os -o fw.elf hint.c

flash:
	avr-objcopy -O ihex fw.elf fw.hex
	avrdude -qq -c usbasp -p atmega32u4 -U efuse:v:0xcb:m -U hfuse:v:0xd9:m -U lfuse:v:0xff:m -U flash:w:fw.hex
