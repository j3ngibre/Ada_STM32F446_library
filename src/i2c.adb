
with SSD1306;
with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446;use stm32f446;
with I2C; use I2C;
with USART; use USART;

package body I2C is

protected body Bus is
procedure Initialize is
begin
     
   if Initialized then
      return;
   end if;
   RCC_AHB1ENR := RCC_AHB1ENR or Uint32(2#10#);
   RCC_APB1ENR := RCC_APB1ENR  or Uint32(2**21);

--recuperacionde bus 
   -- Limpiar MODER PB8 y PB9
   GPIOB_MODER := (GPIOB_MODER
      and not(Uint32(2**16)) and not(Uint32(2**17))
      and not(Uint32(2**18)) and not(Uint32(2**19)))
      or Uint32(2**16) or Uint32(2**18);  -- output (01) PB8 y PB9

   -- Open-drain 
   GPIOB_OTYPER := GPIOB_OTYPER
      or Uint32(2**8) or Uint32(2**9);

   -- Pull-up activo
   GPIOB_PUPDR := (GPIOB_PUPDR
      and not(Uint32(2**17)) and not(Uint32(2**19)))
      or Uint32(2**16) or Uint32(2**18);

   -- Ambas líneas altas inicialmente
   GPIOB_ODR := GPIOB_ODR or Uint32(2**8) or Uint32(2**9);
   for J in 1 .. 500 loop null; end loop;

   -- 9 pulsos de SCL manteniendo SDA alto
   for I in 1 .. 9 loop
      GPIOB_ODR := GPIOB_ODR and not(Uint32(2**8));  -- SCL bajo
      for J in 1 .. 500 loop null; end loop;
      GPIOB_ODR := GPIOB_ODR or Uint32(2**8);         -- SCL alto
      for J in 1 .. 500 loop null; end loop;
   end loop;

   --SDA sube mientras SCL está alto
   GPIOB_ODR := GPIOB_ODR and not(Uint32(2**9));  -- SDA bajo
   for J in 1 .. 500 loop null; end loop;
   GPIOB_ODR := GPIOB_ODR or Uint32(2**8);         -- SCL alto
   for J in 1 .. 500 loop null; end loop;
   GPIOB_ODR := GPIOB_ODR or Uint32(2**9);         -- SDA alto = STOP
   for J in 1 .. 500 loop null; end loop;

   I2C_CR1A := I2C_CR1A or  Uint32(2**I2C_CR1_SWRST);
   for I in 1 .. 200 loop null; end loop;
   I2C_CR1A := I2C_CR1A and not(Uint32(2**I2C_CR1_SWRST));

  --conf
   GPIOB_MODER := (GPIOB_MODER
      and not(Uint32(2**16)) and not(Uint32(2**17))
      and not(Uint32(2**18)) and not(Uint32(2**19)))
      or Uint32(2**17) or Uint32(2**19);            -- AF (10)

   GPIOB_OTYPER := GPIOB_OTYPER
      or Uint32(2**8) or Uint32(2**9);              -- open-drain

   GPIOB_OSPEEDR := (GPIOB_OSPEEDR
      and not(Uint32(2**16)) and not(Uint32(2**18)))
      or Uint32(2**17) or Uint32(2**19);            -- fast speed

   GPIOB_PUPDR := (GPIOB_PUPDR
      and not(Uint32(2**17)) and not(Uint32(2**19)))
      or Uint32(2**16) or Uint32(2**18);            -- pull-up

   GPIOB_AFRH := (GPIOB_AFRH and not(Uint32(16#FF#)))
      or Uint32(16#44#);                            -- AF4

 --conf i2c
   I2C_CR1A := I2C_CR1A and not(Uint32(2**I2C_CR1_PE));

   I2C_CR2A := (I2C_CR2A and not(Uint32(16#3F#)))
      or Uint32(42);

   I2C_CCRA := (I2C_CCRA
      and not(Uint32(2**I2C_CCR_FS))
      and not(Uint32(2**I2C_CCR_DUTY))
      and not(Uint32(16#0FFF#)))
      or Uint32(210);

   I2C_TRISEA := (I2C_TRISEA and not(Uint32(16#3F#)))
      or Uint32(43);


   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_PE);


   for I in 1 .. 10_000 loop null; end loop;
   if (I2C_SR2A and Uint32(2)) /= 0 then
      USART.Send_Line ("WARN: bus sigue BUSY tras init");
   else
      USART.Send_Line ("OK: bus libre tras init");
   end if;
   Initialized:=true;
end Initialize;





 procedure Clear_Errors is
   Tmp : Uint32;
begin
   -- Leer SR1 para capturar estado actual
   Tmp := I2C_SR1A;
   
   --  Limpiar AF (Acknowledge Failure): leer SR2
   if (Tmp and (2**I2C_SR1_AF)) /= 0 then
      Tmp := I2C_SR2A;  -- Leer SR2 limpia AF
   end if;
   
   --  Limpiar STOPF: leer SR1 y luego escribir CR1
   if (Tmp and (2**I2C_SR1_STOPF)) /= 0 then
      Tmp := I2C_SR1A;     
      I2C_CR1A := I2C_CR1A;  
   end if;
   
   --  Limpiar BERR: leer SR1 y luego escribir CR1
   if (Tmp and (2**I2C_SR1_BERR)) /= 0 then
      Tmp := I2C_SR1A;-- Escribir CR1 limpia BERR
   end if;
   
   --  Limpiar ARLO: leer SR1 y luego escribir CR1
   if (Tmp and (2**I2C_SR1_ARLO)) /= 0 then
      Tmp := I2C_SR1A;
      I2C_CR1A := I2C_CR1A; 
   end if;
   
   -- 6. Limpiar OVR: leer SR1 y luego leer DR
   if (Tmp and (2**I2C_SR1_OVR)) /= 0 then
      Tmp := I2C_SR1A;
      Tmp := I2C_DRA;       
   end if;
end Clear_Errors;



function Wait_Flag (Flag_Mask  : Uint32;
                    Timeout_MS : Positive) return Boolean is
   Deadline : constant Time := Clock + Milliseconds (Timeout_MS);
begin
   loop
      -- Flag conseguida: salir con éxito
      if (I2C_SR1A and Flag_Mask) /= 0 then
         return True;
      end if;

      -- NACK (AF): limpiar y liberar bus
      if (I2C_SR1A and Uint32(2**I2C_SR1_AF)) /= 0 then
         I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_AF));  -- limpiar AF
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);      -- liberar bus
         return False;
      end if;

      -- Bus Error (BERR)
      if (I2C_SR1A and Uint32(2**I2C_SR1_BERR)) /= 0 then
         I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_BERR));
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;

      -- Arbitration Lost (ARLO)
      if (I2C_SR1A and Uint32(2**I2C_SR1_ARLO)) /= 0 then
         I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_ARLO));
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;

      -- Timeout
      if Clock > Deadline then
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;

   end loop;
end Wait_Flag;

function I2C_Write (SlaveAddr : Uint8;
                    Data      : Uint8) return Boolean is
   Status : Uint32 with Volatile;
begin
   --  START
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), 100) then
      USART.Send_Line ("FAIL: SB timeout");
      return False;
   end if;

   --  Enviar dirección (escritura: bit0 = 0)
   I2C_DRA := Uint32(SlaveAddr) * 2;

   --  Esperar ADDR
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), 100) then
      USART.Send_Line ("FAIL: ADDR timeout (esclavo no responde ACK)");
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);  -- liberar bus
      return False;
   end if;

   --  Limpiar ADDR leyendo SR1 + SR2
   Status := I2C_SR1A;
   Status := I2C_SR2A;

   --  Esperar TXE ANTES de escribir el dato
   if not Wait_Flag (Uint32(2**I2C_SR1_TXE), 100) then
      USART.Send_Line ("FAIL: TXE timeout antes de dato");
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;

   --  Enviar dato
   I2C_DRA := Uint32(Data);

   --  Esperar BTF (transferencia completa)
   if not Wait_Flag (Uint32(2**I2C_SR1_BTF), 100) then
      USART.Send_Line ("FAIL: BTF timeout");
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;

   -- 8. STOP
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);

   return True;
end I2C_Write;


function I2C_WriteBuffer (SlaveAddr : Uint8;
                          Data      : Uint8_Array) return Boolean is
   Status : Uint32 with Volatile;
   Timeout :Integer; 
begin


 -- 0. Limpiar errores anteriores
   I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_AF))
                         and not(Uint32(2**I2C_SR1_BERR))
                         and not(Uint32(2**I2C_SR1_ARLO));
   Status := I2C_SR1A;
   Status := I2C_SR2A;

  --esperar bus
   Timeout := 100;
   while (I2C_SR2A and Uint32(2)) /= 0 loop   -- bit 1 de SR2 = BUSY
      Timeout := Timeout - 1;
      if Timeout = 0 then
         USART.Send_Line ("FAIL: bus BUSY antes de START");
         return False;
      end if;
   end loop;

   if (I2C_CR1A and Uint32(2**I2C_CR1_PE)) = 0 then
      USART.Send_Line ("FAIL: PE no activo");
      return False;
   end if;
  
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);

 
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), 100) then
      USART.Send_Line ("FAIL: SB timeout - bus congelado");
      if (I2C_SR1A and Uint32(2**I2C_SR1_BERR)) /= 0 then
         USART.Send_Line ("--> BERR: falla electrica SDA/SCL");
      end if;
      if (I2C_SR1A and Uint32(2**I2C_SR1_ARLO)) /= 0 then
         USART.Send_Line ("--> ARLO: alguien bloquea SDA");
      end if;
      return False;
   end if;


   Status  := I2C_SR1A;                          -- limpia SB
   I2C_DRA := Uint32(SlaveAddr) * 2;             -- dirección + R/W=0

 --esperar addr
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), 100) then
      -- Comprobar si fue NACK (AF)
      if (I2C_SR1A and Uint32(2**I2C_SR1_AF)) /= 0 then
         USART.Send_Line ("FAIL: NACK en direccion - esclavo no responde");
         I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_AF));  -- limpiar AF
      else
         USART.Send_Line ("FAIL: ADDR timeout");
      end if;
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;


   Status := I2C_SR1A;
   Status := I2C_SR2A;


   for Byte of Data loop

      -- Esperar TXE antes de escribir
      if not Wait_Flag (Uint32(2**I2C_SR1_TXE), 100) then
         USART.Send_Line ("FAIL: TXE timeout");
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;

      -- Comprobar NACK durante envio
      if (I2C_SR1A and Uint32(2**I2C_SR1_AF)) /= 0 then
         USART.Send_Line ("FAIL: NACK durante envio de datos");
         I2C_SR1A := I2C_SR1A and not(Uint32(2**I2C_SR1_AF));
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;

      I2C_DRA := Uint32(Byte);

   end loop;


   if not Wait_Flag (Uint32(2**I2C_SR1_BTF), 100) then
      USART.Send_Line ("FAIL: BTF timeout");
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;

   
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);

   return True;
end I2C_WriteBuffer;

function I2C_Read (SlaveAddr : Uint8;
                   Data : out Uint8) return Boolean is
   Status : Uint32;
   Time: constant Positive := 100;
begin
  
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);
   
   -- flag SB (Start Bit)
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), Time) then
      return False;
   end if;
   
   --Dir esclavo lect
   I2C_DRA := Uint32(SlaveAddr * 2) or 16#01#;  -- Bit 0 = 1 (lectura)
   
   --flag addr dir enviada
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), Time) then
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;
   
   --limpiar flag adr
   Status := I2C_SR1A;
   Status := I2C_SR2A;
   
   --Esperar dato
   if not Wait_Flag (Uint32(2**I2C_SR1_RxNE), Time) then
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;
   
   --Leer dato
   Data := Uint8(I2C_DRA and 16#FF#);
   
   --Byte stop 
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
   
   return True;
end I2C_Read;



function I2C_ReadBuffer (SlaveAddr : Uint8;
                              Data : out Uint8_Array) return Boolean
 is
   Status : Uint32;
   Time : constant Positive := 100;

begin

   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), Time) then
      return False;
   end if;
   
  
   I2C_DRA := Uint32(SlaveAddr * 2) or 16#01#;
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), Time) then
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;
   
  
   Status := I2C_SR1A;
   Status := I2C_SR2A;
   
  
   for I in Data'Range loop
      -- Si es el ult byte, debemos generar NACK y STOP
      if I = Data'Last then  
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_ACK); 
      end if;
      
      -- Esperar RxNE
      if not Wait_Flag (Uint32(2**I2C_SR1_RxNE), Time) then
         I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
         return False;
      end if;
      
      Data(I) := Uint8(I2C_DRA and 16#FF#);
   end loop;
   
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
   
   return True;
end I2C_ReadBuffer;

end Bus;
end I2C;