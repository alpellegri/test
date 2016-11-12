#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <FirebaseArduino.h>
#include <WiFiUdp.h>
#include <string.h>

#include "timesrv.h"

static const int timeZone = +1; // Time offset from GMT

static uint8_t timesrv_setup = 0;
static bool timesrv_run = false;
static uint8_t TimeServiceCnt;

static char isodate[25]; // The current time in ISO format is being stored here
static tmElements_t tm;

char *getUTC(void) { return isodate; }

/*-------- NTP code ----------*/

// NTP Servers:
static const char ntpServerName[] = "us.pool.ntp.org";
// static const char ntpServerName[] = "time.nist.gov";
// static const char ntpServerName[] = "time-a.timefreq.bldrdoc.gov";
// static const char ntpServerName[] = "time-b.timefreq.bldrdoc.gov";
// static const char ntpServerName[] = "time-c.timefreq.bldrdoc.gov";

// local port to listen for UDP packets
uint16_t localPort = 8888;

// NTP time stamp is in the first 48 bytes of the message
const uint16_t NTP_PACKET_SIZE = 48;

byte packetBuffer[NTP_PACKET_SIZE]; // buffer to hold incoming
// and outgoing packets
// A UDP instance to let us send and receive packets over UDP

WiFiUDP Udp;

#define LEAP_YEAR(_year)                                                       \
  (((((1970 + _year) % 4) == 0) && ((1970 + year) % 100 != 0)) ||              \
   ((1970 + _year) % 400 == 0))

static const uint8_t monthDays[] = {31, 28, 31, 30, 31, 30,
                                    31, 31, 30, 31, 30, 31};

// break the given time_t into time components
// this is a more compact version of the C library localtime function
// note that year is offset from 1970 !!!
void breakTime(time_t time, tmElements_t &tm) {

  uint8_t year;
  uint8_t month, monthLength;
  unsigned long days;

  tm.Second = time % 60;
  time /= 60; // now it is minutes
  tm.Minute = time % 60;
  time /= 60; // now it is hours
  tm.Hour = time % 24;
  time /= 24;                     // now it is days
  tm.Wday = ((time + 4) % 7) + 1; // Sunday is day 1

  year = 0;
  days = 0;
  while ((unsigned)(days += (LEAP_YEAR(year) ? 366 : 365)) <= time) {
    year++;
  }
  tm.Year = year; // year is offset from 1970
  tm.Year += 1970;

  days -= LEAP_YEAR(year) ? 366 : 365;
  time -= days; // now it is days in this year, starting at 0

  days = 0;
  month = 0;
  monthLength = 0;
  for (month = 0; month < 12; month++) {
    if (month == 1) { // february
      if (LEAP_YEAR(year)) {
        monthLength = 29;
      } else {
        monthLength = 28;
      }
    } else {
      monthLength = monthDays[month];
    }

    if (time >= monthLength) {
      time -= monthLength;
    } else {
      break;
    }
  }
  tm.Month = month + 1; // jan is month 1
  tm.Day = time + 1;    // day of month

  sprintf(isodate, "%d-%02d-%02dT%02d:%02d:%02d", tm.Year, tm.Month, tm.Day,
          tm.Hour, tm.Minute, tm.Second);
  // Serial.printf("isodate: %s\n", isodate);
}

// send an NTP request to the time server at the given address
void sendNTPpacket(IPAddress &address) {
  // set all bytes in the buffer to 0
  memset(packetBuffer, 0, NTP_PACKET_SIZE);
  // Initialize values needed to form NTP request
  // (see URL above for details on the packets)
  packetBuffer[0] = 0b11100011; // LI, Version, Mode
  packetBuffer[1] = 0;          // Stratum, or type of clock
  packetBuffer[2] = 6;          // Polling Interval
  packetBuffer[3] = 0xEC;       // Peer Clock Precision
  // 8 bytes of zero for Root Delay & Root Dispersion
  packetBuffer[12] = 49;
  packetBuffer[13] = 0x4E;
  packetBuffer[14] = 49;
  packetBuffer[15] = 52;
  // all NTP fields have been given values, now
  // you can send a packet requesting a timestamp:
  Udp.beginPacket(address, 123); // NTP requests are to port 123
  Udp.write(packetBuffer, NTP_PACKET_SIZE);
  Udp.endPacket();
}

time_t getNtpTime(void) {
  IPAddress ntpServerIP; // NTP server's ip address

  while (Udp.parsePacket() > 0)
    ; // discard any previously received packets

  // get a random server from the pool
  WiFi.hostByName(ntpServerName, ntpServerIP);
  sendNTPpacket(ntpServerIP);
  uint32_t beginWait = millis();
  while (millis() - beginWait < 1500) {
    int size = Udp.parsePacket();
    if (size >= NTP_PACKET_SIZE) {
      Udp.read(packetBuffer, NTP_PACKET_SIZE); // read packet into the buffer
      unsigned long secsSince1900;
      // convert four bytes starting at location 40 to a long integer
      secsSince1900 = (unsigned long)packetBuffer[40] << 24;
      secsSince1900 |= (unsigned long)packetBuffer[41] << 16;
      secsSince1900 |= (unsigned long)packetBuffer[42] << 8;
      secsSince1900 |= (unsigned long)packetBuffer[43];
      return secsSince1900 - 2208988800UL + timeZone * 3600L;
    }
  }
  return 0; // return 0 if unable to get the time
}

bool TimeService(void) {
  if (timesrv_setup == 0) {
    timesrv_setup = 1;
    timesrv_run = false;
    Udp.begin(localPort);
    Serial.println("init done");
  } else {
    if (TimeServiceCnt < 5) {
      TimeServiceCnt++;
    } else {
      Serial.println("getNtpTime");
      time_t mytime = getNtpTime();
      if (mytime != 0) {
        timesrv_run = true;
        TimeServiceCnt = 0;
        breakTime(mytime, tm);
      }
    }
  }

  return timesrv_run;
}