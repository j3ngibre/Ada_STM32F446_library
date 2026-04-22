
with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446; use stm32f446;
with I2C; use I2C;
with USART;
with USART_Driver; use USART_Driver;

package body I2C is

   protected body Bus is

  
     
  procedure Initialize is
  tmp , tmp2 :Integer;
begin
     
   if Initialized then
      return;
   end if;
   RCC_AHB1ENR := RCC_AHB1ENR or AHB1_SCL_Bit or AHB1_SDA_Bit;
   RCC_APB1ENR := RCC_APB1ENR  or APB1_I2C_Bit;


 
   GPIO_MODER_SCL := (GPIO_MODER_SCL
      and not(Uint32(2**(2*SCL_Pin))) and not(Uint32(2**(2*(SCL_Pin+1)))));


   GPIO_MODER_SDA := (GPIO_MODER_SDA
      and not(Uint32(2**(2*SDA_Pin))) and not(Uint32(2**(2*(SDA_Pin+1)))));
  
   GPIO_MODER_SCL:=(GPIO_MODER_SCL or Uint32(2**(2*SCL_Pin)));
   GPIO_MODER_SDA:=(GPIO_MODER_SDA or Uint32(2**(2*SDA_Pin)));


   -- Open-drain 
   GPIO_OTYPER_SCL := GPIO_OTYPER_SCL
      or Uint32(2**SCL_PIN);
      
   GPIO_OTYPER_SCL := GPIO_OTYPER_SCL 
      or Uint32(2**SDA_PIN);

   -- Pull-up activo
    GPIO_PUPDR_SCL := (GPIO_PUPDR_SCL
      and not(Uint32(2**((2*SCL_PIN)+1)))); 
   
   GPIO_PUPDR_SDA := (GPIO_PUPDR_SDA
      and not(Uint32(2**((2*SDA_PIN)+1))));  
      
   GPIO_PUPDR_SCL := GPIO_PUPDR_SCL   
      or Uint32(2**(2*SCL_PIN));

   GPIO_PUPDR_SDA := GPIO_PUPDR_SDA   
      or Uint32(2**(2*SDA_PIN));


   
   -- Ambas líneas altas inicialmente
   GPIO_ODR_SCL := GPIO_ODR_SCL or Uint32(2**SCL_PIN);
   GPIO_ODR_SDA := GPIO_ODR_SDA or Uint32(2**SDA_PIN);
   for J in 1 .. 500 loop null; end loop;
--por aqui
   -- 9 pulsos de SCL manteniendo SDA alto
   for I in 1 .. 9 loop
      GPIO_ODR_SCL := GPIO_ODR_SCL and not(Uint32(2**SCL_PIN));  -- SCL bajo
      for J in 1 .. 500 loop null; end loop;
      GPIO_ODR_SCL := GPIO_ODR_SCL or Uint32(2**SCL_PIN);         -- SCL alto
      for J in 1 .. 500 loop null; end loop;
   end loop;

   --SDA sube mientras SCL está alto
   GPIO_ODR_SDA := GPIO_ODR_SDA and not(Uint32(2**SDA_PIN));  -- SDA bajo
   for J in 1 .. 500 loop null; end loop;
   GPIO_ODR_SCL := GPIO_ODR_SCL or Uint32(2**SCL_PIN);         -- SCL alto
   for J in 1 .. 500 loop null; end loop;
   GPIO_ODR_SDA := GPIO_ODR_SDA or Uint32(2**SDA_PIN);         -- SDA alto = STOP
   for J in 1 .. 500 loop null; end loop;

   CR1 := CR1 or  Uint32(2**I2C_CR1_SWRST);
   for I in 1 .. 200 loop null; end loop;
   CR1 := CR1 and not(Uint32(2**I2C_CR1_SWRST));

  --conf
   GPIO_MODER_SCL := (GPIO_MODER_SCL
      and not(Uint32(4**SCL_PIN)) and not(Uint32((4**SCL_PIN)+1)));

   GPIO_MODER_SDA := (GPIO_MODER_SDA  
      and not(Uint32(4**SDA_PIN)) and not(Uint32((4**SDA_PIN)+1)));

   --Problema por conversion de tipos debemos usar var auxiliar

   tmp := (2*SCL_PIN)+1;
   GPIO_MODER_SCL:=(GPIO_MODER_SCL or Uint32(2**tmp));
   tmp2 := (2*SDA_PIN)+1;
   GPIO_MODER_SDA := (GPIO_MODER_SDA  or Uint32(2**tmp2));            
   
      

   GPIO_OTYPER_SCL := GPIO_OTYPER_SCL
      or Uint32(2**SCL_PIN);
      
   GPIO_OTYPER_SDA := GPIO_OTYPER_SDA
      or Uint32(2**SDA_PIN);
   --hasta aqui creo 

   GPIO_OSPEEDR_SCL := (GPIO_OSPEEDR_SCL
      and not(Uint32(4**SCL_PIN)));
      
   GPIO_OSPEEDR_SDA := (GPIO_OSPEEDR_SDA   
      and not(Uint32(4**SDA_PIN)));

   GPIO_OSPEEDR_SCL :=(GPIO_OSPEEDR_SCL or Uint32(2**tmp));
   GPIO_OSPEEDR_SDA :=(GPIO_OSPEEDR_SDA or Uint32(2**tmp2));
   
    
   
   GPIO_PUPDR_SCL := (GPIO_PUPDR_SCL
      and not(Uint32(2**((2*SCL_PIN)+1)))); 
   
   GPIO_PUPDR_SDA := (GPIO_PUPDR_SDA
      and not(Uint32(2**((2*SDA_PIN)+1))));  
      
   GPIO_PUPDR_SCL := GPIO_PUPDR_SCL   
      or Uint32(2**(2*SCL_PIN));

   GPIO_PUPDR_SDA := GPIO_PUPDR_SDA   
      or Uint32(2**(2*SDA_PIN));


   --FALTA ESTO    
    
    if SCL_PIN < 8 then GPIO_AFRL_SCL := (GPIO_AFRL_SCL 
    and not(Uint32(2#1111# * (2**(4*SCL_PIN))))) or Uint32(I2C_AF * (2**(4*(SCL_PIN)))); -- hay q meter las funciones alternativas 
    else 
    GPIO_AFRH_SCL := (GPIO_AFRH_SCL 
    and not(Uint32(2#1111# * (2**(4*(SCL_PIN-8)))))) or Uint32(I2C_AF* (2**(4*(SCL_PIN-8)))); 
    end if; 
    
    
    if SDA_PIN < 8 then GPIO_AFRL_SDA := (GPIO_AFRL_SDA 
    and not(Uint32(2#1111# * (2**(4*SDA_PIN))))) or Uint32(I2C_AF * (2**(4*SDA_PIN)));                 -- AF4
    else 
    GPIO_AFRH_SDA := (GPIO_AFRH_SDA 
    and not(Uint32(2#1111# * (2**(4*(SDA_PIN-8)))))) or Uint32(I2C_AF *(2**(4*(SDA_PIN-8)))); 
    end if;

 --conf i2c
   CR1 := CR1 and not(Uint32(2**I2C_CR1_PE));

   CR2 := (CR2 and not(Uint32(16#3F#)))
      or Uint32(PCLK1_MHz);

   tmp:= (PCLK1_MHz*10 )/ (2*(I2C_SPEED/100_000));

   CCR := (CCR
      and not(Uint32(2**I2C_CCR_FS))
      and not(Uint32(2**I2C_CCR_DUTY))
      and not(Uint32(16#0FFF#)))
      or Uint32(tmp);

   TRISE := (TRISE and not(Uint32(16#3F#)))
      or Uint32(PCLK1_MHz+1);


  CR1 := CR1 or Uint32(2**I2C_CR1_PE);


   for I in 1 .. 10_000 loop null; end loop;
   if (SR2 and Uint32(2)) /= 0 then
        Send_Line ("WARN: bus sigue BUSY tras init");
   else
        Send_Line ("OK: bus libre tras init");
   end if;
   Initialized:=true;
   

end Initialize;




      -- CORRECCION: AF se limpia escribiendo 0 en SR1[AF],
      -- no leyendo SR2 (SR2 limpia ADDR, no AF).
      procedure Clear_Errors is
         Tmp : Uint32;
      begin
         Tmp := SR1;

         if (Tmp and Uint32 (2 ** I2C_SR1_AF)) /= 0 then
            SR1 := Tmp and not (Uint32 (2 ** I2C_SR1_AF));
         end if;

         if (Tmp and Uint32 (2 ** I2C_SR1_STOPF)) /= 0 then
            Tmp := SR1;
            CR1 := CR1;
         end if;

         if (Tmp and Uint32 (2 ** I2C_SR1_BERR)) /= 0 then
            SR1 := Tmp and not (Uint32 (2 ** I2C_SR1_BERR));
         end if;

         if (Tmp and Uint32 (2 ** I2C_SR1_ARLO)) /= 0 then
            SR1 := Tmp and not (Uint32 (2 ** I2C_SR1_ARLO));
         end if;

         if (Tmp and Uint32 (2 ** I2C_SR1_OVR)) /= 0 then
            Tmp := SR1;
            Tmp := DR;
         end if;
      end Clear_Errors;


      function Wait_Flag (Flag_Mask  : Uint32;
                          Timeout_MS : Positive) return Boolean is
         Deadline : constant Time := Clock + Milliseconds (Timeout_MS);
      begin
         loop
            if (SR1 and Flag_Mask) /= 0 then
               return True;
            end if;
            if (SR1 and Uint32 (2 ** I2C_SR1_AF)) /= 0 then
               SR1 := SR1 and not (Uint32 (2 ** I2C_SR1_AF));
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
            if (SR1 and Uint32 (2 ** I2C_SR1_BERR)) /= 0 then
               SR1 := SR1 and not (Uint32 (2 ** I2C_SR1_BERR));
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
            if (SR1 and Uint32 (2 ** I2C_SR1_ARLO)) /= 0 then
               SR1 := SR1 and not (Uint32 (2 ** I2C_SR1_ARLO));
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
            if Clock > Deadline then
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
         end loop;
      end Wait_Flag;


      function Write (SlaveAddr : Uint8;
                      Data      : Uint8) return Boolean is
         Status : Uint32 with Volatile;
      begin
         CR1 := CR1 or Uint32 (2 ** I2C_CR1_START);

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_SB), 100) then
              Send_Line ("FAIL: SB timeout");
            return False;
         end if;

         DR := Uint32 (SlaveAddr) * 2;  -- 7-bit addr, R/W=0

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_ADDR), 100) then
              Send_Line ("FAIL: ADDR timeout");
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         Status := SR1;
         Status := SR2;

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_TXE), 100) then
              Send_Line ("FAIL: TXE timeout");
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         DR := Uint32 (Data);

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_BTF), 100) then
              Send_Line ("FAIL: BTF timeout");
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
         return True;
      end Write;


      function Write_Buffer (SlaveAddr : Uint8;
                              Data      : Uint8_Array) return Boolean is
         Status  : Uint32 with Volatile;
         Timeout : Integer;
      begin
         SR1 := SR1
            and not (Uint32 (2 ** I2C_SR1_AF))
            and not (Uint32 (2 ** I2C_SR1_BERR))
            and not (Uint32 (2 ** I2C_SR1_ARLO));
         Status := SR1;
         Status := SR2;

         Timeout := 100;
         while (SR2 and Uint32 (2)) /= 0 loop
            Timeout := Timeout - 1;
            if Timeout = 0 then
                 Send_Line ("FAIL: bus BUSY antes de START");
               return False;
            end if;
         end loop;

         if (CR1 and Uint32 (2 ** I2C_CR1_PE)) = 0 then
              Send_Line ("FAIL: PE no activo");
            return False;
         end if;

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_START);

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_SB), 100) then
              Send_Line ("FAIL: SB timeout");
            return False;
         end if;

         Status := SR1;
         DR     := Uint32 (SlaveAddr) * 2;

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_ADDR), 100) then
            if (SR1 and Uint32 (2 ** I2C_SR1_AF)) /= 0 then
                 Send_Line ("FAIL: NACK en direccion");
               SR1 := SR1 and not (Uint32 (2 ** I2C_SR1_AF));
            else
                 Send_Line ("FAIL: ADDR timeout");
            end if;
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         Status := SR1;
         Status := SR2;

         for Byte of Data loop
            if not Wait_Flag (Uint32 (2 ** I2C_SR1_TXE), 100) then
                 Send_Line ("FAIL: TXE timeout");
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
            if (SR1 and Uint32 (2 ** I2C_SR1_AF)) /= 0 then
                 Send_Line ("FAIL: NACK durante envio");
               SR1 := SR1 and not (Uint32 (2 ** I2C_SR1_AF));
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               return False;
            end if;
            DR := Uint32 (Byte);
         end loop;

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_BTF), 100) then
              Send_Line ("FAIL: BTF timeout");
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
         return True;
      end Write_Buffer;


      -- CORRECCION: para 1 byte, deshabilitar ACK ANTES de limpiar ADDR,
      -- y generar STOP antes de leer DR.
      function Read (SlaveAddr : Uint8;
                     Data      : out Uint8) return Boolean is
         Status : Uint32;
         Time   : constant Positive := 100;
      begin
         CR1 := CR1 or Uint32 (2 ** I2C_CR1_ACK);
         CR1 := CR1 or Uint32 (2 ** I2C_CR1_START);

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_SB), Time) then
            return False;
         end if;

         DR := (Uint32 (SlaveAddr) * 2) or 16#01#;  -- R/W=1

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_ADDR), Time) then
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         -- Para 1 byte: deshabilitar ACK ANTES de limpiar ADDR
         CR1 := CR1 and not (Uint32 (2 ** I2C_CR1_ACK));

         -- Limpiar ADDR (leer SR1 + SR2)
         Status := SR1;
         Status := SR2;

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_RxNE), Time) then
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         -- STOP antes de leer DR (obligatorio para 1 byte en STM32)
         CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
         Data := Uint8 (DR and 16#FF#);

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_ACK);  -- restaurar ACK
         return True;
      end Read;


      -- CORRECCION: logica ACK/NACK del ultimo byte completamente reescrita.
      -- La secuencia correcta para N bytes es:
      --   bytes 1..N-1: leer con ACK activo
      --   byte N:       deshabilitar ACK -> esperar RxNE -> STOP -> leer DR
      function Read_Buffer (SlaveAddr : Uint8;
                             Data      : out Uint8_Array) return Boolean is
         Status : Uint32;
         Time   : constant Positive := 100;
      begin
         if Data'Length = 0 then
            return True;
         end if;

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_ACK);
         CR1 := CR1 or Uint32 (2 ** I2C_CR1_START);

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_SB), Time) then
            return False;
         end if;

         DR := (Uint32 (SlaveAddr) * 2) or 16#01#;  -- R/W=1

         if not Wait_Flag (Uint32 (2 ** I2C_SR1_ADDR), Time) then
            CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
            return False;
         end if;

         -- Caso 1 byte: deshabilitar ACK ANTES de limpiar ADDR
         if Data'Length = 1 then
            CR1 := CR1 and not (Uint32 (2 ** I2C_CR1_ACK));
         end if;

         -- Limpiar ADDR
         Status := SR1;
         Status := SR2;

         for I in Data'Range loop
            if I = Data'Last then
               -- Ultimo byte: deshabilitar ACK (ya hecho si N=1)
               CR1 := CR1 and not (Uint32 (2 ** I2C_CR1_ACK));

               if not Wait_Flag (Uint32 (2 ** I2C_SR1_RxNE), Time) then
                  CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
                  return False;
               end if;

               -- STOP antes de leer DR
               CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
               Data (I) := Uint8 (DR and 16#FF#);
            else
               if not Wait_Flag (Uint32 (2 ** I2C_SR1_RxNE), Time) then
                  CR1 := CR1 or Uint32 (2 ** I2C_CR1_STOP);
                  return False;
               end if;
               Data (I) := Uint8 (DR and 16#FF#);
            end if;
         end loop;

         CR1 := CR1 or Uint32 (2 ** I2C_CR1_ACK);  -- restaurar ACK
         return True;
      end Read_Buffer;

 
 


   --Procedimientos de diagnostico en caso de fallos

procedure Test_Hardware is
   Scl_State, Sda_State : Uint32;
   Scl_Shift, Sda_Shift : Uint32;
begin
     Send_Line ("=== TEST HARDWARE ===");
   
   -- Leer estado actual de los pines usando división por potencias de 2
   -- En lugar de shr, usamos división: (valor / 2**pin) and 1
   Scl_Shift := Uint32(2**SCL_PIN);
   Sda_Shift := Uint32(2**SDA_PIN);
   
   Scl_State := (GPIO_ODR_SCL / Scl_Shift) and 1;
   Sda_State := (GPIO_ODR_SDA / Sda_Shift) and 1;
   
     Send_Line ("Estado actual - SCL=" & Uint32'Image(Scl_State) & 
                    " SDA=" & Uint32'Image(Sda_State));
   
   if Scl_State = 0 then
        Send_Line ("¡ALERTA! SCL está BAJO - posible cortocircuito");
   end if;
   
   if Sda_State = 0 then
        Send_Line ("¡ALERTA! SDA está BAJO - posible cortocircuito");
   end if;
   
   if Scl_State = 1 and Sda_State = 1 then
        Send_Line ("OK: Ambas líneas ALTAS - pull-ups funcionando");
   else
        Send_Line ("ERROR: Pull-ups ausentes, dañados o dispositivo roto");
   end if;
end Test_Hardware;


procedure Scan_I2C_Bus is
   Status : Uint32;
   Found : Boolean := False;
begin
     Send_Line ("=== ESCANEO I2C ===");
   
   for Addr in 0 .. 127 loop
      -- Generar START
      CR1 := CR1 or Uint32(2**I2C_CR1_START);
      
      if Wait_Flag(Uint32(2**I2C_SR1_SB), 10) then
         -- Enviar dirección
         DR := Uint32(Addr) * 2;
         
         if Wait_Flag(Uint32(2**I2C_SR1_ADDR), 10) then
              Send_Line ("Dispositivo encontrado en 0x" & 
                           Uint8'Image(Uint8(Addr)));
            Found := True;
            
            -- Limpiar ADDR
            Status := SR1;
            Status := SR2;
         end if;
      end if;
      
      -- STOP
      CR1 := CR1 or Uint32(2**I2C_CR1_STOP);
      for I in 1 .. 1000 loop null; end loop;
   end loop;
   
   if not Found then
        Send_Line ("NINGÚN dispositivo encontrado - posible:");
        Send_Line ("  1. Dispositivo roto/desconectado");
        Send_Line ("  2. Dirección incorrecta");
        Send_Line ("  3. Sin alimentación en el dispositivo");
        Send_Line ("  4. Pull-ups ausentes");
   end if;
end Scan_I2C_Bus;

procedure Test_Minimo is
   Success : Boolean;
   Dummy_Data : Uint8 := 0;
begin
     Send_Line ("=== TEST MÍNIMO ===");
   
   CR1 := CR1 or Uint32(2**I2C_CR1_START);
   
   if Wait_Flag(Uint32(2**I2C_SR1_SB), 100) then
        Send_Line ("OK: START generado");
      CR1 := CR1 or Uint32(2**I2C_CR1_STOP);
        Send_Line ("OK: STOP generado");
   else
        Send_Line ("FAIL: No se pudo generar START");
        Send_Line ("  -> Bus bloqueado por hardware");
   end if;
end Test_Minimo;

--Mostrar generico funciona bien
   procedure Mostrar_Config  is
      function To_String (V : Uint32) return String is
      begin
         return Long_Long_Integer'Image(Long_Long_Integer(V));
      end To_String;

      function To_String (V : Natural) return String is
      begin
         return Integer'Image(Integer(V));
      end To_String;

   begin
        Send_Line("---- Configuracion I2C ----");
        Send_Line("I2C_Base: " & To_String(I2C_Base));
        Send_Line("SCL_PIN : " & To_String(SCL_PIN));
        Send_Line("SDA_PIN : " & To_String(SDA_PIN));
        Send_Line("GPIO_SCL: " & To_String(GPIO_SCL));
        Send_Line("GPIO_SDA: " & To_String(GPIO_SDA));
        Send_Line("---------------------------");
   end Mostrar_Config;

  end Bus;
end I2C;