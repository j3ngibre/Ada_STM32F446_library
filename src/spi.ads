with System;
with stm32f446; use stm32f446;

package SPI is

   -- =========================================
   -- API pública
   -- =========================================
   procedure Initialize;
--envieyrecibe
   function  Transfer_8  (Data : Uint8)  return Uint8;
   function  Transfer_16 (Data : Uint16) return Uint16;

   -- escritura
   procedure Write_8  (Data : Uint8);
   procedure Write_16 (Data : Uint16);

   -- lectura , enviabytedummy
   function Read_8  return Uint8;
   function Read_16 return Uint16;

   -- Buffer
   procedure Write_Buffer   (Data : Uint8_Array);
   procedure Read_Buffer    (Data : out Uint8_Array);
   procedure Transfer_Buffer(TX : Uint8_Array; RX : out Uint8_Array);

   -- Control de velocidad
   procedure Set_Speed_Low;   -- ≤400 kHz para init SD
   procedure Set_Speed_High;  -- máxima velocidad

   -- Control CS (Chip Select) manual
   procedure CS_Low;
   procedure CS_High;

   -- Registros hardware
   -- =========================================
   -- RCC
   -- =========================================

   SPI1_Base : Uint32 := 16#4001_3000#;
   RCC_AHB1ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#30#);
   RCC_APB2ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#44#);  -- SPI1 en APB2

   -- =========================================
   -- GPIOA (PA5=SCK, PA6=MISO, PA7=MOSI)
   -- =========================================
   GPIOA_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#00#);
   GPIOA_OTYPER : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#04#);
   GPIOA_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#08#);
   GPIOA_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#0C#);
   GPIOA_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#14#);
   GPIOA_AFRL : Uint32 with
      Volatile, Address => System'To_Address (GPIOA + 16#20#);

   -- =========================================
   -- GPIOB (PB6=CS)
   -- =========================================
   GPIOB_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIOB + 16#00#);
   GPIOB_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOB + 16#08#);
   GPIOB_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOB + 16#0C#);
   GPIOB_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIOB + 16#14#);

   -- =========================================
   -- SPI1
   -- =========================================
   SPI1_CR1 : Uint32 with
      Volatile, Address => System'To_Address (SPI1_Base + 16#00#);
   SPI1_CR2 : Uint32 with
      Volatile, Address => System'To_Address (SPI1_Base + 16#04#);
   SPI1_SR : Uint32 with
      Volatile, Address => System'To_Address (SPI1_Base + 16#08#);
   SPI1_DR : Uint32 with
      Volatile, Address => System'To_Address (SPI1_Base + 16#0C#);

private

   -- Bits de CR1
   SPI_CR1_CPHA    : constant := 0;
   SPI_CR1_CPOL    : constant := 1;
   SPI_CR1_MSTR    : constant := 2;
   SPI_CR1_BR0     : constant := 3;   -- Baudrate bits [5:3]
   SPI_CR1_BR1     : constant := 4;
   SPI_CR1_BR2     : constant := 5;
   SPI_CR1_SPE     : constant := 6;   -- SPI Enable
   SPI_CR1_LSBFIRST: constant := 7;
   SPI_CR1_SSI     : constant := 8;
   SPI_CR1_SSM     : constant := 9;   -- Software Slave Management
   SPI_CR1_DFF     : constant := 11;  -- Data Frame Format (0=8bit, 1=16bit)

   -- Bits de SR
   SPI_SR_RXNE     : constant := 0;   -- Rx buffer not empty
   SPI_SR_TXE      : constant := 1;   -- Tx buffer empty
   SPI_SR_BSY      : constant := 7;   -- Busy

   -- CS pin: PB6
   CS_Pin : constant := 6;

   -- Prescalers para APB2=84MHz
   -- BR=000 → /2   = 42 MHz
   -- BR=001 → /4   = 21 MHz
   -- BR=010 → /8   = 10.5 MHz
   -- BR=110 → /128 = 656 kHz  ← init SD
   -- BR=111 → /256 = 328 kHz  ← init SD seguro
   BR_DIV256 : constant Uint32 := 16#38#;  -- 111 en bits [5:3] = 328 kHz
   BR_DIV4   : constant Uint32 := 16#08#;  -- 001 en bits [5:3] = 21 MHz

end SPI;