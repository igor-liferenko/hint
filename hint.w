% TODO: make comments to values of all descriptors match HID spec
% TODO: create function send_descriptor from @<Handle {\caps get descriptor configuration}@> and
%       use it in @<Handle {\caps get descriptor configuration}@> and
%       @<Handle {\caps get descriptor hid report}@>
% TODO: change *(datap++) to *datap? (check that md5 of compiled binary is the same) and
%   change (*datap == 0) to !*datap? (in hid.w and debug.ch; check the same way)

\datethis

\font\caps=cmcsc10 at 9pt

\secpagedepth=2

@* Program.

WARNING: do not press any button until LED stops glowing (USB connection will not
be completed because one IN packet arrives before HID report request and we get stuck
in |@<Process IN packet@>| waiting for next IN packet)

@d DATA_SIZE 50

@c
@<Header files@>@;
@<Type definitions@>@;
@<Global variables@>@;
@<Create ISR...@>@;

void main(void)
{
  DDRB |= _BV(PB0); /* set OUTPUT mode (LED is turned on automatically) */
  @<Read data@>@;
  PORTB |= _BV(PB0); /* turn off the LED (on pro-micro it is inverted) */
  @#
  PORTD |= _BV(PD1);
  _delay_us(1);
  @#
  @<Setup USB Controller@>@;
  sei();
  UDCON &= ~_BV(DETACH); /* attach after we enabled interrupts, because
    USB\_RESET arrives after attach */
  @#
  while (1) {
    UENUM = 0;
    if (UEINTX & _BV(RXSTPI))
      @<Process CONTROL packet@>@;
    UENUM = 1;
    if (*datap && (UEINTX & _BV(TXINI)))
      @<Process IN packet@>@;
    if ((*datap == 0) && !(PIND & _BV(PD1))) datap = data; /* first condition serves as debounce */
  }
}

@ @<Type definitions@>=
typedef unsigned char U8;
typedef unsigned short U16;

@ @<Process IN packet@>= {
  UEINTX &= ~_BV(TXINI);
  UEDATX = ascii_to_hid_key_map[*datap-32][0];
  UEDATX = 0;
  UEDATX = ascii_to_hid_key_map[*datap-32][1];
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEINTX &= ~_BV(FIFOCON);
  _delay_ms(10);
  @#
  while (!(UEINTX & _BV(TXINI))) { }
  UEINTX &= ~_BV(TXINI);
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEDATX = 0;
  UEINTX &= ~_BV(FIFOCON);
  _delay_ms(50);
  @#
  datap++;
}

@ @<Global...@>=
char d, data[DATA_SIZE+1], *datap;

@ @<Read data@>=
UBRR1 = 16; // table 18-12 in datasheet
UCSR1A |= _BV(U2X1);
UCSR1B |= _BV(RXEN1);
@#
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
@#
datap = data;
while (1) {
  while (!(UCSR1A & _BV(RXC1))) { }
  d = UDR1;
  if (d == '\n') break;
  *(datap++) = d;
}
*datap = 0;

@* USB setup.

@ \.{USB\_RESET} signal is sent when device is attached and when USB host reboots.

TODO: use d40- as event for configuring EP0 and get rid of ISR?

@<Create ISR for USB\_RESET@>=
@.ISR@>@t}\begingroup\def\vb#1{\.{#1}\endgroup@>@=ISR@>
  (@.USB\_GEN\_vect@>@t}\begingroup\def\vb#1{\.{#1}\endgroup@>@=USB_GEN_vect@>)
{
  UDINT &= ~_BV(EORSTI);
  @#
  /* TODO: datasheet section 21.13 says that ep0 can be configured before detach - try to do this
     there instead of in ISR (and/or try to delete `de-configure' lines) */
  UENUM = 0;
  UECONX &= ~_BV(EPEN); /* de-configure */
  UECFG1X &= ~_BV(ALLOC); /* de-configure */
  UECONX |= _BV(EPEN);
  UECFG0X = 0;
  UECFG1X = _BV(EPSIZE0) | _BV(EPSIZE1); /* 64 bytes (max) */
  UECFG1X |= _BV(ALLOC);
  @#
  /* TODO: try to delete the following */
  UENUM = 1;
  UECONX &= ~_BV(EPEN);
  UECFG1X &= ~_BV(ALLOC);
}

@ @<Setup USB Controller@>=
UHWCON |= _BV(UVREGE);
USBCON |= _BV(USBE);
PLLCSR = _BV(PINDIV);
PLLCSR |= _BV(PLLE);
while (!(PLLCSR & _BV(PLOCK))) { }
USBCON &= ~_BV(FRZCLK);
USBCON |= _BV(OTGPADE);
UDIEN |= _BV(EORSTE);

@* USB connection.

@<Global variables@>=
U16 wValue;
U16 wIndex;
U16 wLength;
U16 size;
const void *buf;

@ @<Process CONTROL packet@>=
switch (UEDATX | UEDATX << 8) { /* Request and Request Type */
case 0x0500: @/
  @<Handle {\caps set address}@>@;
  break;
case 0x0680: @/
  switch (UEDATX | UEDATX << 8) { /* Descriptor Type and Descriptor Index */
  case 0x0100: @/
    @<Handle {\caps get descriptor device}@>@;
    break;
  case 0x0200 | CONF_NUM - 1: @/
    @<Handle {\caps get descriptor configuration}@>@;
    break;
  default: @/
    UECONX |= _BV(STALLRQ);
    UEINTX &= ~_BV(RXSTPI);
  }
  break;
case 0x0681: @/
  @<Handle {\caps get descriptor hid report}@>@;
  break;
case 0x0900: @/
  @<Handle {\caps set configuration}@>@;
  break;
case 0x0a21: @/
  @<Handle {\caps set idle}@>@;
}

@ @<Handle {\caps set address}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
UDADDR = wValue;
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(TXINI))) { } /* see \S22.7 in datasheet */
UDADDR |= _BV(ADDEN);

@ @<Handle {\caps get descriptor device}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
buf = &dev_desc;
size = wLength > sizeof dev_desc ? sizeof dev_desc : wLength;
while (size) UEDATX = pgm_read_byte(buf++), size--;
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ @<Handle {\caps get descriptor configuration}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
buf = &conf_desc;
size = wLength > sizeof conf_desc ? sizeof conf_desc : wLength;
for (U8 c = size / EP0_SIZE; c > 0; c--) {
  while (!(UEINTX & _BV(TXINI))) { }
  for (U8 c = EP0_SIZE; c > 0; c--) UEDATX = pgm_read_byte(buf++);
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(TXINI))) { }
if (size % EP0_SIZE == 0) {
  if (size != wLength) UEINTX &= ~_BV(TXINI); /* ZLP (USB\S5.5.3) */
}
else {
  for (U8 c = size % EP0_SIZE; c > 0; c--) UEDATX = pgm_read_byte(buf++);
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ @<Handle {\caps get descriptor hid report}@>=
(void) UEDATX; @+ (void) UEDATX;
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
buf = &hid_rprt_desc;
size = wLength > sizeof hid_rprt_desc ? sizeof hid_rprt_desc : wLength;
while (size) UEDATX = pgm_read_byte(buf++), size--;
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ @<Handle {\caps set configuration}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
UEINTX &= ~_BV(TXINI);
if (wValue == CONF_NUM) {
  @<Configure EP1@>@;
}

@ @<Handle {\caps set idle}@>=
UEINTX &= ~_BV(RXSTPI);
UEINTX &= ~_BV(TXINI);

@* USB descriptors.

@*1 Device descriptor.

\S9.6.1 in USB spec; \S5.1.1 in CDC spec.

@d EP0_SIZE 64 /* the same as in configuration of EP0 */

@<Global variables@>=
struct {
  U8 bLength;
  U8 bDescriptorType;
  U16 bcdUSB;
  U8 bDeviceClass;
  U8 bDeviceSubClass;
  U8 bDeviceProtocol;
  U8 bMaxPacketSize0;
  U16 idVendor;
  U16 idProduct;
  U16 bcdDevice;
  U8 iManufacturer;
  U8 iProduct;
  U8 iSerialNumber;
  U8 bNumConfigurations;
} const dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  18, @/
  1, /* DEVICE */
  0x0200, /* 2.0 */
  0x00, @/
  0x00, /* constant */
  0x00, /* constant */
  EP0_SIZE, @/
  0x03EB, @/
  0x2015, @/
  0x0100, /* 1.0 */
  0, /* no string */
  0, /* no string */
  0, /* no string */
@t\2@> 1 /* see |CONF_NUM| */
};

@*1 Configuration descriptor.

@<Global variables@>=
@<HID report descriptor@>@;
struct {
  @<Configuration descriptor@>@;
  @<Interface descriptor@>@;
  @<HID descriptor@>@;
  @<Endpoint descriptor@>@;
} const conf_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize Configuration descriptor@>, @/
  @<Initialize Interface descriptor@>, @/
  @<Initialize HID descriptor@>, @/
@t\2@> @<Initialize EP1 descriptor@> @/
};

@*2 Configuration descriptor.

\S9.6.3 in USB spec.

@d CONF_NUM 1 /* see last parameter in |dev_desc| */

@<Initialize Configuration descriptor@>=
SIZEOF_THIS, @/ 
2, /* CONFIGURATION */
SIZEOF_CONF_DESC, @/
1, @/
CONF_NUM, @/
0, @/
1 << 7, @/
250 /* 500 mA */

@*2 Interface descriptor.

\S9.6.5 in USB spec; \S5.1.3 in CDC spec.

@<Initialize Interface descriptor@>=
SIZEOF_THIS, @/
4, /* INTERFACE */
0, @/
0, /* no alternate settings */
1, /* one endpoint */
0x03, @/
0x00, @/
0x00, /* no protocol */
0 /* no string */

@*2 HID descriptor.

@<Initialize HID descriptor@>=
SIZEOF_THIS,
0x21, @/
0x0111, @/
0x00, @/
1, @/
0x22, @/
sizeof hid_rprt_desc

@*2 EP1 descriptor.

\S9.6.6 in USB spec.

@<Initialize EP1 descriptor@>=
SIZEOF_THIS, @/ 
5, /* ENDPOINT */
1 | 1 << 7, @/
0x03, @/
8, @/
0x0F

@ @<Configure EP1@>=
UENUM = 1;
UECONX |= _BV(EPEN);
UECFG0X = _BV(EPTYPE1) | _BV(EPTYPE0) | _BV(EPDIR);
UECFG1X = 0;
UECFG1X |= _BV(ALLOC);

@*2 \bf Configuration descriptor.

@ Configuration descriptor.

\S9.6.3 in USB spec.

@<Configuration descriptor@>=
U8 bLength;
U8 bDescriptorType;
U16 wTotalLength;
U8 bNumInterfaces;
U8 bConfigurationValue;
U8 iConfiguration;
U8 bmAttibutes;
U8 bMaxPower;

@ Interface descriptor.

\S9.6.5 in USB spec.

@<Interface descriptor@>=
U8 bLength;
U8 bDescriptorType;
U8 bInterfaceNumber;
U8 bAlternativeSetting;
U8 bNumEndpoints;
U8 bInterfaceClass;
U8 bInterfaceSubClass;
U8 bInterfaceProtocol;
U8 iInterface;

@ HID descriptor.

@<HID descriptor@>=
U8 bLength;
U8 bDescriptorType;
U16 bcdHID;
U8 bCountryCode;
U8 bNumDescriptors;
U8 bReportDescriptorType;
U16 wReportDescriptorLength;

@ Endpoint descriptor.

\S9.6.6 in USB spec.

@<Endpoint descriptor@>=
U8 bLength;
U8 bDescriptorType;
U8 bEndpointAddress;
U8 bmAttributes;
U16 wMaxPacketSize;
U8 bInterval;

@*1 HID report descriptor.

@<HID report descriptor@>=
const U8 hid_rprt_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x05, 0x01, @t\hskip10pt@> // \.{USAGE\_PAGE (Generic Desktop)}
  0x09, 0x06, @t\hskip10pt@> // \.{USAGE (Keyboard)}
  0xa1, 0x01, @t\hskip10pt@> // \.{COLLECTION (Application)}
  0x05, 0x07, @t\hskip21pt@> //   \.{USAGE\_PAGE (Keyboard)}
  0x75, 0x01, @t\hskip21pt@> //   \.{REPORT\_SIZE (1)}
  0x95, 0x08, @t\hskip21pt@> //   \.{REPORT\_COUNT (8)}
  0x19, 0xe0, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Keyboard LeftControl)}
  0x29, 0xe7, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Right GUI)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x01, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (1)}
  0x81, 0x02, @t\hskip21pt@> //   \.{INPUT (Data,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x01, @t\hskip21pt@> //   \.{REPORT\_COUNT (1)}
  0x81, 0x03, @t\hskip21pt@> //   \.{INPUT (Cnst,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x06, @t\hskip21pt@> //   \.{REPORT\_COUNT (6)}
  0x19, 0x00, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Reserved (no event indicated))}
  0x29, 0x65, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Application)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x65, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (101)}
  0x81, 0x00, @t\hskip21pt@> //   \.{INPUT (Data,Ary,Abs)}
@t\2@> 0xc0   @t\hskip36pt@> // \.{END\_COLLECTION}
};

@* Headers.

\halign{\.{#}\hfil&#\hfil\cr
\noalign{\kern10pt}
%
EORSTE  & End Of Reset Interrupt Enable \cr
EORSTI  & End Of Reset Interrupt \cr
\noalign{\medskip}
FIFOCON & FIFO Control \cr
PLLCSR  & PLL Control and Status Register \cr
RXOUTI  & Received OUT Interrupt \cr
RXSTPI  & Received SETUP Interrupt \cr
\noalign{\medskip}
UDIEN   & USB Device Interrupt Enable \cr
UDINT   & USB Device Interrupt \cr
\noalign{\medskip}
UECFG1X & USB Endpoint-X Configuration 1 \cr
UEDATX  & USB Endpoint-X Data \cr
\noalign{\medskip}
UEIENX  & USB Endpoint-X Interrupt Enable \cr
UEINTX  & USB Endpoint-X Interrupt \cr
\noalign{\medskip}
UENUM   & USB endpoint number \cr
USBCON  & USB Control \cr
USBINT  & USB General Interrupt \cr
%
\noalign{\kern10pt}}

@<Header files@>=
#include <avr/boot.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include "hint.h"
