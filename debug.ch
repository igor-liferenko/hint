cu -l /dev/ttyUSB0 -s 115200

@x show data sent to USB
  datap++;
@y
  UDR1 = *datap; while (!(UCSR1A & _BV(UDRE1))) { }
  datap++;
  if (*datap == 0) {
    UDR1 = '\r'; while (!(UCSR1A & _BV(UDRE1))) { }
    UDR1 = '\n'; while (!(UCSR1A & _BV(UDRE1))) { }
  }
@z

@x
UCSR1B |= _BV(RXEN1);
@y
UCSR1B |= _BV(RXEN1) | _BV(TXEN1);
@z

@x show data read from serial
  if (d == '\n') break;
@y
  if (d == '\n') {
    UDR1 = '\r'; while (!(UCSR1A & _BV(UDRE1))) { }
    UDR1 = '\n'; while (!(UCSR1A & _BV(UDRE1))) { }
    break;
  }
  UDR1 = d; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x
  UDINT &= ~_BV(EORSTI);
@y
  UDINT &= ~_BV(EORSTI);
  UDR1 = '!'; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x
  UECFG1X |= _BV(ALLOC);
@y
  UECFG1X |= _BV(ALLOC);
  if (!(UESTA0X & _BV(CFGOK))) {
    cli();
    UDR1='0'; while (1) { }
  }
@z

@x
@* USB connection.
@y
@* USB connection.
@d HEX(c) UDR1 = ((c)<10 ? (c)+'0' : (c)-10+'A'); while (!(UCSR1A & _BV(UDRE1))) { }
@d hex(c) HEX((c >> 4) & 0x0f); HEX(c & 0x0f);
@z

@x
    UEINTX &= ~_BV(RXSTPI);
@y
    UEINTX &= ~_BV(RXSTPI);
    UDR1='?'; while (!(UCSR1A & _BV(UDRE1))) { }
    UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x address
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1='\r'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1='\n'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1='a'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1='='; while (!(UCSR1A & _BV(UDRE1))) { }
hex(wValue);
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x device
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1='d'; while (!(UCSR1A & _BV(UDRE1))) { }
hex(wLength);
if (UDADDR & _BV(ADDEN)) {
  UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
}
else {
  UDR1='-'; while (!(UCSR1A & _BV(UDRE1))) { }
  UDR1='\r'; while (!(UCSR1A & _BV(UDRE1))) { }
  UDR1='\n'; while (!(UCSR1A & _BV(UDRE1))) { }
}
@z

@x configuration
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1='c'; while (!(UCSR1A & _BV(UDRE1))) { }
hex(wLength);
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x hid report
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1='h'; while (!(UCSR1A & _BV(UDRE1))) { }
hex(wLength);
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x set configuration
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1 = wValue == CONF_NUM ? 's' : '@@'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x set idle
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1='i'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x
UECFG1X |= _BV(ALLOC);
@y
UECFG1X |= _BV(ALLOC);
if (!(UESTA0X & _BV(CFGOK))) {
  cli();
  UDR1='1'; while (1) { }
}
@z
