\datethis
\input epsf

\font\caps=cmcsc10 at 9pt

\secpagedepth=2

@* Program.

@c
@<Header files@>@;
@<Type definitions@>@;
@<Global variables@>@;
@<Create ISR...@>@;

void main(void)
{
  DDRD |= _BV(PD5);
  @<Read all data@>@;
  PORTD |= _BV(PD5);
  @#
  U8 trigger = 0;
  PORTB |= _BV(PB4) | _BV(PB5) | _BV(PB6);
  _delay_us(1); // TODO: see HID file
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
    if (UEINTX & _BV(TXINI))
      @<Process IN packet@>@;
    if (!trigger && (PORTB & _BV(PB4))) {
      _delay_ms(1000);
      trigger = 1;
      datap = data1;
    }
    if (!trigger && (PORTB & _BV(PB5))) {
      _delay_ms(1000);
      trigger = 1;
      datap = data2;
    }
    if (!trigger && (PORTB & _BV(PB6))) {
      _delay_ms(1000);
      trigger = 1;
      datap = data3;
    }
  }
}

@ @<Type definitions@>=
typedef unsigned char U8;
typedef unsigned short U16;

@ @<Process IN packet@>= {
  if (trigger) {
    UEINTX &= ~_BV(TXINI);
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0x04; // *datap
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEINTX &= ~_BV(FIFOCON);
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
    @#
    UDR1 = *datap; while (!(UCSR1A & _BV(UDRE1))) { }
    datap++;
    if (*datap == 0) {
      trigger = 0;
      UDR1 = '\r'; while (!(UCSR1A & _BV(UDRE1))) { }
      UDR1 = '\n'; while (!(UCSR1A & _BV(UDRE1))) { }
    }
  }
}

@ @<Global...@>=
char d, data1[50], data2[50], data3[50], *datap;

@ @<Read all data@>=
UBRR1 = 34; // table 18-12 in datasheet
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
datap = data1;
@<Read data@>@;
datap = data2;
@<Read data@>@;
datap = data3;
@<Read data@>@;

@ @<Read data@>=
while (1) {
  while (!(UCSR1A & _BV(RXC1))) { }
  d = UDR1;
  if (d == '\n') {
    UDR1 = '\r'; while (!(UCSR1A & _BV(UDRE1))) { }
    UDR1 = '\n'; while (!(UCSR1A & _BV(UDRE1))) { }
    break;
  }
  UDR1 = d; while (!(UCSR1A & _BV(UDRE1))) { }
  *datap++ = d;
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
while (size) {
  while (!(UEINTX & _BV(TXINI))) { }
  for (U8 c = EP0_SIZE; c && size; c--) UEDATX = pgm_read_byte(buf++), size--;
  UEINTX &= ~_BV(TXINI);
}
if ((wLength > sizeof conf_desc ? sizeof conf_desc : wLength) % EP0_SIZE == 0) { /* USB\S5.5.3 */
  while (!(UEINTX & _BV(TXINI))) { }
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

@d CTRL_IFACE_NUM 0

@<Initialize Interface descriptor@>=
SIZEOF_THIS, @/
4, /* INTERFACE */
CTRL_IFACE_NUM, @/
0, /* no alternate settings */
1, /* one endpoint */
0x03, @/
0x00, @/
0x00, /* no protocol */
0 /* no string */

@*3 HID descriptor.

@<Initialize HID descriptor@>=
SIZEOF_THIS,
0x21, /* HID */
0x0111, /* HID 1.11 */
0x00, /* no localization */
0x01, /* one descriptor for this device */
0x22, /* HID report (value for |bDescriptorType| in {\caps get descriptor hid}) */
sizeof hid_rprt_desc

@*4 EP2 descriptor.

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
