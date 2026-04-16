  
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
  
   I2C1_Base : constant := 16#4000_5400#;
   I2C2_Base : constant := 16#4000_5800#;
   I2C3_Base : constant := 16#4000_5C00#; 
   USART1_Base : constant := 16#40011000#;
   USART2_Base : constant := 16#40004400#;
   USART3_Base : constant := 16#40004800#;
   UART4_Base  : constant := 16#40004C00#;
   UART5_Base : constant := 16#40005000#;
   USART6_Base : constant := 16#40011400#;
   I2C_OAR1 : constant := 16#08#;
   I2C_OAR2  : constant := 16#0C#;
   I2C_DR   : constant := 16#10#;--8bits los otros 8 reservados
   --Nuevo
   
  
   GPIO_MODER_Offset:constant:=16#00#;
   GPIO_AFRL_Offset:constant:=16#20#;
   GPIO_AFRH_Offset:constant:=16#24#;
   GPIO_OTYPER_Offset:constant:=16#04#;
   GPIO_OSPEEDR_Offset:constant:=16#08#;
   GPIO_PUPDR_Offset:constant:=16#0C#;
   GPIO_ODR_Offset:constant:=16#14#;


   AHB1ENR_A: constant := 16#30#;
      OTGHSULPIEN:constant:=30;
      OTGHSEN:constant:=29;
      DMA2EN:constant:=22;
      DMA1EN:constant:=21;
      BKPSRAMEN:constant:=18;
      CRCEN:constant:=12;
      GPIOHEN:constant:=7;
      GPIOGEN:constant:=6;
      GPIOFEN:constant:=5;
      GPIOEEN:constant:=4;
      GPIODEN:constant:=3;
      GPIOCEN:constant:=2;
      GPIOBEN:constant:=1;
      GPIOAEN:constant:=0;

   APB1ENR_A: constant := 16#40#;
      DACEN:constant:=29;
      PWREN:constant:=28;
      CECEN:constant:=27;
      CAN2EN:constant:=26;
      CAN1EN:constant:=25;
      FMPI2C1EN:constant:=24;
      I2C3EN:constant:=23;
      I2C2EN :constant:=22;
      I2C1EN :constant:=21;
      USART5EN:constant:=20;
      USART4EN:constant:=19;
      USART3EN :constant:=18;
      USART2EN :constant:=17;
      SPDIFRXEN:constant:=16;
      SPI3EN:constant:=15;
      SPI2EN:constant:=14;
      WWDEGEN:constant:=11;
      TIM14EN:constant:=8;
      TIM13EN:constant:=7;
      TIM12EN:constant:=6;
      TIM7EN:constant:=5;
      TIM6EN:constant:=4;
      TIM5EN:constant:=3;
      TIM4EN:constant:=2;
      TIM3EN:constant:=1;
      TIM2EN:constant:=0;

   APB2ENR_A :constant := 16#44#;
      TIM1EN:constant:=0;
      TIM8EN:constant:=1;
      USART1EN:constant:=4;
      USART6EN:constant:=5;
      ADC1EN:constant:=8;
      ADC2EN:constant:=9;
      ADC3EN:constant:=10;
      SDIOEN:constant:=11;
      SPI1EN:constant:=12;
      SPI4EN:constant:=13;
      SYSCFGEN:constant:=14;
      TIM9EN:constant:=16;
      TIM10EN:constant:=17;
      TIM11EN:constant:=18;
      SAI2EN:constant:=22;
      SAI1EN:constant:=23;

   -- Desplazamiento USART2
 
   USART_DR_Offset  : constant := 16#04#;  -- Registro de datos
   USART_BRR_Offset : constant := 16#08#;  -- Baudrate
   
   USART_CR2_Offset : constant := 16#10#;  -- Control 2 , configuración avanzada
   USART_CR3_Offset : constant := 16#14#;  -- Control 3 , funciones especiales , dma , control de flujo , errores de transmisión
   USART_CR1_Offset : constant := 16#0C#;  -- Control 1
      CR1_UE     : constant := 13;  -- USART enable
      CR1_M      : constant := 12;
      CR1_WAKE   : constant :=11;
      CR1_PCE    : constant :=10;
      CR1_PS     : constant := 9;
      CR1_PEIE   : constant := 8;
      CR1_TXEIE  : constant := 7;
      CR1_TCIE   : constant := 6;
      CR1_RXNEIE : constant := 5;
      CR1_IDLEIE : constant := 4;
      CR1_TE     : constant := 3;   --  habilitar transmisión
      CR1_RE     : constant := 2;   -- habilitar recepcion
      CR1_RWU    : constant := 1;
      CR1_SBK    : constant := 0;
   
   -- Bits de SR
  USART_SR_Offset  : constant := 16#00#;  -- Status 
   SR_CTS     : constant := 9;
   SR_LBD     : constant := 8;
   SR_TXE     : constant := 7;   -- Registro de transmisión vacio
   SR_TC      : constant := 6;   -- Transmisión completa
   SR_RXNE    : constant := 5;   -- Datos de registro no vacio
   SR_IDLE    : constant := 4;
   SR_ORE     : constant := 3;
   SR_NF      : constant := 2;
   SR_FE      : constant := 1;
   SR_PE      : constant := 0;


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