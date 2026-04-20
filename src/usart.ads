
with System;
with stm32f446; use stm32f446;
-- -/
-- 
--  Funcionamiento de usart
-- 
--  -Transmisión en serie (bit a bit linea única)
--  -TX -> transmite
--  -RX -> Recibe
--  -CLK -> Es opcional y solo funciona en modo síncrono
-- 
--  ¿Cómo?
-- 
-- Modo asíncrono
-- 
-- En 8N1 (8 bits , No paridad ,1 bit de stop)
--  |Start|D0|D1|D2|D3|D4|D5|D6|D7|Stop|
-- 
-- Start bit : Siempre es 0 y indica que el receptor comienza la transmisión
-- Bits de datos : LSB  D0 es menos significativo que D7
-- Bit de paridad : Sirve para deteccón de errores puede ser Par o Impar , no lo usamos en el ejemplo
-- Stop bit : Siempre a 1 marca final del byte
-- 
-- La sincronización se hace al configurar el mismo baudrate , bits por segundo 
-- 115200 baudios -> 8.68 us por  Bit
-- 
-- 
-- 
-- A nivel hardware:
-- 
-- Emitir 
-- 
-- 1.Escribes un byte en USART_DR 
-- 2.El hardware añade el start y stop y lo convierte en señal electrica
-- 3.Envia por TX 
-- 4.Activa TXE cuando todo este listo
-- 
-- Recepción
-- 
-- 1.Detecta start bit
-- 2.Muestrea los bits
-- 3.Reconstruye el byte
-- 3.Lo guarda en USART_DR
-- 4.Activa bandera RXNE
-- 
-- 
-- Enviar la letra 'A'
-- 
-- ASCII 'A' = 0x41 = 01000001
-- 
-- Se transmite como:
-- 
-- Start: 0
-- Data:  1 0 0 0 0 0 1 0   (LSB primero)
-- Stop:  1
-- 
-- 
-- Modo sincrono menos común 
-- 
-- Se usa una línea de reloj (CLK)
-- Transmisor genera el reloj
-- Más rápido y preciso
-- Similar a SPI pero diferente estructura
-- 
-- 
-- Modo típico: 115200 8N1
-- 
-- Cada byte:
--    1 start
--    8 datos
--    1 stop
--       → 10 bits totales
-- 
-- -/
generic
   GPIO_RX:Uint32;
   GPIO_TX:Uint32;
   RX_PIN: Natural;
   TX_PIN:Natural;
   AF_RX:Natural;
   AF_TX:Natural;
   USART_Base:Uint32;
 

package USART is
   protected PU is 
  

   procedure Initialize (Baudrate : Uint32);
   
   -- Enviar  char
   procedure Send_Char (C : Uint8);
   
   -- Enviar string 
   procedure Send_String (S : String);
   
   -- Enviar string con salto de linea
   procedure Send_Line (S : String);
   
   -- Leer caracter (bloquea)
   function Read_Char return Uint8;
   
   -- Checkea datos
   function Data_Available return Boolean;
end PU;
  private

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
   
      function USART_To_APB_Bit (Base : Uint32) return Uint32 is
      (case Base is
        when USART1_Base => 2**USART1EN,
        when USART2_Base => 2**USART2EN,
        when USART3_Base => 2**USART3EN,
        when UART4_Base => 2**USART4EN,
        when UART5_Base => 2**USART5EN,
        when USART6_Base => 2**USART6EN,
        when others    => 0);

      AHB1_TX_Bit : constant Uint32 := GPIO_To_AHB1_Bit (GPIO_TX);
      AHB1_RX_Bit : constant Uint32 := GPIO_To_AHB1_Bit (GPIO_RX);
      APB_USART_Bit : constant Uint32 := USART_To_APB_Bit  (USART_Base);
    



    RCC_AHB1ENR : Uint32 with
     Volatile,
     Address => System'To_Address (RCC + AHB1ENR_A);

    RCC_APB2ENR:Uint32 with 
      Volatile, 
      Address => System'To_Address(RCC+APB2ENR_A);
   
   RCC_APB1ENR : Uint32 with
     Volatile,
     Address => System'To_Address (RCC + APB1ENR_A);

    --Esto hay q tocarlo despues
   
   GPIO_MODER_TX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_TX + GPIO_MODER_Offset);
    
    GPIO_MODER_RX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_RX + GPIO_MODER_Offset);
   
   GPIO_AFRL_RX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_RX + GPIO_AFRL_Offset);

    GPIO_AFRL_TX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_TX + GPIO_AFRL_Offset);


       
   GPIO_AFRH_RX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_RX + GPIO_AFRH_Offset);

    GPIO_AFRH_TX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_TX + GPIO_AFRH_Offset);
   
   
   GPIO_PUPDR_RX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_RX + GPIO_PUPDR_Offset);

    GPIO_PUPDR_TX : Uint32 with
     Volatile,
     Address => System'To_Address (GPIO_TX + GPIO_PUPDR_Offset);
   
   USART_SR : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_SR_Offset);
   
   USART_DR : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_DR_Offset);
   
   USART_BRR : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_BRR_Offset);
   
   USART_CR1 : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_CR1_Offset);
   
   USART_CR2 : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_CR2_Offset);
   
   USART_CR3 : Uint32 with
     Volatile,
     Address => System'To_Address (USART_Base + USART_CR3_Offset);

end USART;
