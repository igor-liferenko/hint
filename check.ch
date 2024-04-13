@x
@<Global variables@>@;
@y
@<Global variables@>@;
U16 millis = 0;
@z


@x
      @<Process CONTROL packet@>@;
@y
      @<Process CONTROL packet@>@;
    if (millis < 2000) {
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

@x
  UDINT &= ~_BV(EORSTI);
@y
  millis = 0;
  datap = data;
  UDINT &= ~_BV(EORSTI);
@z
