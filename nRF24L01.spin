{
Name: nRF24L01+ Frontend/API
Date: 06/18/2015
Author: John Board
(c) 2015 John Board
}

CON

  {Command Set, see page 48 of the manual}
  R_REGISTER      = %0000_0000
  W_REGISTER      = %0010_0000
  R_RX_PAYLOAD    = %0110_0001
  W_TX_PAYLOAD    = %1010_0000
  FLUSH_TX        = %1110_0001
  FLUSH_RX        = %1110_0010
  REUSE_TX_PL     = %1110_0011
  R_RX_PL_WID     = %0110_0000
  W_ACK_PAYLOAD   = %1010_1000  'Last 3 bits are the pipe to write the ack to
  W_TX_PAYLOAD_NO_ACK = %1011_0000
  _NOP            = %1111_1111  'No Operation. Used to read status reg

  {
  Register addresses. To read or write OR (|) the command (R_REG, W_REG) with the register,
        write_register(R_REGISTER|REG_CONFIG, %0000_1010)

  All register constants start with REG_. Registers are 5 bits long.
  }
  REG_CONFIG      = %00000
  REG_EN_AA       = %00001
  REG_EN_RXADDR   = %00010
  REG_SETUP_AW    = %00011
  REG_SETUP_RETR  = %00100
  REG_RF_CH       = %00101
  REG_RF_SETUP    = %00110
  REG_STATUS      = %00111
  REG_OBSERVE_TX  = %01000
  REG_RPD         = %01001
  REG_RX_ADDR_P0  = %01010
  REG_RX_ADDR_P1  = %01011
  REG_RX_ADDR_P2  = %01100
  REG_RX_ADDR_P3  = %01101
  REG_RX_ADDR_P4  = %01110
  REG_RX_ADDR_P5  = %01111
  REG_TX_ADDR     = %10000
  REG_RX_P0       = %10001
  REG_RX_P1       = %10010
  REG_RX_P2       = %10011
  REG_RX_P3       = %10100
  REG_RX_P4       = %10101
  REG_RX_P5       = %10110
  REG_FIFO_STATUS = %10111
  REG_DYNPD       = %11100
  REG_FEATURE     = %11101

  {Common Bit Masks. Or'ed with other bits for data}
  MASK_RX_DR      = %0100_0000
  MASK_TX_DS      = %0010_0000
  MASK_MAX_RT     = %0001_0000
  EN_CRC          = %0000_1000
  CRCO            = %0000_0100
  PWR_UP          = %0000_0010
  PRIM_RX         = %0000_0001




  SPI_SHIFTOUT_MODE = 5
  SPI_SHIFTOUT_BITS = 8

  SPI_SHIFTIN_MODE = 0
  SPI_SHIFTIN_BITS = 8

VAR

  byte CE, CSN, SCK, MOSI, MISO, IRQ

OBJ

  SPI:  "SPI_Spin"

PUB init(_CE, _CSN, _SCK, _MOSI, _MISO, _IRQ)
{
Initializes the object. Parameters are the pins that the nRF24L01 is sitting on.

Typically it takes 100ms from power on for the nRF to respond to any commands.
Considering it takes the propeller ~2-3 seconds to boot, this wait is not accounted
for.

}

  CE := _CE
  CSN := _CSN
  SCK := _SCK
  MOSI := _MOSI
  MISO := _MISO
  IRQ := _IRQ

  {Set pin 'direction'}
  DIRA[CE..MOSI]~~
  DIRA[MISO..IRQ]~

  DIRA[23]~~                    'LED status indicating initialization of code. Only applicable for
  OUTA[23]~~                    'Demo board.

  {Set starting pin states}
  OUTA[CSN] := 1                'Default Chip Select state is 1
  OUTA[CE] := 0                 'Default Chip Enable state is 0

  SPI.start(8, 0)

  writeRegister(REG_CONFIG, EN_CRC|CRCO)

PUB txByte(data)

  writeCommand(W_TX_PAYLOAD, data)
  OUTA[CE]~~
  waitUS(30)
  OUTA[CE]~

PUB setPowered(power)
{
power: boolean. True for on, False for off.

A little speed is lost when turning off as it gets the current
register setting (which takes time), and ANDs it with the
new power mask.
}
  if power
    writeRegister(REG_CONFIG, readRegister(REG_CONFIG) | %10)
  else
    writeRegister(REG_CONFIG, readRegister(REG_CONFIG) & %10)

PUB setReceiver

  writeRegister(REG_CONFIG, readRegister(REG_CONFIG) | PRIM_RX)

PUB setTransmitter

  'do nothing. Don't needa flip no bits or nothing.

PUB flushTX

  writeByte(FLUSH_TX)

PUB writeCommand(command, data)

  OUTA[CSN]~                    'Transition CSN to low for start of command (section 8.3.1 of manual)
  waitUS(5)                     'Wait 5us (minimum wait time)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, command)        'SHIFTOUT register
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, data)           'SHIFTOUT data
  waitUS(5)                     'wait 5us
  OUTA[CSN]~~                   'Pull CSN high again, signifying end of shiftout

PUB writeRegister(_reg, data) | reg
{
Reg is the byte register to write to
The first 3 bits (001) of a write operation signifies that it's a write operation,
the next 5 bits are the register address, thus a valid write reg value would be:

  %001A_AAAA

Where A is a register address (5 bit)
Data is the byte data to write to said register
}
  reg := W_REGISTER | _reg
  writeCommand(reg, data)

PRI writeByte(data)

  OUTA[CSN]~
  waitUS(5)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, data)
  waitUS(5)
  OUTA[CSN]~~

PUB readRegister(_reg) | data, reg
{
Read registers are typically formed as such
  %000A_AAAA
Where A is the register address (5 bit)
}

  reg := _reg | R_REGISTER

  OUTA[CSN]~                    'Transition CSN to low for start of command (section 8.3.1 of manual)
  waitUS(5)
  SPI.SHIFTOUT(MOSI, SCK, SPI_SHIFTOUT_MODE, SPI_SHIFTOUT_BITS, reg)            'SHIFTOUT reg to read
  data := SPI.SHIFTIN(MISO, SCK, SPI_SHIFTIN_MODE, SPI_SHIFTIN_BITS)            'SHIFTIN to data
  waitUS(5)
  OUTA[CSN]~~

  return data

PRI waitUS(us)
{
Minimum wait time is 5us
}

  waitcnt((80*us-381 #> 381)+cnt)

