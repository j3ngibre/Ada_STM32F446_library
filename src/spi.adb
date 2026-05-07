with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446;     use stm32f446;
with USART;
with USART_Driver;         use USART_Driver;

package body SPI is



   function SPI_AF(SPIBase  : Uint32; GPIOBase : Uint32;Pin       : Natural) return Uint32 is
   begin
      case SPIBase is

     
         when SPI1_Base =>  return 5;
      
         when SPI2_Base =>   -- SPI2
            case GPIOBase is
               when GPIOC =>
                  case Pin is
                     when 2 | 3            => return 5; 
                     when 1                => return 7;--MOSI PC1
                     when others           => return 16#FFFF_FFFF#;
                  end case;
               when others =>
               return 5;
            end case;
  
         when SPI3_Base =>   -- SPI3
            case GPIOBase is
               when GPIOB =>
                  case Pin is
                     when 0 | 2          => return 7; --PB0 MOSI  PB2 MOSI
                     when 3 | 4 | 5      => return 6; -- PB3 SCK, PB4 MISO, PB5 MOSI
                     when others         => return 16#FFFF_FFFF#;
                  end case;

               when GPIOC =>
                  case Pin is
                     when 1              => return 5;
                     when 10 | 11 | 12   => return 6; -- PC10 SCK, PC11 MISO, PC12 MOSI
                     when others         => return 16#FFFF_FFFF#;
                  end case;

               when GPIOD =>
                  case Pin is
                     when 0              => return 6;
                     when 6              => return 5; -- PC10 SCK, PC11 MISO, PC12 MOSI
                     when others         => return 16#FFFF_FFFF#;
                  end case;

               when others =>
                  return 16#FFFF_FFFF#;
            end case;

         when SPI4_Base =>   -- SPI4
            case GPIOBase is
               when GPIOD => return 5;
               when GPIOE => return 5;
               when GPIOG => return 6;
               when others => return 16#FFFF_FFFF#;    
            end case;

         when others =>
            return 16#FFFF_FFFF#;
      end case;
   
   end SPI_AF;


    
   procedure Initialize is --TEORICAMENTE HECHo
      AF_MISO:Uint32:=SPI_AF (SPI_Base, GPIO_MISO, MISO_Pin);
      AF_MOSI:Uint32:=SPI_AF (SPI_Base, GPIO_MOSI, MOSI_Pin);
      AF_SCK:Uint32:=SPI_AF (SPI_Base, GPIO_SCK, SCK_Pin);
   begin
  
   
      -- A. Habilitar relojes
       case SPI_Base is
         when SPI1_Base=>
          RCC_APB2ENR := RCC_APB2ENR or Uint32(2**SPI1_EN);
         when SPI3_Base =>
            RCC_APB1ENR := RCC_APB1ENR or Uint32(2** SPI3_EN);
         when SPI2_Base =>
            RCC_APB1ENR := RCC_APB1ENR or Uint32(2**SPI2_EN);
         when SPI4_Base=>
            RCC_APB2ENR := RCC_APB2ENR or Uint32(2**SPI4_EN);
         when others=>
          RCC_APB2ENR := RCC_APB2ENR or Uint32(2**SPI1_EN); 
      end case;
  
     
      RCC_AHB1ENR := RCC_AHB1ENR or GPIO_To_AHB1_Bit(GPIO_MISO)or GPIO_To_AHB1_Bit(GPIO_MOSI) or GPIO_To_AHB1_Bit(GPIO_SCK) or GPIO_To_AHB1_Bit(GPIO_CS);
 
      -- B. CS alto antes de configurar
      GPIO_CS_ODR := GPIO_CS_ODR or Uint32(2**CS_Pin);


      -- C. Configurar  (SCK),  (MISO),  (MOSI) como AF
     

        GPIO_MISO_MODER := (GPIO_MISO_MODER
         and not(Uint32(2**(2*MISO_Pin))) and not(Uint32(2**((2*MISO_Pin)+1))))  
         or Uint32(2**((2*MISO_Pin)+1));  

       GPIO_MOSI_MODER := (GPIO_MOSI_MODER
         and not(Uint32(2**(2*MOSI_Pin))) and not(Uint32(2**((2*MOSI_Pin)+1)))) 
         or Uint32(2**((2*MOSI_Pin)+1));    


       GPIO_SCK_MODER := (GPIO_SCK_MODER
         and not(Uint32(2**(2*SCK_Pin))) and not(Uint32(2**((2*SCK_Pin)+1)))) 
         or Uint32(2**((2*SCK_Pin)+1));    

      

      GPIO_MISO_OTYPER := GPIO_MISO_OTYPER 
         and not(Uint32(2**MISO_Pin));
      
      GPIO_MOSI_OTYPER := GPIO_MOSI_OTYPER 
         and not(Uint32(2**MOSI_Pin));

      GPIO_SCK_OTYPER := GPIO_SCK_OTYPER 
         and not(Uint32(2**SCK_Pin));

      
      GPIO_MOSI_OSPEEDR:=(GPIO_MOSI_OSPEEDR
      and not(Uint32(2**(2*MOSI_Pin)))) or Uint32(2**((2*MOSI_Pin)+1));
      
      GPIO_MISO_OSPEEDR:=(GPIO_MISO_OSPEEDR
      and not(Uint32(2**(2*MISO_Pin)))) or Uint32(2**((2*MISO_Pin)+1));

      GPIO_SCK_OSPEEDR:=(GPIO_SCK_OSPEEDR
      and not(Uint32(2**(2*SCK_Pin)))) or Uint32(2**((2*SCK_Pin)+1));


      GPIO_SCK_PUPDR :=(GPIO_SCK_PUPDR and not(Uint32(2**(2*SCK_Pin))) and not(Uint32(2**((2*SCK_Pin)+1))));
      GPIO_MOSI_PUPDR :=(GPIO_MOSI_PUPDR and not(Uint32(2**(2*MOSI_Pin))) and not(Uint32(2**((2*MOSI_Pin)+1))));
      GPIO_MISO_PUPDR :=(GPIO_MISO_PUPDR and not(Uint32(2**(2*MISO_Pin))) and not(Uint32(2**((2*MISO_Pin)+1)))) or Uint32(2**(2*MISO_Pin)); 
  
  

      if MISO_Pin <= 7 then
         GPIO_MISO_AFRL:=(GPIO_MISO_AFRL  and not(Uint32(2#1111# * (2**(4*MISO_PIN))))) or Uint32(AF_MISO * (2**(4*(MISO_Pin))));
        
      else
            GPIO_MISO_AFRH:=(GPIO_MISO_AFRH and not(Uint32(2#1111# * (2**(4*(MISO_Pin-8)))))) or Uint32(AF_MISO* (2**(4*(MISO_Pin-8)))); 
      end if;


      if MOSI_Pin <= 7 then
         GPIO_MOSI_AFRL:=(GPIO_MOSI_AFRL  and not(Uint32(2#1111# * (2**(4*MOSI_PIN))))) or Uint32(AF_MOSI * (2**(4*(MOSI_Pin))));  
      else
         GPIO_MOSI_AFRH:=(GPIO_MOSI_AFRH and not(Uint32(2#1111# * (2**(4*(MOSI_Pin-8)))))) or Uint32(AF_MOSI* (2**(4*(MOSI_Pin-8)))); 
      end if;


      if SCK_Pin <=7 then 
          GPIO_SCK_AFRL:=(GPIO_SCK_AFRL  and not(Uint32(2#1111# * (2**(4*SCK_Pin))))) or Uint32(AF_SCK * (2**(4*(SCK_Pin))));
      else
          GPIO_SCK_AFRH:=(GPIO_SCK_AFRH and not(Uint32(2#1111# * (2**(4*(SCK_Pin-8)))))) or Uint32(AF_SCK* (2**(4*(SCK_Pin-8)))); 
      end if ;

       
      -- D. Configurar PB6 como CS (GPIO salida)
      GPIO_CS_MODER := (GPIO_CS_MODER
         and not(Uint32(2**(2*CS_Pin))) and not(Uint32(2**((2*CS_Pin)+1))))
         or Uint32(2**(2*CS_Pin));             

      GPIO_CS_OSPEEDR := (GPIO_CS_OSPEEDR
         and not(Uint32(2**(2*CS_Pin))))
         or Uint32(2**((2*CS_Pin)+1));            

      GPIO_CS_PUPDR := (GPIO_CS_PUPDR
         and not(Uint32(2**(2*CS_Pin))) and not(Uint32(2**((2*CS_Pin)+1))));  -- sin pull

      -- E. Configurar SPI
      -- Deshabilitar primero
      SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_SPE));

      -- CR1: Master, Mode 0, 8 bit, MSB first, SSM=1, SSI=1
      -- Velocidad inicial baja para SD (BR=111 = /256 = 328 kHz)
      SPI_CR1 :=
         Uint32(2**SPI_CR1_MSTR)    -- Master
         or Uint32(2**SPI_CR1_SSM)  -- Software CS
         or Uint32(2**SPI_CR1_SSI)  -- SSI=1
         or BR_DIV256;              -- 328 kHz para init SD
         -- CPOL=0, CPHA=0 → Mode 0 (bits no puestos = 0)
         -- DFF=0 → 8 bits
         -- LSBFIRST=0 → MSB first

      -- CR2: sin interrupciones ni DMA por ahora
      SPI_CR2 := 0;

      -- F. Habilitar SPI1
      SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_SPE);

      Send_Line ("OK: SPI1 inicializado a 328 kHz");
   end Initialize;


   procedure Set_Speed_Low is--hecho
   begin
      -- Deshabilitar, cambiar BR, habilitar
      SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI_CR1 := (SPI_CR1 and not(Uint32(16#38#))) or BR_DIV256;
      SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_SPE);
   end Set_Speed_Low;

   procedure Set_Speed_High is--hecho 
   begin
      SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI_CR1 := (SPI_CR1 and not(Uint32(16#38#))) or BR_DIV4;
      SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_SPE);
      Send_Line ("OK: SPI1 a 21 MHz");
   end Set_Speed_High;

   -- HECHO
   procedure CS_Low is
   begin
      GPIO_CS_ODR := GPIO_CS_ODR and not(Uint32(2**CS_Pin));
   end CS_Low;

   procedure CS_High is
   begin
      GPIO_CS_ODR := GPIO_CS_ODR or Uint32(2**CS_Pin);
   end CS_High;

   
   -- Esperar TXE (buffer TX vacío) --hecho
   procedure Wait_TXE is
   begin
      loop
         exit when (SPI_SR and Uint32(2**SPI_SR_TXE)) /= 0;
      end loop;
   end Wait_TXE;

   -- Esperar RXNE (buffer RX no vacío) --hecho
   procedure Wait_RXNE is
   begin
      loop
         exit when (SPI_SR and Uint32(2**SPI_SR_RXNE)) /= 0;
      end loop;
   end Wait_RXNE;

   -- Esperar que no esté ocupado--hecho
   procedure Wait_Not_Busy is
   begin
      loop
         exit when (SPI_SR and Uint32(2**SPI_SR_BSY)) = 0;
      end loop;
   end Wait_Not_Busy;

   
   function Transfer_8 (Data : Uint8) return Uint8 is --hecho 
   begin
      Wait_TXE;
      SPI_DR := Uint32(Data);
      Wait_RXNE;
      return Uint8(SPI_DR and 16#FF#);
   end Transfer_8;

   function Transfer_16 (Data : Uint16) return Uint16 is
   begin
      -- Cambiar a 16 bits
      SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_SPE));
      SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_DFF);
      SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_SPE);

      Wait_TXE;
      SPI_DR := Uint32(Data);
      Wait_RXNE;

      declare
         Result : constant Uint16 := Uint16(SPI_DR and 16#FFFF#);
      begin
         -- Volver a 8 bits
         SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_SPE));
         SPI_CR1 := SPI_CR1 and not(Uint32(2**SPI_CR1_DFF));
         SPI_CR1 := SPI_CR1 or Uint32(2**SPI_CR1_SPE);
         return Result;
      end;
   end Transfer_16;

 --hecho hasta aqui 
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