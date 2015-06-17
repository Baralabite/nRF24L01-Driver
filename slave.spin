CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  CE    = 0
  CSN   = 1
  SCK   = 2
  MOSI  = 3
  MISO  = 4
  IRQ   = 5

  SPI_SHIFTOUT_MODE = 5
  SPI_SHIFTOUT_BITS = 8

  SPI_SHIFTIN_MODE = 0
  SPI_SHIFTIN_BITS = 8 

OBJ

  Serial: "FullDuplexSerial"
  SPI: "SPI_Spin"
  
PUB Main | counter

  {Set INPUTs/OUTPUTs}
  DIRA[CE..MOSI]~~               
  DIRA[MISO..IRQ]~

  {Set starting pin states}
  OUTA[CSN]~~
  OUTA[CE]~

  SPI.start(100, 0)
  Serial.start(31, 30, 0, 115200)
  waitcnt(clkfreq*2+cnt)
  Serial.str(String(16, "Start Reciving...", 13))
  
  wait(1)

  write_register(%0010_0000, %0111_1011)      'All IRQ masks on, 1 bit CRC, CRC enabled, PWR on, TX mode activated.

  wait(2)


  DIRA[CE]~~
  OUTA[CE]~~
  wait(2)
                          
  repeat
    counter := read_register(%0110_0001)

    Serial.bin(counter, 8)
    Serial.tx(13)

    waitcnt(clkfreq/10+cnt)     
  
  
  
  

PUB write_register(reg, data)

  OUTA[CSN]~                    'Transition CSN to low for start of command (section 8.3.1 of manual)  
  wait(1)                       'Wait 1ms for good measure

  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, reg)
  'wait(1)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, data)

  wait(2)
  OUTA[CSN]~~

PUB read_register(reg) | data

  OUTA[CSN]~                    'Transition CSN to low for start of command (section 8.3.1 of manual)  
  wait(1)                       'Wait 1ms for good measure

  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, reg)
  'wait(1)
  data := SPI.SHIFTIN(MISO, SCK, SPI_SHIFTIN_MODE, SPI_SHIFTIN_BITS)
  

  wait(1)
  OUTA[CSN]~~

  return data      

PUB wait(ms)

  waitcnt(((clkfreq/1000)*ms)+cnt)
  