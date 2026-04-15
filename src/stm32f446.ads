  
package stm32f446 is

   type Uint8 is mod 2**8; --para adb
   type Uint16 is mod 2**16;
   type Uint32 is mod 2**32; 
   type Uint8_Array is array (Positive range <>) of Uint8;
  
  -- Direcciones base
   RCC   : constant := 16#4002_3800#; -- Direccion del Reset  y  Clock control para que llegue alimentacion, por defecto siempre apagado
   GPIOA : constant := 16#4002_0000#;
   GPIOB : constant := 16#4002_0400#;
   GPIOC : constant := 16#4002_0800#;
   GPIOD : constant := 16#4002_0C00#;
   GPIOE : constant := 16#4002_1000#;
   GPIOF : constant := 16#4002_1400#;
   GPIOG : constant := 16#4002_1800#;
   GPIOH : constant := 16#4002_1C00#;
   USART2_Base : constant := 16#4000_4400#;  -- USART2 donde están todos los registros 
   I2C1_Base : constant := 16#4000_5400#;
   I2C2_Base : constant := 16#4000_5800#;
   I2C3_Base : constant := 16#4000_5C00#; 
   I2C_OAR1 : constant := 16#08#;
   I2C_OAR2  : constant := 16#0C#;
   I2C_DR   : constant := 16#10#;--8bits los otros 8 reservados
  

   -- Desplazamiento USART2
   USART_SR_Offset  : constant := 16#00#;  -- Status 
   USART_DR_Offset  : constant := 16#04#;  -- Registro de datos
   USART_BRR_Offset : constant := 16#08#;  -- Baudrate
   USART_CR1_Offset : constant := 16#0C#;  -- Control 1
   USART_CR2_Offset : constant := 16#10#;  -- Control 2 , configuración avanzada
   USART_CR3_Offset : constant := 16#14#;  -- Control 3 , funciones especiales , dma , control de flujo , errores de transmisión
   
   -- Bits de CR1
   CR1_UE     : constant := 13;  -- USART enable
   CR1_TE     : constant := 3;   --  habilitar transmisión
   CR1_RE     : constant := 2;   -- habilitar recepcion
   
   -- Bits de SR
   SR_TXE     : constant := 7;   -- Registro de transmisión vacio
   SR_TC      : constant := 6;   -- Transmisión completa
   SR_RXNE    : constant := 5;   -- Datos de registro no vacio


   --Offsets de registros I2C
      I2C_CR1   : constant := 16#00#;  -- Control Register 1
      I2C_CR1_PE       : constant := 0;   -- Peripheral enable 0:disable 1:enable 
      I2C_CR1_SMBUS    : constant := 1;   -- SMBus mode  0:i2c 1:smbus 
      --Bit 2 reserved
      I2C_CR1_SMBTYPE  : constant := 3;   -- SMBus type 0:host device 1:smbus mode
      I2C_CR1_ENARP    : constant := 4;   -- ARP enable 0:arp disable 1:arp ena
      I2C_CR1_ENPEC    : constant := 5;   -- PEC enable 0: disa 1:ena
      I2C_CR1_ENGC     : constant := 6;   -- General call enable  0: : General call disabled. Address 00h is NACKed  1:General call enabled. Address 00h is ACKed.
      I2C_CR1_NOSTRETCH: constant := 7;   -- Clock stretching disable  0: enable  1 : disable
      I2C_CR1_START    : constant := 8;   -- Start generation    In controller mode:     0: No Start generation  |  1: Repeated start generation  &  In target mode: 0: No Start generation | 1: Start generation when the bus is free
      I2C_CR1_STOP     : constant := 9;   -- Stop generation   In controller mode: 0: No Stop generation. |1: Stop generation after the current byte transfer or after the current Start condition is sent. & In target mode: 0: No Stop generation. |1: Release the SCL and SDA lines after the current byte transfer
      I2C_CR1_ACK      : constant := 10;  -- Acknowledge enable   0: No acknowledge returned   1: Acknowledge returned after a byte is received
      I2C_CR1_POS      : constant := 11;  -- Acknowledge/PEC position 0: ACK bit controls the (N)ACK of the current byte being received in the shift register. The PEC bit indicates that current byte in shift register is a PEC.  1: ACK bit controls the (N)ACK of the next byte which is received in the shift register. The PEC bit indicates that the next byte in the shift register is a PEC
      I2C_CR1_PEC      : constant := 12;  -- Packet error checking 0: No PEC transfer  1: PEC transfer (in Tx or Rx mode)
      I2C_CR1_ALERT    : constant := 13;  -- SMBus alert 0: Releases SMBA pin high. Alert Response Address Header followed by NACK.   | 1: Drives SMBA pin low. Alert Response Address Header followed by ACK.
      --Bit 14 reserved
      I2C_CR1_SWRST    : constant := 15;  -- Software reset 0: I2C Peripheral not under reset | 1: I2C Peripheral under reset state


   I2C_CR2   : constant := 16#04#;  -- Control Register 2
      I2C_CR2_FREQ       : constant := 0;   -- Bits 5:0 Peripheral clock frequency
      -- bit 6 reserved
      -- bit 7 reserved
      I2C_CR2_ITERREN    : constant := 8;   -- Error interrupt enable
      I2C_CR2_ITEVTEN    : constant := 9;   -- Event interrupt enable
      I2C_CR2_ITBUFEN    : constant := 10;  -- Buffer interrupt enable
      I2C_CR2_DMAEN      : constant := 11;  -- DMA requests enable
      I2C_CR2_LAST       : constant := 12;  -- DMA last transfer
     
      --Bit    15:13  reserved


   I2C_SR1  : constant := 16#14#;      
      I2C_SR1_SB       : constant := 0;
      I2C_SR1_ADDR     : constant := 1;
      I2C_SR1_BTF      : constant := 2;
      I2C_SR1_ADD10    : constant := 3;
      I2C_SR1_STOPF    : constant := 4;
      -- bit 5 reserved
      I2C_SR1_RxNE     : constant := 6;
      I2C_SR1_TxE      : constant := 7;
      I2C_SR1_BERR     : constant := 8;
      I2C_SR1_ARLO     : constant := 9;
      I2C_SR1_AF       : constant := 10;
      I2C_SR1_OVR      : constant := 11;
      I2C_SR1_PECERR   : constant := 12;
      -- bit 13 reserved
      I2C_SR1_TIMEOUT  : constant := 14;
      I2C_SR1_SMBALERT : constant := 15;

   I2C_SR2   : constant := 16#18#;
      I2C_SR2_MSL      : constant := 0;
      I2C_SR2_BUSY     : constant := 1;
      I2C_SR2_TRA      : constant := 2;
      -- bit 3 reserved
      I2C_SR2_GENCALL  : constant := 4;
      I2C_SR2_SMBDEFAULT : constant := 5;
      I2C_SR2_SMBHOST    : constant := 6;
      I2C_SR2_DUALF      : constant := 7;
      -- bits 15:8 PEC



   I2C_CCR : constant := 16#1C#;
      I2C_CCR_CCR  : constant := 0;   -- bits 11:0
      -- bits 13:12 reserved
      I2C_CCR_DUTY : constant := 14;  -- fast mode duty cycle
      I2C_CCR_FS   : constant := 15;  -- 0: standard 100kHz | 1: fast 400kHz



   I2C_TRISE : constant := 16#20#;
      I2C_TRISE_TRISE : constant := 0;-- 0:5
      --reservado hasta 15 

   PCLK1_MHz : constant := 42;
   I2C_AF : constant :=4;
   I2C_SPEED  : constant  := 100_000;

   end stm32f446;