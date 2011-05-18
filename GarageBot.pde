// EtherShield webserver demo
#include <EtherShield.h>
#include <stdlib.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#define ONE_WIRE_BUS 8  // Data wire is plugged into pin 8 on the Arduino
OneWire oneWire(ONE_WIRE_BUS);  // Setup a oneWire instance to communicate with any OneWire devices 
DallasTemperature sensors(&oneWire); // Pass our oneWire reference to Dallas Temperature.

int doorPin = 7;   // pushbutton connected to digital pin 7
int doorTrigger = 5; // this will be tied to the relay, activate it to open / close
// please modify the following two lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static uint8_t mymac[6] = {
  0x54,0x55,0x58,0x10,0x00,0x25}; 
  
static uint8_t myip[4] = {
  192,168,230,20};

#define MYWWWPORT 80
#define BUFFER_SIZE 550
static uint8_t buf[BUFFER_SIZE+1];

// The ethernet shield
EtherShield es=EtherShield();

uint16_t http200ok(void)
{
  return(es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nPragma: no-cache\r\n\r\n")));
}

// prepare the webpage by writing the data to the tcp send buffer
uint16_t print_webpage(uint8_t *buf)
{
  String Output1;
  String buffer;
  int doorOpen = 0;
  float garageTempf = 0.0; 
  char garageTempc[7];
  int i=0;
  uint16_t plen;
  plen=http200ok();
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<html><head><title>Jim's Garage V1.0</title></head><body>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<center><h1>Welcome to Jim's Garage Ethernet Shield V1.0</h1>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<hr><br><h2><font color=\"red\">"));
  // Varible Data Here 
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("The Light is : ") );
  if (analogRead(0) > 500) 
  {
    // The light is on!
    Output1 = "ON";
    Serial.print("The Light is ON - ");
    Serial.println(analogRead(0));
  }
  else
  {
    // The light is off!
    Output1 = "OFF";
    Serial.print("The Light is OFF - ");
    Serial.println(analogRead(0));
  }



//SensorData = itoa(analogRead(0), Output1, 10);
  while (Output1[i]) {
                buf[TCP_CHECKSUM_L_P+3+plen]=Output1[i++];
                plen++;
        }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br>The Door is: ") );
  doorOpen = digitalRead(doorPin);
  if (doorOpen)
  { // The door is open because the switch it pushed
    Output1 = "OPEN!";
    Serial.println("the door is open");
    Serial.println(doorOpen);
  }
  else
  {
    Output1 = "CLOSED";
    Serial.println("the door is closed");
    Serial.println(doorOpen);
  }
  i=0;
   while (Output1[i]) {
                buf[TCP_CHECKSUM_L_P+3+plen]=Output1[i++];
                plen++;
        }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br>The Temp is: ") );
  sensors.requestTemperatures(); // Send the command to get temperatures
  garageTempf = DallasTemperature::toFahrenheit(sensors.getTempCByIndex(0));
  dtostrf(garageTempf, 3, 2, garageTempc);
  Serial.println(garageTempf); 
   i=0;
   while (garageTempc[i]) {
                buf[TCP_CHECKSUM_L_P+3+plen]=garageTempc[i++];
                plen++;
        }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br></font></h2>") );
  // end of variable data
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<a href=\"http://192.168.230.20/operate\">Open/Close The Garage</a>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<hr><br>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</center>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("V1.0 <a href=\"http://www.stuffjimmakes.com\">www.stuffjimmakes.com</a>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</body></html>"));

  return(plen);
}
/////////////////////////////////////////////////////////////////////
uint16_t print_opening_webpage(uint8_t *buf)
{
  digitalWrite(doorTrigger, HIGH);
  delay(250);
  digitalWrite(doorTrigger, LOW);
  uint16_t plen;
  plen=http200ok();
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<html><head><title>Jim's Garage V1.0</title><meta http-equiv=\"REFRESH\" content=\"15;url=http://192.168.230.20\"></head><body>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<center><h1>Welcome to Jim's Garage Ethernet Shield V1.0</h1>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<hr><br><h2><font color=\"red\">"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("The door is MOVING!") );
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br></font></h2>") );
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<hr><br>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</center>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("V1.0 <a href=\"http://www.stuffjimmakes.com\">www.stuffjimmakes.com</a>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</body></html>"));
  return(plen);
}
/////////////////////////////////////////////////////////////////////

void setup(){
  Serial.begin(9600);
  // initialize enc28j60
  es.ES_enc28j60Init(mymac);

  // init the ethernet/ip layer:
  es.ES_init_ip_arp_udp_tcp(mymac,myip, MYWWWPORT);
  
  pinMode(doorPin, INPUT);      // sets the digital pin 7 as input
  pinMode(doorTrigger, OUTPUT); // Sets digital pin 5 as my relay trigger output
  
  sensors.begin();      // Start up the library
}

void loop(){
  
  uint16_t plen, dat_p;

  while(1) {
    // read packet, handle ping and wait for a tcp packet:
    dat_p=es.ES_packetloop_icmp_tcp(buf,es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));

    /* dat_p will be unequal to zero if there is a valid 
     * http get */
    if(dat_p==0){
      // no http request
      continue;
    }
    // tcp port 80 begin
    if (strncmp("GET ",(char *)&(buf[dat_p]),4)!=0){
      // head, post and other methods:
      dat_p=http200ok();
      dat_p=es.ES_fill_tcp_data_p(buf,dat_p,PSTR("<h1>200 OK</h1>"));
      goto SENDTCP;
    }
    // just one web page in the "root directory" of the web server
    if (strncmp("/ ",(char *)&(buf[dat_p+4]),2)==0){
      dat_p=print_webpage(buf);
      goto SENDTCP;
    }
    // This is if we want to trigger the door to open / close
    if (strncmp("/operate ",(char *)&(buf[dat_p+4]),2)==0){
      dat_p=print_opening_webpage(buf);
      goto SENDTCP;
    }
    else{
      dat_p=es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 401 Unauthorized\r\nContent-Type: text/html\r\n\r\n<h1>401 Unauthorized</h1>"));
      goto SENDTCP;
    }
SENDTCP:
    es.ES_www_server_reply(buf,dat_p); // send web page data
    // tcp port 80 end

  }

}


