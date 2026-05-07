with System;
with stm32f446; use stm32f446;
generic
   SPI_Base    : Uint32;
   GPIO_SCK    : Uint32;
   GPIO_MISO   : Uint32;
   GPIO_MOSI   : Uint32;
   GPIO_CS     : Uint32;
   SCK_Pin     : Natural;
   MISO_Pin    : Natural;
   MOSI_Pin    : Natural;
   CS_Pin      : Natural;
package SPI is
 
   procedure Initialize;
 
   
   function  Transfer_8  (Data : Uint8)  return Uint8;
   function  Transfer_16 (Data : Uint16) return Uint16;
 

   procedure Write_8  (Data : Uint8);
   procedure Write_16 (Data : Uint16);
 
   
   function Read_8  return Uint8;
   function Read_16 return Uint16;
 
 
   procedure Write_Buffer   (Data : Uint8_Array);
   procedure Read_Buffer    (Data : out Uint8_Array);
   procedure Transfer_Buffer(TX : Uint8_Array; RX : out Uint8_Array);
 
   
   procedure Set_Speed_Low;   -- ≤400 kHz para init SD
   procedure Set_Speed_High;  -- máxima velocidad
 

   procedure CS_Low;
   procedure CS_High;
 
private
 
  
   function SPI_AF (SPIBase  : Uint32; GPIOBase : Uint32; Pin : Natural) return Uint32;
 
 
   function GPIO_To_AHB1_Bit (Base : Uint32) return Uint32 is
      (case Base is
         when GPIOA => 2**GPIOAEN,
         when GPIOB => 2**GPIOBEN,
         when GPIOC => 2**GPIOCEN,
         when GPIOD => 2**GPIODEN,
         when GPIOE => 2**GPIOEEN,
         when GPIOF => 2**GPIOFEN,
         when GPIOG => 2**GPIOGEN,
         when GPIOH => 2**GPIOHEN,
         when others => 0);
 

   function SPI_To_APB_Bit (Base : Uint32) return Uint32 is
      (case Base is
         when SPI1_Base => 2**SPI1_EN,   
         when SPI2_Base => 2**SPI2_EN,   
         when SPI3_Base => 2**SPI3_EN,  
         when SPI4_Base => 2**SPI4_EN,  
         when others    => 0);
 
   RCC_AHB1ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#30#);
   RCC_APB2ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#44#);  -- SPI1 en APB2
   RCC_APB1ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#40#);
 
 

   --GPIO SCK 
   GPIO_SCK_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#00#);
   GPIO_SCK_OTYPER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#04#);
   GPIO_SCK_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#08#);
   GPIO_SCK_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#0C#);
   GPIO_SCK_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#14#);
   GPIO_SCK_AFRL : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#20#);
   GPIO_SCK_AFRH : Uint32 with
      Volatile, Address => System'To_Address (GPIO_SCK + 16#24#);
 
   -- GPIO MISO
   GPIO_MISO_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#00#);
   GPIO_MISO_OTYPER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#04#);
   GPIO_MISO_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#08#);
   GPIO_MISO_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#0C#);
   GPIO_MISO_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#14#);
   GPIO_MISO_AFRL : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#20#);
   GPIO_MISO_AFRH : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MISO + 16#24#);
 
   -- GPIO MOSI
   GPIO_MOSI_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#00#);
   GPIO_MOSI_OTYPER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#04#);
   GPIO_MOSI_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#08#);
   GPIO_MOSI_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#0C#);
   GPIO_MOSI_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#14#);
   GPIO_MOSI_AFRL : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#20#);
   GPIO_MOSI_AFRH : Uint32 with
      Volatile, Address => System'To_Address (GPIO_MOSI + 16#24#);
 
   -- GPIO CS
   GPIO_CS_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIO_CS + 16#00#);
   GPIO_CS_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_CS + 16#08#);
   GPIO_CS_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_CS + 16#0C#);
   GPIO_CS_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIO_CS + 16#14#);
 
   -- Registros SPI
   SPI_CR1 : Uint32 with
      Volatile, Address => System'To_Address (SPI_Base + 16#00#);
   SPI_CR2 : Uint32 with
      Volatile, Address => System'To_Address (SPI_Base + 16#04#);
   SPI_SR : Uint32 with
      Volatile, Address => System'To_Address (SPI_Base + 16#08#);
   SPI_DR : Uint32 with
      Volatile, Address => System'To_Address (SPI_Base + 16#0C#);
 
   -- Prescalers para APB2=84MHz
   -- BR=000 → /2   = 42 MHz
   -- BR=001 → /4   = 21 MHz
   -- BR=010 → /8   = 10.5 MHz
   -- BR=110 → /128 = 656 kHz  ← init SD
   -- BR=111 → /256 = 328 kHz  ← init SD seguro
   BR_DIV256 : constant Uint32 := 16#38#;  -- 111 en bits [5:3] = 328 kHz
   BR_DIV4   : constant Uint32 := 16#08#;  -- 001 en bits [5:3] = 21 MHz
 
end SPI;
 
