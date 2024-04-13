@x
  while (1) {
    UENUM = 0;
    if (UEINTX & _BV(RXSTPI))
      @<Process CONTROL packet@>@;
@y
  U16 millis = 0;
  datap = data;
  while (1) {
    UENUM = 0;
    if (UEINTX & _BV(RXSTPI))
      @<Process CONTROL packet@>@;
    if (millis < 1000) {
      if (UDINT & _BV(SOFI)) {
        UDINT &= ~_BV(SOFI);
        millis++;
      }
      continue;
    }
@z

@x
while (1) {
  while (!(UCSR1A & _BV(RXC1))) { }
  d = UDR1;
  if (d == '+') {
    while (!(UCSR1A & _BV(RXC1))) { }
    d = UDR1;
    if (d == '+') {
      while (!(UCSR1A & _BV(RXC1))) { }
      d = UDR1;
      if (d == '+') break;
    }
  }
}
@y
@z

@x
while (1) {
  while (!(UCSR1A & _BV(RXC1))) { }
  d = UDR1;
  if (d == '\n') break;
  *datap++ = d;
}
@y
for (char *c = "congratulations"; *c != '\0'; c++)
  *datap++ = *c;
@z
