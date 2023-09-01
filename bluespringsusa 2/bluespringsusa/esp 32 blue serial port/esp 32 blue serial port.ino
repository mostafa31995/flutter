#include "BluetoothSerial.h"  
#include "esp_bt_main.h"
#include "esp_bt_device.h"
 
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);  
  SerialBT.begin("BlueSpringBT");//Bluetooth device name 
  Serial.println("The device started, now you can pair it with bluetooth!");
}

String received_msg = "";
bool connected = false;
void loop() {
  if(!connected)
  {
    connected = SerialBT.connected(); 
    if(connected)
    {
      Serial.write("Connected to device\n");    
    }
  }
  else
  {
    connected = SerialBT.connected();
    if(!connected)
    {
      Serial.write("Connection lost\n");    
    }
  }
  
  if (Serial.available()) {
    // String data = String(Serial.read());
    // Serial.write("Me:--");
    // Serial.write(Serial.read());
    String teststr = Serial.readString();
    SerialBT.print(teststr);
  }
  if (SerialBT.available()) {
    // String data = String(SerialBT.read());
    // received_msg += data;
    char ch = SerialBT.read();    
    received_msg += ch;
    if(ch == 10)
    {
      Serial.print(received_msg);  
      if(received_msg.startsWith("BLUE_SSID:"))
      {
        delay(100);
        SerialBT.println("SSID_OK");
        Serial.println("SSID_OK");
      }
      if(received_msg.startsWith("BLUE_PASSWORD:"))
      {
        delay(100);
        SerialBT.println("PASS:OK");
        Serial.println("PASS:OK"); 
        delay(2000);
        SerialBT.print("SUCCESS:y8B7EKuusgGygRDH9R2W");
        // SerialBT.println(getAddress());
        
        Serial.print("SUCCESS:y8B7EKuusgGygRDH9R2W");
        // Serial.println(getAddress());
      }
      received_msg= "";    
    } 
  }
  // delay(20);
}
String getAddress() {
  String address = "";
  const uint8_t* point = esp_bt_dev_get_address();
 
  for (int i = 0; i < 6; i++) {
 
    char str[3];
 
    sprintf(str, "%02X", (int)point[i]);
    // Serial.print(str);
    address += str;
    if (i < 5){
      // Serial.print(":");
      address += ":";
    }
  }
  return address;
}