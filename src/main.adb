
with System;
with USART;use USART;
with Ada.Real_Time; use Ada.Real_Time;
procedure Main is
   
   -- Delay aproximado en milisegundos
   procedure Delay_MS (Milliseconds : Natural) is
   begin
      delay(Milliseconds/1000.0);
--  -/
--       Cycles_Per_MS : constant := 16000;
--       C : Natural;
--    begin
--       for I in 1 .. Milliseconds loop
--          C := 0;
--          while C < Cycles_Per_MS loop
--             C := C + 1;
--          end loop;
--       end loop;
--    -/
   end Delay_MS;
   
   -- LED en PA5
   LED_Port : constant := 16#4002_0000#;  -- GPIOA
   LED_Pin  : constant := 5;
   LED_Mask : constant := 2**LED_Pin;
   
   GPIOA_BSRR : Uint32 with
     Volatile,
     Address => System'To_Address (LED_Port + 16#18#);
   
   procedure LED_On is
   begin
      GPIOA_BSRR := LED_Mask;
   end LED_On;
   
   procedure LED_Off is
   begin
      GPIOA_BSRR := LED_Mask * 2**16;
   end LED_Off;
   
   procedure LED_Toggle is
      GPIOA_ODR : Uint32 with
        Volatile,
        Address => System'To_Address (LED_Port + 16#14#);
   begin
      GPIOA_ODR := GPIOA_ODR xor LED_Mask;
   end LED_Toggle;
   
   Received : Uint8;
   Counter : Integer := 0;
   
begin
   -- Configurar LED como salida
   declare
      GPIOA_MODER : Uint32 with
        Volatile,
        Address => System'To_Address (LED_Port + 16#00#);
   begin
      GPIOA_MODER := GPIOA_MODER and not (3 * 2**(LED_Pin * 2));
      GPIOA_MODER := GPIOA_MODER or (1 * 2**(LED_Pin * 2));  -- 01 = Sal
   end;
   
  
   USART.Initialize (115200);
   
   Delay_MS (100);
   
   
   USART.Send_Line ("");
 
   USART.Send_Line ("");
   USART.Send_Line ("USART2  a 115200 baudios");
   USART.Send_Line ("");
   USART.Send_Line ("Comandos disponibles:");
   USART.Send_Line ("  '1' - LED");
   USART.Send_Line ("  '0' - of LED");
   USART.Send_Line ("  't' - Toggle");
   USART.Send_Line ("  'c' - Mostrar contador");
   USART.Send_Line ("  'h' help");
   USART.Send_Line ("");
   USART.Send_String ("Listo> ");
   
   
   loop
     
      if USART.Data_Available then
         Received := USART.Read_Char;
         USART.Send_Char (Received);
         
      
         case Received is
            when Character'Pos ('1') =>  
               LED_On;
               USART.Send_Line (" LED encendido");
               USART.Send_String ("Listo> ");
                  
            when Character'Pos ('0') => 
               LED_Off;
               USART.Send_Line (" LED apagado");
               USART.Send_String ("Listo> ");
                  
            when Character'Pos ('t') =>  
               LED_Toggle;
               USART.Send_Line (" LED toggle");
               USART.Send_String ("Listo> ");
                  
            when Character'Pos ('c') => 
               Counter := Counter + 1;
               USART.Send_String (" Contador: ");
               
               -- entero string
               declare
                  Num : Integer := Counter;
                  Temp : String (1 .. 10);
                  Len : Integer := 0;
               begin
                  if Num = 0 then
                     USART.Send_String ("0");
                  else
                     while Num > 0 loop
                        Len := Len + 1;
                        Temp (Len) := Character'Val (Character'Pos ('0') + (Num mod 10));
                        Num := Num / 10;
                     end loop;
                     for I in reverse 1 .. Len loop
                        USART.Send_Char (Character'Pos (Temp (I)));
                     end loop;
                  end if;
               end;
               
               USART.Send_Line ("");
               USART.Send_String ("Listo> ");
                  
            when Character'Pos ('h') | Character'Pos ('?') =>  
               USART.Send_Line ("");
               USART.Send_Line ("Comandos:");
               USART.Send_Line ("  1 - Encender LED");
               USART.Send_Line ("  0 - Apagar LED");
               USART.Send_Line ("  t - Toggle LED");
               USART.Send_Line ("  c - Mostrar contador");
               USART.Send_Line ("  h/? - Mostrar ayuda");
               USART.Send_String ("Listo> ");
                  
            when 13 | 10 =>  -- Para hacer salto de linea le ponemos un null
           
               null;
                  
            when others =>
               USART.Send_Line (" comando no reconocido (usa 'h' para ayuda)");
               USART.Send_String ("Listo> ");
         end case;
      end if;
      
      -- Indicar que vive
      LED_On;
      Delay_MS (10);
      LED_Off;
      
      Delay_MS (990);  -- delay
   end loop;
   
end Main;