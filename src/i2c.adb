
with System;
with Ada.Real_Time; use Ada.Real_Time;
with stm32f446;use stm32f446;
with I2C; use I2C;
with USART; use USART;

-- -/
   ---------------------------------------------------------------------------
--  I2c1
--   Registro	Campo	Valor	Cálculo
-- I2C_CR2	FREQ	42	PCLK1 en MHz
-- I2C_CCR	CCR	210	42MHz/(2×100kHz)
-- I2C_CCR	FS	0	Standard-mode
-- I2C_CCR	DUTY	0	No usado en Sm
-- I2C_TRISE	TRISE	43	(1000ns/23.8ns)+1
   ---------------------------------------------------------------------------
-- -/
package body I2C is

   procedure Initialize is
   
   begin
      
      -- A Habilitar relojes: GPIOB (para PB8/PB9) 
      RCC_AHB1ENR := RCC_AHB1ENR or 2#10#; --Habilitar gpiob
      RCC_APB1ENR := RCC_APB1ENR  or Uint32(2**21);-- Habilitar i2c1 si fuese la 2 22 , 3 23
     --PRimero hay que limpiar los anteriores es decir 16 y 18 

      GPIOB_MODER:= GPIOB_MODER and not(Uint32(2**16)) and not(Uint32(2**18));
      GPIOB_MODER:= GPIOB_MODER or Uint32(2**17) or Uint32(2**19);--Posición de scl y sda  17 pb8  scl y 19 pb9  sda

      GPIOB_AFRH:= (GPIOB_AFRH  and (not (2#1111# )) and (not( 2#1111#*2**4)))  or 16#04# or Uint32(2**6);--  0100 para pb8 y 0100_0000 para pb9 = 0100 0100
      GPIOB_OTYPER:= GPIOB_OTYPER or Uint32(2**8) or Uint32(2**9); -- lo ponemos en modo opendrain
      GPIOB_PUPDR := GPIOB_PUPDR or Uint32(2**16) or Uint32(2**18); --  Poner pull up  10 es pulldown 
      GPIOB_OSPEEDR:= GPIOB_OSPEEDR or Uint32(2**17) or Uint32(2**19); -- fast pero no very fst podemos cambiar a medium tmabien 
         --B Reset del periferico
      I2C_CR1A:= I2C_CR1A or Uint32(2**I2C_CR1_SWRST );
      I2C_CR1A:= I2C_CR1A and  (not(Uint32(2**I2C_CR1_SWRST )));
    

      --Limpia  y ponemos freq - reloj periferico
      I2C_CR2A:= I2C_CR2A   and 16#FFFFFFC0#;
      I2C_CR2A:= I2C_CR2A or Uint32(42);
  
     
    
      
      I2C_CCRA := (I2C_CCRA and not(Uint32(2**I2C_CCR_DUTY)) 
      and not(Uint32(2**I2C_CCR_FS))) 
      or Uint32(210);
        --esto es la mascara de fast mode =0 but 15 yel duty q 0 pq es para fast mode
        --210 =  PCLK1 = 42mhz / 2*100 i2cspeed sm = 100khz  es el valor de CCR

--    -/
-- Ahora viene trise para calcularlo hay que calcular el periodo qeue es la 1/PCLk para 42mhz = 23.8095
--  TRISE= trunc(max rise time /tpclk) +1 segun  datasheet 1000ns
-- 42+1
--    -/

    I2C_TRISEA:=I2C_TRISEA or Uint32(43);
    --HAbilitamos periferico como acto final 

    I2C_CR1A:= I2C_CR1A or Uint32(2**I2C_CR1_PE);

   end Initialize;



 procedure Clear_Errors is
   Tmp : Uint32;
begin
   -- 1. Leer SR1 para capturar estado actual
   Tmp := I2C_SR1A;
   
   -- 2. Limpiar AF (Acknowledge Failure): leer SR2
   if (Tmp and (2**I2C_SR1_AF)) /= 0 then
      Tmp := I2C_SR2A;  -- Leer SR2 limpia AF
   end if;
   
   -- 3. Limpiar STOPF: leer SR1 y luego escribir CR1
   if (Tmp and (2**I2C_SR1_STOPF)) /= 0 then
      Tmp := I2C_SR1A;     
      I2C_CR1A := I2C_CR1A;  
   end if;
   
   -- 4. Limpiar BERR: leer SR1 y luego escribir CR1
   if (Tmp and (2**I2C_SR1_BERR)) /= 0 then
      Tmp := I2C_SR1A;-- Escribir CR1 limpia BERR
   end if;
   
   -- 5. Limpiar ARLO: leer SR1 y luego escribir CR1
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



 function Wait_Flag (Flag_Mask : Uint32; Timeout_MS : Positive) return Boolean is
        Deadline : constant Time := Clock + Milliseconds (Timeout_MS);
    begin
        while (I2C_SR1A and Flag_Mask) = 0 loop
            if (I2C_SR1A and (2**I2C_SR1_AF)) /= 0 then --acknown failure
                Clear_Errors;
               I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
                return False;
            end if;
            if Clock > Deadline then
             I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
                return False;
            end if;
            delay 0.0001;  -- Pequeña pausa
        end loop;
        return True;
    end Wait_Flag;



 function I2C_Write  (SlaveAddr : Uint8;
                        Data : Uint8) return Boolean is
   Status : Uint32;
begin
   --  Generar condición START
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START );
   
   --  Esperar flag SB (Start Bit) con timeout
  if not Wait_Flag (Uint32(2**I2C_SR1_SB), 100) then
      return False;  
      
   end if;
   
   --  Enviar dirección del esclavo (modo escritura)
   -- Dirección de 7 bits se desplaza y bit 0 = 0 para escritura
   I2C_DRA := Uint32(SlaveAddr * 2) and 16#FE#;
   
   --  Esperar flag ADDR (dirección enviada) con timeout
  if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), 100) then
 
      return False;  
   end if;
   --  Limpiar flag ADDR (leyendo SR1 y SR2)
   Status := I2C_SR1A;  -- Leer SR1
   Status := I2C_SR2A;  -- Leer SR2 (limpia ADDR automáticamente)
   
   --  Enviar dato
   I2C_DRA := Uint32(Data);
   
   --  Esperar flag TxE (Transmit empty) con timeout
 if not Wait_Flag (Uint32(2**I2C_SR1_TxE), 100) then

      return False;  
   end if;
   
   --  Esperar flag BTF (Byte Transfer Finished) opcional  pero te aseguras tansmision completa

 if not Wait_Flag (Uint32(2**I2C_SR1_BTF), 100) then
 
      return False;  
   end if;
   
   
   --  Generar condición STOP
   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
   
   return True; 
end I2C_Write;





function I2C_WriteBuffer (SlaveAddr : Uint8; 
                          Data : Uint8_Array) return Boolean is
   Status : Uint32;
begin

   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);
   
   
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), 100) then
      return False;
   end if;
    

   I2C_DRA := Uint32(SlaveAddr * 2) and 16#FE#;
   
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), 100) then
      return False;
   end if;
   USART.Send_Line ("NO start bit");
 
   Status := I2C_SR1A;
   Status := I2C_SR2A;
   
 
   for I in Data'Range loop
      I2C_DRA := Uint32(Data(I));
      if I < Data'Last then
         if not Wait_Flag (Uint32(2**I2C_SR1_TxE), 100) then
            I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
            return False;
         end if;
      end if;
   end loop;
    USART.Send_Line ("No 2 bit");
   if not Wait_Flag (Uint32(2**I2C_SR1_BTF), 100) then
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
      -- Si es el último byte, debemos generar NACK y STOP
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
end I2C;