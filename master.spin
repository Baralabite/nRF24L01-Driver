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

  SPI: "SPI_Spin"
  
PUB Main | counter, c

  waitcnt(clkfreq*2+cnt)

  {Set INPUTs/OUTPUTs}
  DIRA[CE..MOSI]~~
  DIRA[5]~
  DIRA[MISO..IRQ]~

  {Set starting pin states}
  OUTA[CSN]~~
  OUTA[CE]~
  DIRA[20..23]~~

  SPI.start(10, 0)

  write_register(%0010_0100, %0001_1010)
  wait(1)
  write_register(%0010_0000, $0e)

  wait(1)
  write_byte($01)
  wait(1)
  write_byte($02)
  wait(1)
  write_byte($03)
  wait(1)
  write_byte($04)

  repeat
                          
  {repeat
    counter++

    write_register(%1010_0000, counter)
    wait(1)

    if counter > 254
      counter := 0

    if INA[5] == 0
      write_register(%0010_0111, %0010_1110)
      wait(1)

    !OUTA[23]

    waitcnt(clkfreq/100+cnt)}
  
  
  
PUB write_byte(data)

  write_register($A0, data)
  OUTA[CE]~~
  waitcnt(1443+cnt) '30us
  OUTA[CE]~

PUB write_register(reg, data)

  OUTA[CSN]~                    'Transition CSN to low for start of command (section 8.3.1 of manual)  
  wait(1)                       'Wait 1ms for good measure
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, reg)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, data)
  wait(1)
  OUTA[CSN]~~

PUB write(data)

  OUTA[CSN]~
  wait(1)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, data)
  wait(1)
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
  
