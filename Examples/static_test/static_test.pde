#include <TinyGPS.h>
#include <avr\pgmspace.h>

/* This sample code demonstrates the basic use of a TinyGPS object.
   Typically, you would feed it characters from a serial GPS device, but 
   this example uses static strings for simplicity.
   
*/

prog_char str1[] PROGMEM = "$PUBX,00,081350.00,4717.113210,N,00833.915187,E,546.589,G3,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,9,0,0*5F";
//prog_char str2[] PROGMEM = "$PUBX,00,081351.00,4717.213210,N,00833.915187,E,536.589,G3,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,8,0,0*5B";
prog_char str2[] PROGMEM = "$PUBX,00,000327.00,0000.00000,N,00000.00000,E,0.000,NF,5303307,3750003,0.000,0.00,0.000,,99.99,99.99,99.99,0,0,0*29";
prog_char str3[] PROGMEM = "$PUBX,00,081352.00,4717.313210,N,00833.915187,E,526.589,G3,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,7,0,0*57";
prog_char str4[] PROGMEM = "$PUBX,00,081353.00,4717.413210,N,00833.915187,E,516.589,G3,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,6,0,0*53";
prog_char str5[] PROGMEM = "$PUBX,00,081354.00,4717.513210,N,00833.915187,E,506.589,NF,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,5,0,0*2B";
prog_char str6[] PROGMEM = "$PUBX,00,081355.23,4717.533210,S,00833.915187,W,500.589,NF,2.1,2.0,0.007,77.52,0.007,,0.92,1.19,0.77,4,0,0*21";

prog_char *teststrs[6] = {str1, str2, str3, str4, str5, str6};

static void sendstring(TinyGPS &gps, const PROGMEM char *str);
static void gpsdump(TinyGPS &gps);
static void print_float(float val, float invalid, int len, int prec);
static void print_int(unsigned long val, unsigned long invalid, int len);
static void print_date(TinyGPS &gps);
static void print_str(const char *str, int len);

void setup()
{
  TinyGPS test_gps;
  Serial.begin(9600);
  
  Serial.print("Testing TinyGPS library v. "); Serial.println(TinyGPS::library_version());
  Serial.println("by Mikal Hart");
  Serial.println();
  Serial.print("Sizeof(gpsobject) = "); Serial.println(sizeof(TinyGPS));
  Serial.println();

  Serial.println("Sats HDOP Latitude Longitude Fix  Date       Time       Date Alt     Course Speed Card  Distance Course Card  Chars Sentences Checksum");
  Serial.println("          (deg)    (deg)     Age                        Age  (m)     --- from GPS ----  ---- to London  ----  RX    RX        Fail");
  Serial.println("--------------------------------------------------------------------------------------------------------------------------------------");
  gpsdump(test_gps);
  for (int i=0; i<6; ++i)
  {
    sendstring(test_gps, teststrs[i]);
    gpsdump(test_gps);
  }
}

void loop()
{
}

static void sendstring(TinyGPS &gps, const PROGMEM char *str)
{
  while (true)
  {
    char c = pgm_read_byte_near(str++);
    if (!c) break;
    gps.encode(c);
  }
  gps.encode('\r');
  gps.encode('\n');
}

static void gpsdump(TinyGPS &gps)
{
  float flat, flon;
  unsigned long age, date, time, chars = 0;
  unsigned short sentences = 0, failed = 0;
  static const float LONDON_LAT = 51.508131, LONDON_LON = -0.128002;
  
  print_int(gps.satellites(), TinyGPS::GPS_INVALID_SATELLITES, 5);
  print_int(gps.hdop(), TinyGPS::GPS_INVALID_HDOP, 5);
  gps.f_get_position(&flat, &flon, &age);
  print_float(flat, TinyGPS::GPS_INVALID_F_ANGLE, 9, 5);
  print_float(flon, TinyGPS::GPS_INVALID_F_ANGLE, 10, 5);
  print_int(age, TinyGPS::GPS_INVALID_AGE, 5);

  print_date(gps);

  print_float(gps.f_altitude(), TinyGPS::GPS_INVALID_F_ALTITUDE, 8, 2);
  print_float(gps.f_course(), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);
  print_float(gps.f_speed_kmph(), TinyGPS::GPS_INVALID_F_SPEED, 6, 2);
  print_str(gps.f_course() == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(gps.f_course()), 6);
  print_int(flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0UL : (unsigned long)TinyGPS::distance_between(flat, flon, LONDON_LAT, LONDON_LON) / 1000, 0xFFFFFFFF, 9);
  print_float(flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0.0 : TinyGPS::course_to(flat, flon, 51.508131, -0.128002), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);
  print_str(flat == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(TinyGPS::course_to(flat, flon, LONDON_LAT, LONDON_LON)), 6);

  gps.stats(&chars, &sentences, &failed);
  print_int(chars, 0xFFFFFFFF, 6);
  print_int(sentences, 0xFFFFFFFF, 10);
  print_int(failed, 0xFFFFFFFF, 9);
  Serial.println();
}

static void print_int(unsigned long val, unsigned long invalid, int len)
{
  char sz[32];
  if (val == invalid)
    strcpy(sz, "*******");
  else
    sprintf(sz, "%ld", val);
  sz[len] = 0;
  for (int i=strlen(sz); i<len; ++i)
    sz[i] = ' ';
  if (len > 0) 
    sz[len-1] = ' ';
  Serial.print(sz);
}

static void print_float(float val, float invalid, int len, int prec)
{
  char sz[32];
  if (val == invalid)
  {
    strcpy(sz, "*******");
    sz[len] = 0;
        if (len > 0) 
          sz[len-1] = ' ';
    for (int i=7; i<len; ++i)
        sz[i] = ' ';
    Serial.print(sz);
  }
  else
  {
    Serial.print(val, prec);
    int vi = abs((int)val);
    int flen = prec + (val < 0.0 ? 2 : 1);
    flen += vi >= 1000 ? 4 : vi >= 100 ? 3 : vi >= 10 ? 2 : 1;
    for (int i=flen; i<len; ++i)
      Serial.print(" ");
  }
}

static void print_date(TinyGPS &gps)
{
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned long age;
  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);
  if (age == TinyGPS::GPS_INVALID_AGE)
    Serial.print("*******    *******    ");
  else
  {
    char sz[32];
    sprintf(sz, "%02d/%02d/%02d %02d:%02d:%02d   ",
        month, day, year, hour, minute, second);
    Serial.print(sz);
  }
  print_int(age, TinyGPS::GPS_INVALID_AGE, 5);
}

static void print_str(const char *str, int len)
{
  int slen = strlen(str);
  for (int i=0; i<len; ++i)
    Serial.print(i<slen ? str[i] : ' ');
}
