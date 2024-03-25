NAKINI is set to zero by USB_RESET
(LED would be on if it was not zero).

This ch-file is tested with attach device,
with reboot host and with `sudo usbreset 03eb:2018'.

@x
  UDINT &= ~_BV(EORSTI);
@y
  UENUM = 1;
  if (UEINTX & _BV(NAKINI)) DDRD |= _BV(PD5);
  UDINT &= ~_BV(EORSTI);
@z
