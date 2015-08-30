CON

  _clkmode = XTAL1 + PLL8X
  _xinfreq = 10_000_000

OBJ

  nRF: "nRF24L01"

PUB Main | c

  waitcnt(clkfreq*3+cnt)        'Wait for 100ms to allow for Receiver to start up.

  nRF.init(3, 4, 6, 7, 8, 9)

  nRF.setTransmitter
  nRF.setPowered(true)

  repeat
    if INA[9] == 0
      nRF.writeRegister(nRF#REG_STATUS, %0010_0000)

    c++

    nRF.txByte(c)

    if c > 254
      c := 0

    waitcnt(clkfreq/5+cnt)

