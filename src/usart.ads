
with System;

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


package USART is

   type Uint8 is mod 2**8; --para adb
   type Uint32 is mod 2**32; 


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

private

   -- Direcciones base
   RCC   : constant := 16#4002_3800#; -- Direccion del Reset  y  Clock control para que llegue alimentacion, por defecto siempre apagado
   GPIOA: constant := 16#4002_0000#; -- Direccion del gpioa
   USART2_Base : constant := 16#4000_4400#;  -- USART2 donde están todos los registros 

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
   
end USART;
