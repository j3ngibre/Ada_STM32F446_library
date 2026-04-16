
with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446; use stm32f446;
package body USART is
-- -/
-- *********************************************************************************************************************************
--    
--    
--                         REGISTROS MAPEADOS EN MEMORIA
-- 
--    RCC_AHB1ENR : RCC AHB1 ENABLE ->Habilita el reloj para perifericos conectados a AHB1 (Bus de alta velocidad 1 para gpio , dma ,crc , sram ,e tc)
--    RCC_APB1ENR : RCC APB1 ENABLE ->APB1(ES advanced bus para perifericos más lentos USART2 , USART3 , UART4 , SPI2, I2C , TIM2)
--    GPIOA_MODER : GPIO MODE REISTER : cada 2 bits 00-> input , 01-> output ,  10->alternate , 11 analog
--    GPIOA_AFRL : GPIO Alternate function low register : configuras que funcion alternativa , cada pin  4 bits
--    GPIOA_PUPDR : Pull up / pull down register 00-> nada , 01 -> pull ip , 10 -> pull down (nuestro caso pull up)
--    USART2_SR : registro de estado (explicado ads)
--    USART2_DR: registro de datos se lee aqui
--    USART2_BRR: baud rate register : se calcula siendo BRR=  PCLK1 / baudrate  (reloj / lo que queremos)
--    USART2_CR1 : Control principal 13 enable usart , 3 enable transmit 2 enable receiver
--    USART2_CR2: Control 2 ->stop bits , sincrono , multiprocesador 
--                      
--                      
--                      
--                      CR2:
-- 
-- | Bit(s) | Nombre  | Función                           |
-- | ------ | ------- | --------------------------------- |
-- | 15     | LINEN   | Habilita modo LIN                 |
-- | 14     | STOP[1] | Stop bits                         |
-- | 13     | STOP[0] | Stop bits                         |
-- | 11     | CLKEN   | Habilita reloj síncrono           |
-- | 10     | CPOL    | Polaridad reloj (modo síncrono)   |
-- | 9      | CPHA    | Fase reloj (modo síncrono)        |
-- | 8      | LBCL    | Último pulso de reloj             |
-- | 6      | LBDIE   | Interrupción LIN                  |
-- | 5      | LBDL    | Longitud detección break          |
-- | 4:0    | ADD     | Dirección en modo multiprocesador |
-- 
-- Nosotrs 0 que es asincrono stop bit normal
-- 
-- 
-- 
-- USART2_CR3: FUnciones complejas normalmente a 0 en 8N1
-- 
-- 
-- | Bit | Nombre | Función                |
-- | --- | ------ | ---------------------- |
-- | 14  | CTSIE  | Interrupción por CTS   |
-- | 13  | CTSE   | Enable CTS             |
-- | 12  | RTSE   | Enable RTS             |
-- | 11  | DMAT   | DMA transmisión        |
-- | 10  | DMAR   | DMA recepción          |
-- | 8   | SCEN   | Smartcard mode         |
-- | 7   | NACK   | Smartcard NACK         |
-- | 6   | HDSEL  | Half-duplex            |
-- | 5   | IRLP   | IrDA modo bajo consumo |
-- | 4   | IREN   | IrDA enable            |
-- | 3   | EIE    | Interrupción por error |
-- 
-- 
-- 
-- 
-- 
--    *******************************************************************************************************************
-- -/

  
   







--Si no funciona el runtime usaremos esto


   procedure Delay_Loop (Cycles : Uint32) is
      C : Uint32 := Cycles;
   begin
      while C > 0 loop
         C := C - 1;
      end loop;
   end Delay_Loop;

   
   
   procedure Initialize (Baudrate : Uint32) is
      PCLK1 : constant Uint32 := 42_000_000;  -- Segun configuracion 16mhz , 42mhz , 48 mhz ni idea de pq es 42
      Div : Uint32;
   begin
      --  Habilitar reloj para GPIOA
      RCC_AHB1ENR := RCC_AHB1ENR or AHB1_RX_Bit or AHB1_TX_Bit;
      
      --  Habilitar reloj para USART2
      case USART_Base is
         when USART1_Base=> 
                           RCC_APB2ENR:= RCC_APB2ENR or APB_USART_Bit;
                     
         when USART6_Base=>RCC_APB2ENR:= RCC_APB2ENR or APB_USART_Bit;
         when others => RCC_APB1ENR := RCC_APB1ENR or APB_USART_Bit;
      end case;

    
     -- Delay_Loop (1000);
      delay(0.001);
      -- PA2 como funcion alternativa por tanto creo que es 42 (tx)
      GPIO_MODER_TX := GPIO_MODER_TX and not (3 * 4**(TX_PIN));--#estoy poniendo 11 para limpiar bueno en nuestro caso 11100111
      GPIO_MODER_TX := GPIO_MODER_TX or (2 * 4**(TX_PIN));
      
      --  PA3 (RX) como  alternativa 
      GPIO_MODER_RX := GPIO_MODER_RX and not (3 * 4**(RX_PIN));--#estoy poniendo 11 para limpiar bueno en nuestro caso 11100111
      GPIO_MODER_RX := GPIO_MODER_RX or (2 * 4**(RX_PIN));
      -- función alternativa AF7 para PA2 y PA3

      
       if TX_PIN < 8 then 
      GPIO_AFRL_TX := (GPIO_AFRL_TX 
    and not(Uint32(2#1111# * (2**(4*TX_PIN))))) or Uint32(AF_TX * (2**(4*(TX_PIN)))); 
    else 
    GPIO_AFRH_TX := (GPIO_AFRH_TX
    and not(Uint32(2#1111# * (2**(4*(TX_PIN-8)))))) or Uint32(AF_TX* (2**(4*(TX_PIN-8)))); 
    end if; 


          
       if RX_PIN < 8 then 
      GPIO_AFRL_RX := (GPIO_AFRL_RX 
    and not(Uint32(2#1111# * (2**(4*RX_PIN))))) or Uint32(AF_RX * (2**(4*(RX_PIN)))); 
    else 
    GPIO_AFRH_RX := (GPIO_AFRH_RX
    and not(Uint32(2#1111# * (2**(4*(RX_PIN-8)))))) or Uint32(AF_RX* (2**(4*(RX_PIN-8)))); 
    end if; 
    

      --a partir de aqui
      -- Configurar pull-ups
      GPIO_PUPDR_TX := GPIO_PUPDR_TX or ( 4**(RX_PIN ));
      GPIO_PUPDR_RX := GPIO_PUPDR_RX or ( 4**(TX_PIN));
      
      --  Calcular baud rate
      Div := PCLK1 / Baudrate;
      USART_BRR := Div;
      
      --  Habilitar USART
      USART_CR1 := (2**CR1_TE) or (2**CR1_RE) or (2**CR1_UE);  -- TE, RE, UE
      
     
      USART_CR2 := 0;
      USART_CR3 := 0;
      
      --Delay_Loop (10000);
      delay(0.01);
   end Initialize;
   




   
   function Data_Available return Boolean is --FUNCION PARA IR DEPURANDO PODEMOS ELIMINARLA 
   begin
      return (USART_SR and (2**SR_RXNE)) /= 0;  -- RXNE el de si hay dato
   end Data_Available;



   
   function Read_Char return Uint8 is
   begin
      while (USART_SR and (2**SR_RXNE)) = 0 loop   --bloqueado esperando a que  llegue algo a RNXE
         null;
      end loop;
      return Uint8 (USART_DR and 16#FF#); --LOs bits de abajo
   end Read_Char;





   
   procedure Send_Char (C : Uint8) is
   begin
      while (USART_SR and (2**SR_TXE)) = 0 loop  -- Esperando TXE , bloqueo
         null;
      end loop;
      USART_DR := Uint32 (C); --A 32 bits 0000_0000_0000_0000_0000_0000_1111_1111
      
      
      while (USART_SR and (2**SR_TC)) = 0 loop  -- TC bit , transmission completed , hasta bloqueado
         null;
      end loop;
   end Send_Char;
   
   procedure Send_String (S : String) is
   begin
      for I in S'Range loop
         Send_Char (Character'Pos (S (I))); --Vamos enviando char a char y yasta
      end loop;
   end Send_String;
   
   procedure Send_Line (S : String) is
   begin
      Send_String (S);
      Send_Char (13);  -- Carriege return -> al principio de la linea
      Send_Char (10);  -- Line finish ->siguiente linea  puede ser interesanto hacer funcion para poder dibujar por pantlla a modo de ampliación
   end Send_Line;
   
end USART;