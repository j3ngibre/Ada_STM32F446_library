--763 
with System;
with stm32f446; use stm32f446;
with USART;
with USART_Driver; use USART_Driver;
with Ada.Real_Time; use Ada.Real_Time;

procedure Main is
   

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
   
  
       Initialize (115200);
   
   Delay_MS (100);
   
   
       Send_Line ("");
 
       Send_Line ("");
       Send_Line ("USART2  a 115200 baudios");
       Send_Line ("");
       Send_Line ("Comandos disponibles:");
       Send_Line ("  '1' - LED");
       Send_Line ("  '0' - of LED");
       Send_Line ("  't' - Toggle");
       Send_Line ("  'c' - Mostrar contador");
       Send_Line ("  'h' help");
       Send_Line ("");
       Send_String ("Listo> ");
   
   
   loop
     
      if     Data_Available then
         Received :=     Read_Char;
             Send_Char (Received);
         
      
         case Received is
            when Character'Pos ('1') =>  
               LED_On;
                   Send_Line (" LED encendido");
                   Send_String ("Listo> ");
                  
            when Character'Pos ('0') => 
               LED_Off;
                   Send_Line (" LED apagado");
                   Send_String ("Listo> ");
                  
            when Character'Pos ('t') =>  
               LED_Toggle;
                   Send_Line (" LED toggle");
                   Send_String ("Listo> ");
                  
            when Character'Pos ('c') => 
               Counter := Counter + 1;
                   Send_String (" Contador: ");
               
               -- entero string
               declare
                  Num : Integer := Counter;
                  Temp : String (1 .. 10);
                  Len : Integer := 0;
               begin
                  if Num = 0 then
                         Send_String ("0");
                  else
                     while Num > 0 loop
                        Len := Len + 1;
                        Temp (Len) := Character'Val (Character'Pos ('0') + (Num mod 10));
                        Num := Num / 10;
                     end loop;
                     for I in reverse 1 .. Len loop
                            Send_Char (Character'Pos (Temp (I)));
                     end loop;
                  end if;
               end;
               
                   Send_Line ("");
                   Send_String ("Listo> ");
                  
            when Character'Pos ('h') | Character'Pos ('?') =>  
                   Send_Line ("");
                   Send_Line ("Comandos:");
                   Send_Line ("  1 - Encender LED");
                   Send_Line ("  0 - Apagar LED");
                   Send_Line ("  t - Toggle LED");
                   Send_Line ("  c - Mostrar contador");
                   Send_Line ("  h/? - Mostrar ayuda");
                   Send_String ("Listo> ");
                  
            when 13 | 10 =>  -- Para hacer salto de linea le ponemos un null
           
               null;
                  
            when others =>
                   Send_Line (" comando no reconocido (usa 'h' para ayuda)");
                   Send_String ("Listo> ");
         end case;
      end if;
      
      -- Indicar que vive
      LED_On;
      Delay_MS (10);
      LED_Off;
      
      Delay_MS (990);  -- delay
   end loop;
   
end Main;