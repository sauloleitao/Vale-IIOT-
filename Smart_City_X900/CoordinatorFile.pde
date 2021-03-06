


#include <WaspXBeeDM.h>
#include <WaspFrame.h>

// SP parameter: Time to be asleep -> 5 seconds: 0x0001F4 (hex format, time in units of 10ms)
// Other possible values: 
//   0x0003E8 (10 seconds)
//   0x0000C8 (2 seconds)
//   0x0005DC (15 seconds)
//   0x001770 (60 seconds)
uint8_t asleep[3]={ 0x00,0x01,0xF4};

// ST parameter: Time to be awake -> 5 seconds: 0x001388 (hex format, time in units of 1ms)
// Other possible values: 
//   0x002710 (10 seconds)
//   0x0007D0 (2 seconds)
//   0x003A98 (15 seconds)
//   0x00EA60 (60 seconds)
uint8_t awake[3]={ 0x00,0x13,0x88};

// deifne variable to get running time
unsigned long startTime;


// PAN (Personal Area Network) Identifier
uint8_t  panID[2] = {0x7F,0xFF}; 

// Define Unicast
//////////////////////////////////////////
char RX_ADDRESS[] = "0013A20040794b68";

// define variable
uint8_t error;

// Define the Waspmote ID
char WASPMOTE_ID[] = "SCordinator";


void setup()
{
  // Init USB port
  USB.ON();
  USB.println(F("Cyclic sleep example"));

  // init RTC 
  RTC.ON();

  //////////////////////////
  // 1. XBee setup
  //////////////////////////

  // 1.1. init XBee
  xbeeDM.ON();
  
  // set Waspmote identifier
  frame.setID(WASPMOTE_ID);
  xbeeDM.setNodeIdentifier(WASPMOTE_ID);
  
  // 1.2. set time the module remains awake (ST parameter)
  xbeeDM.setAwakeTime(awake);
  
  // check AT command flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("ST parameter set ok"));
  }
  else 
  {
    USB.println(F("error setting ST parameter")); 
  }

  // 1.3. set Sleep period (SP parameter)
  xbeeDM.setSleepTime(asleep);
  
  // check AT command flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("SP parameter set ok"));
  }
  else 
  {
    USB.println(F("error setting SP parameter")); 
  }
  
    /////////////////////////////////////
  // 2. set PANID
  /////////////////////////////////////
  xbeeDM.setPAN( panID );
  // check the AT commmand execution flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbeeDM.PAN_ID[0] ); 
    USB.printHex( xbeeDM.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }


  // 1.4. set sleep mode for cyclic sleep mode
  xbeeDM.setSleepMode(8);  
  
   // 1.5 Mesh Network Retries (4.7 manual digimesh)
  xbeeDM.setMeshNetworkRetries(0x03); 
    
   /////////////////////////////////////
  // 5. write values to XBee module memory
  /////////////////////////////////////
  xbeeDM.writeValues();

  // check the AT commmand execution flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("5. Changes stored OK"));
  }
  else 
  {
    USB.println(F("5. Error calling 'writeValues()'"));   
  }

  USB.println(F("-------------------------------")); 

}


void loop()
{  
  ///////////////////////////////////////////////
  // 2. Waspmote sleeps while XBee sleeps
  ///////////////////////////////////////////////

  // Waspmote enters to sleep until XBee module wakes it up
  // It is important not to switch off the XBee module when
  // entering sleep mode calling PWR.sleep function
  // It is necessary to enable the XBee interrupt

  // get starting time
  startTime = RTC.getEpochTime();

  USB.println(F("Enter deep sleep..."));
  
  // 2.1. enables XBEE Interrupt
  enableInterrupts(XBEE_INT);

  // 2.2. Waspmote enters sleep mode
  PWR.sleep( SENS_OFF );


  ///////////////////////////////////////////////
  // 3. Waspmote wakes up and check intFlag
  ///////////////////////////////////////////////

  USB.println(F("...wake up!"));

  // init RTC 
  RTC.ON();
  
  USB.print(F("Sleeping time (seconds):"));
  USB.println( RTC.getEpochTime() - startTime );
 
  
  // After waking up check the XBee interrupt
  if( intFlag & XBEE_INT )
  {
    // blink the red LED
    Utils.blinkRedLED();

    USB.println(F("--------------------"));
    USB.println(F("XBee interruption captured!!"));
    USB.println(F("--------------------"));
    
    intFlag &= ~(XBEE_INT); // Clear flag
  }

  /* Application transmissions should be done here when XBee
   module is awake for the defined awake time. All operations
   must be done during this period before teh XBee modules enters
   a sleep period again*/

  // do nothing while XBee module remains awake before 
  // return to sleep agains after 'awake' seconds
  
  ///////////////////////////////////////////
// 3. Create ASCII frame or Create Binnary frame
///////////////////////////////////////////  


///////////////////////////////////////////
// Create ASCII frame
/////////////////////////////////////////// 
// Create new frame
    USB.println(F("Create a new Frame:"));
    frame.createFrame(ASCII);  
    
// Create frame fields
    frame.addSensor(SENSOR_STR, "Park 4");
    frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel()); 
  
///////////////////////////////////////////
// 4. Send packet
///////////////////////////////////////////  

// send XBee packet
    error = xbeeDM.send( RX_ADDRESS, frame.buffer, frame.length );   
  
// check TX flag
  if( error == 0 )
  {
    USB.println(F("send ok"));
    
// blink green LED
    Utils.blinkGreenLED();
    
  }
     else 
  {
     USB.println(F("send error"));
    
// blink red LED
     Utils.blinkRedLED();
  }
  
  
  delay(1000);
}

