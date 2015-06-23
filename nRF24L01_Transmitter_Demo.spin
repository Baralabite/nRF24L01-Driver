CON

  _clkmode = XTAL1 + PLL16X
  _xinfreq = 5_000_000

OBJ

  nRF: "nRF24L01"

PUB Main | c

  waitcnt(clkfreq*2+cnt)        'Wait for 100ms to allow for Receiver to start up.

  nRF.init(0, 1, 2, 3, 4, 5)

  nRF.setTransmitter
  nRF.setPowered(true)

  nRF.txByte(1)
  nRF.txByte(2)
  nRF.txByte(4)
  nRF.txByte(5)
  nRF.txByte(6)

  repeat

  {repeat
    c++

    nRF.txByte(c)

    if c > 254
      c := 0

    waitcnt(clkfreq/10+cnt)}

