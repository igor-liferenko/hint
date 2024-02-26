cu -l /dev/ttyUSB0 -s 57600

@x
  @<Setup USB Controller@>@;
@y
  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= _BV(U2X1);
  UCSR1B |= _BV(TXEN1);
  @<Setup USB Controller@>@;
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

@x set line coding
  UEINTX &= ~_BV(RXSTPI);
@y
  UEINTX &= ~_BV(RXSTPI);
  UDR1='%'; while (!(UCSR1A & _BV(UDRE1))) { }
  UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x set control line state
  UEINTX &= ~_BV(RXSTPI);
@y
  wValue = UEDATX | UEDATX << 8;
  UEINTX &= ~_BV(RXSTPI);
  UDR1='x'; while (!(UCSR1A & _BV(UDRE1))) { }
  UDR1='='; while (!(UCSR1A & _BV(UDRE1))) { }
  hex(wValue);
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

@x set configuration
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
UDR1 = wValue == CONF_NUM ? 's' : '@@'; while (!(UCSR1A & _BV(UDRE1))) { }
UDR1=' '; while (!(UCSR1A & _BV(UDRE1))) { }
@z

@x
UECFG1X |= _BV(ALLOC);
@y
UECFG1X |= _BV(ALLOC);
if (!(UESTA0X & _BV(CFGOK))) {
  cli();
  UDR1='3'; while (1) { }
}
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

@x
UECFG1X |= _BV(ALLOC);
@y
UECFG1X |= _BV(ALLOC);
if (!(UESTA0X & _BV(CFGOK))) {
  cli();
  UDR1='2'; while (1) { }
}
@z
