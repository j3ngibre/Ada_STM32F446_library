with System;

package I2C is

   type Uint8 is mod 2**8;
   type Uint16 is mod 2**16;
   type Uint32 is mod 2**32;
   type Uint8_Array is array (Positive range <>) of Uint8;

   procedure Initialize;


   function I2C_WriteRead (SlaveAddr : Uint8;
                             Write_Data : Uint8;
                             Read_Data : out Uint8) return Boolean;

   function I2C_Write  (SlaveAddr : Uint8;
                        Data : Uint8) return Boolean;

   function I2C_Read (SlaveAddr : Uint8;
                       Data : out Uint8) return Boolean;


   function I2C_WriteBuffer (SlaveAddr : Uint8;
                               Buffer : Uint8_Array;
                               Len : Uint8) return Boolean;

   function I2C_ReadBuffer (SlaveAddr : Uint8;
                              Buffer : out Uint8_Array;
                              Len : Uint8) return Boolean;

function Wait_Bus return Boolean;
function Wait_Flag (Flag_Mask : Uint32; Timeout_MS : Positive) return Boolean;
procedure Clear_Errors;

private


   RCC  : constant := 16#4002_3800#;
   GPIOB : constant := 16#4002_0400#;  --GPIOB para/PB9 PB8/PB9
   I2C_base  : constant := 16#4000_5400#;  -- I2C1

   --Offsets de registros I2C

   I2C_CR1A   : constant := 16#00#;  -- Control Register 1
   I2C_CR2A   : constant := 16#04#;  -- Control Register 2
   I2C_OAR1  : constant := 16#08#;  --+address propio1
   I2C_OAR2 : constant := 16#0C#;  --adress prop 2
   I2C_TIMING : constant := 16#10#;  --registro para timing
   I2C_TIMEOUT : constant := 16#14#;  --registro de tiemout
   I2C_ISRA  : constant := 16#18#;  -- interrupcion y stauts
   I2C_ICRA  : constant := 16#1C#;  -- clear interrupt
   I2C_PEC  : constant := 16#20#;  -- Packet Error Checking Register cosa nueva opcional que sirve para entornos con ruido genera como un crc para checkerar integridad
   I2C_RXDA : constant := 16#24#;  -- registro de recepcion
   I2C_TXDA  : constant := 16#28#;  -- transmisión

   -- Bits del registro CR1

   I2C_CR1_PE       : constant := 0;   -- perifericos enable a nivel bajo
   I2C_CR1_TXI     : constant := 1;   -- avisa registro vacio con int de trans
   I2C_CR1_RXI     : constant := 2;   -- avisa registro vacio con int de recep
   I2C_CR1_ADDRI   : constant := 3;   -- interruption cuando match el address con el del bus
   I2C_CR1_NACKI   : constant := 4;   -- si el otro hace nack se pone a 1 y vamos mal
   I2C_CR1_STOPI   : constant := 5;   --  si se envia bit de stop 1
   I2C_CR1_TCIE     : constant := 6;   -- Transfer Complete Interrupt Enable
   I2C_CR1_ERRIE    : constant := 7;   -- Error int enable
   I2C_CR1_DNF      : constant := 8;   -- Digital noise filter ( 8 al 11)
   I2C_CR1_ANFOFF   : constant := 12;  -- analog noise filter
   I2C_CR1_TXDMA  : constant := 14;  -- DMA para que cpu no trabaje
   I2C_CR1_RXDMA  : constant := 15;  -- DMA reception enable
   I2C_CR1_SBC      : constant := 16;  -- si está on hace que dure más el reloj para decidir si ack o no
   I2C_CR1_NOSTRETCH : constant := 17;  -- Clock strech disable
   I2C_CR1_WUP    : constant := 18;  -- i2c despierte del modo bajo consumo
   I2C_CR1_GCEN     : constant := 19;  -- habilitar respuesta a broadcast cuando addr es 0
   --BusSMBUs es más estricto y seguro
   I2C_CR1_SMBH   : constant := 20;  -- SMBus Host address enable ??
   I2C_CR1_SMBD  : constant := 21;  -- habilita dir por defectod e smbus
   I2C_CR1_ALERTEN  : constant := 22;  -- si escalvo problema int a master
   I2C_CR1_PECEN    : constant := 23;  -- PEC enable



   -- Bits del registro CR2


   I2C_CR2_SADD     : constant := 0;   -- slave address
   I2C_CR2_RD_WRN   : constant := 10;  -- Tdireccion 0:w 1:r
   I2C_CR2_ADD10    : constant := 11;  -- 10-bit Addressing Mode
   I2C_CR2_HEAD10R  : constant := 12;  --  no se suele usar para cuando +10 b
   I2C_CR2_START    : constant := 13;  -- Genera start
   I2C_CR2_STOP     : constant := 14;  -- GEnera stop
   I2C_CR2_NACK     : constant := 15;  -- Genera nack
   I2C_CR2_NBYTES   : constant := 16;  -- numero de bytes
   I2C_CR2_RELOAD   : constant := 24;  --  se usa tipo acaba n bytes y otra vez mas nbytes para eproom
   I2C_CR2_AUTOEND  : constant := 25;  -- genera el  stop al terminar los bytes
   I2C_CR2_PECBYTE  : constant := 26;  -- packet error checking

   -- Bits del registro ISR
   I2C_ISR_TXE      : constant := 0;   -- Transmit Data Register Empty
   I2C_ISR_TXIS     : constant := 1;   -- 1  registro vacio listo para envir
   I2C_ISR_RXNE     : constant := 2;   -- 1 byte recibido
   I2C_ISR_ADDR     : constant := 3;   --  la address hace match
   I2C_ISR_NACKF    : constant := 4;   -- NACK flag, esclavo no responde
   I2C_ISR_STOPF    : constant := 5;   -- Stop detection flag
   I2C_ISR_TC       : constant := 6;   -- Transfer complete
   I2C_ISR_TCR      : constant := 7;   -- Transfer complete reload
   I2C_ISR_BERR     : constant := 8;   -- Bus error
   I2C_ISR_ARLO     : constant := 9;   -- problema de arbitra
   I2C_ISR_OVR      : constant := 10;  --  no leer or escribir a tiempo
   I2C_ISR_PECERR   : constant := 11;  -- PEC Error
   I2C_ISR_TIMEOUT  : constant := 12;  -- timeout
   I2C_ISR_ALERT    : constant := 13;  -- SmBus alerta
   I2C_ISR_BUSY     : constant := 15;  -- bus busy

   -- Pines I2C en GPIOB
   SCL_Pin : constant := 8;   -- PB8 como SCL
   SDA_Pin : constant := 9;   -- PB9 como SDA

end I2C;
