stty -F /dev/ttyUSB0 raw 115200; cat /dev/ttyUSB0

@x
UCSR1B |= _BV(RXEN1);
@y
UCSR1B |= _BV(RXEN1) | _BV(TXEN1);
@z

@x
  UECFG1X = _BV(EPSIZE0) | _BV(EPSIZE1) | _BV(ALLOC); /* 64 bytes */
@y
  UECFG1X = _BV(EPSIZE0) | _BV(EPSIZE1) | _BV(ALLOC); /* 64 bytes */
  if (!(UESTA0X & _BV(CFGOK))) DDRD |= _BV(PD5);
@z

@x
  UDINT &= ~_BV(EORSTI);
@y
  UDINT &= ~_BV(EORSTI);
  tx_char('\n');
  tx_char('!');
  tx_char(' ');
@z

@x
@* USB connection.
@y
@* USB connection.
@d tx_char(c) do { UDR1 = c; while (!(UCSR1A & _BV(UDRE1))) { } } while (0)
@d HEX(c) tx_char((c)<10 ? (c)+'0' : (c)-10+'A')
@d hex(c) HEX((c >> 4) & 0x0f); HEX(c & 0x0f);
@z

@x
    UEINTX &= ~_BV(RXSTPI);
@y
    UEINTX &= ~_BV(RXSTPI);
    tx_char('?');
    tx_char(' ');
@z

@x address
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char('a');
tx_char('=');
hex(wValue);
tx_char(' ');
@z

@x device
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char('d');
hex(wLength);
if (UDADDR & _BV(ADDEN))
  tx_char(' ');
else
  tx_char('-');
@z

@x configuration
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char('c');
hex(wLength);
tx_char(' ');
@z

@x hid report
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char('h');
hex(wLength);
tx_char(' ');
@z

@x set configuration
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char(wValue == CONF_NUM ? 's' : '@@');
tx_char(' ');
@z

@x set idle
UEINTX &= ~_BV(RXSTPI);
@y
UEINTX &= ~_BV(RXSTPI);
tx_char('i');
tx_char(' ');
@z

@x
UECFG1X = _BV(ALLOC);
@y
UECFG1X = _BV(ALLOC);
if (!(UESTA0X & _BV(CFGOK))) DDRD |= _BV(PD5);
@z
