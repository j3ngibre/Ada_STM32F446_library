with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446;     use stm32f446;
with USART;         use USART;

package body SPI is

   -- =========================================
   procedure Initialize is
   begin
      -- A. Habilitar relojes
      RCC_AHB1ENR := RCC_AHB1ENR or Uint32(2#1#)    -- GPIOA
                                  or Uint32(2#10#);  -- GPIOB (CS)
      RCC_APB2ENR := RCC_APB2ENR or Uint32(2**12);   -- SPI1

      -- B. CS alto antes de configurar
      GPIOB_ODR := GPIOB_ODR or Uint32(2**CS_Pin);

      -- C. Configurar PA5 (SCK), PA6 (MISO), PA7 (MOSI) como AF5
      -- MODER: AF (10) en bits [11:10], [13:12], [15:14]
      GPIOA_MODER := (GPIOA_MODER
         and not(Uint32(2**10)) and not(Uint32(2**11))  -- limpiar PA5
         and not(Uint32(2**12)) and not(Uint32(2**13))  -- limpiar PA6
         and not(Uint32(2**14)) and not(Uint32(2**15))) -- limpiar PA7
         or Uint32(2**11)                               -- PA5 AF
         or Uint32(2**13)                               -- PA6 AF
         or Uint32(2**15);                              -- PA7 AF

      -- Push-pull (no open-drain para SPI)
      GPIOA_OTYPER := GPIOA_OTYPER
         and not(Uint32(2**5))
         and not(Uint32(2**6))
         and not(Uint32(2**7));

      -- Very high speed
      GPIOA_OSPEEDR := (GPIOA_OSPEEDR
         and not(Uint32(2**10)) and not(Uint32(2**12)) and not(Uint32(2**14)))
         or Uint32(2**11) or Uint32(2**13) or Uint32(2**15);

      -- Pull-up en MISO (PA6)
      GPIOA_PUPDR := (GPIOA_PUPDR
         and not(Uint32(2**10)) and not(Uint32(2**11))  -- PA5 sin pull
         and not(Uint32(2**12)) and not(Uint32(2**13))  -- PA6
         and not(Uint32(2**14)) and not(Uint32(2**15))) -- PA7 sin pull
         or Uint32(2**12);                              -- PA6 pull-up

      -- AF5 para PA5, PA6, PA7 en AFRL
      -- PA5 → bits [23:20] = 0101
      -- PA6 → bits [27:24] = 0101
      -- PA7 → bits [31:28] = 0101
      GPIOA_AFRL := (GPIOA_AFRL
         and not(Uint32(16#FFF00000#)))  -- limpiar PA5, PA6, PA7
         or Uint32(16#55500000#);        -- AF5 para los tres

      -- D. Configurar PB6 como CS (GPIO salida)
      GPIOB_MODER := (GPIOB_MODER
         and not(Uint32(2**12)) and not(Uint32(2**13)))
         or Uint32(2**12);              -- output (01)

      GPIOB_OSPEEDR := (GPIOB_OSPEEDR
         and not(Uint32(2**12)))
         or Uint32(2**13);              -- very high speed

      GPIOB_PUPDR := (GPIOB_PUPDR
         and not(Uint32(2**12)) and not(Uint32(2**13)));  -- sin pull

      -- E. Configurar SPI1
      -- Deshabilitar primero
      SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_SPE));

      -- CR1: Master, Mode 0, 8 bit, MSB first, SSM=1, SSI=1
      -- Velocidad inicial baja para SD (BR=111 = /256 = 328 kHz)
      SPI1_CR1 :=
         Uint32(2**SPI_CR1_MSTR)    -- Master
         or Uint32(2**SPI_CR1_SSM)  -- Software CS
         or Uint32(2**SPI_CR1_SSI)  -- SSI=1
         or BR_DIV256;              -- 328 kHz para init SD
         -- CPOL=0, CPHA=0 → Mode 0 (bits no puestos = 0)
         -- DFF=0 → 8 bits
         -- LSBFIRST=0 → MSB first

      -- CR2: sin interrupciones ni DMA por ahora
      SPI1_CR2 := 0;

      -- F. Habilitar SPI1
      SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_SPE);

      USART.Send_Line ("OK: SPI1 inicializado a 328 kHz");
   end Initialize;

   -- =========================================
   procedure Set_Speed_Low is
   begin
      -- Deshabilitar, cambiar BR, habilitar
      SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI1_CR1 := (SPI1_CR1 and not(Uint32(16#38#))) or BR_DIV256;
      SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_SPE);
   end Set_Speed_Low;

   procedure Set_Speed_High is
   begin
      SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI1_CR1 := (SPI1_CR1 and not(Uint32(16#38#))) or BR_DIV4;
      SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_SPE);
      USART.Send_Line ("OK: SPI1 a 21 MHz");
   end Set_Speed_High;

   -- =========================================
   procedure CS_Low is
   begin
      GPIOB_ODR := GPIOB_ODR and not(Uint32(2**CS_Pin));
   end CS_Low;

   procedure CS_High is
   begin
      GPIOB_ODR := GPIOB_ODR or Uint32(2**CS_Pin);
   end CS_High;

   -- =========================================
   -- Esperar TXE (buffer TX vacío)
   procedure Wait_TXE is
   begin
      loop
         exit when (SPI1_SR and Uint32(2**SPI_SR_TXE)) /= 0;
      end loop;
   end Wait_TXE;

   -- Esperar RXNE (buffer RX no vacío)
   procedure Wait_RXNE is
   begin
      loop
         exit when (SPI1_SR and Uint32(2**SPI_SR_RXNE)) /= 0;
      end loop;
   end Wait_RXNE;

   -- Esperar que no esté ocupado
   procedure Wait_Not_Busy is
   begin
      loop
         exit when (SPI1_SR and Uint32(2**SPI_SR_BSY)) = 0;
      end loop;
   end Wait_Not_Busy;

   -- =========================================
   function Transfer_8 (Data : Uint8) return Uint8 is
   begin
      Wait_TXE;
      SPI1_DR := Uint32(Data);
      Wait_RXNE;
      return Uint8(SPI1_DR and 16#FF#);
   end Transfer_8;

   function Transfer_16 (Data : Uint16) return Uint16 is
   begin
      -- Cambiar a 16 bits
      SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_DFF);
      SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_SPE);

      Wait_TXE;
      SPI1_DR := Uint32(Data);
      Wait_RXNE;

      declare
         Result : constant Uint16 := Uint16(SPI1_DR and 16#FFFF#);
      begin
         -- Volver a 8 bits
         SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_SPE));
         SPI1_CR1 := SPI1_CR1 and not(Uint32(2**SPI_CR1_DFF));
         SPI1_CR1 := SPI1_CR1 or Uint32(2**SPI_CR1_SPE);
         return Result;
      end;
   end Transfer_16;

   -- =========================================
   procedure Write_8 (Data : Uint8) is
      Dummy : Uint8;
   begin
      Dummy := Transfer_8 (Data);
   end Write_8;

   procedure Write_16 (Data : Uint16) is
      Dummy : Uint16;
   begin
      Dummy := Transfer_16 (Data);
   end Write_16;

   function Read_8 return Uint8 is
   begin
      return Transfer_8 (16#FF#);  -- dummy byte
   end Read_8;

   function Read_16 return Uint16 is
   begin
      return Transfer_16 (16#FFFF#);  -- dummy word
   end Read_16;

   -- =========================================
   procedure Write_Buffer (Data : Uint8_Array) is
   begin
      for Byte of Data loop
         Write_8 (Byte);
      end loop;
      Wait_Not_Busy;
   end Write_Buffer;

   procedure Read_Buffer (Data : out Uint8_Array) is
   begin
      for I in Data'Range loop
         Data (I) := Read_8;
      end loop;
   end Read_Buffer;

   procedure Transfer_Buffer (TX : Uint8_Array; RX : out Uint8_Array) is
   begin
      for I in TX'Range loop
         RX (I) := Transfer_8 (TX (I));
      end loop;
      Wait_Not_Busy;
   end Transfer_Buffer;

end SPI;