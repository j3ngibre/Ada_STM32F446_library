with System;
with USART;         use USART;
with Ada.Real_Time; use Ada.Real_Time;
with SPI;           use SPI;
with stm32f446;     use stm32f446;

procedure Main is

   TX : Uint8 := 16#55#;
   RX : Uint8;

   Next_Time : Time := Clock;

begin

   USART.Initialize (115200);
   USART.Send_Line ("USART INICIALIZADO");

   SPI.Initialize;
   USART.Send_Line ("SPI INICIALIZADO");

   loop

      RX := SPI.Transfer_8 (TX);

      if RX = TX then
         USART.Send_Line ("SPI OK");
      else
         USART.Send_Line ("SPI ERROR");
      end if;

      Next_Time := Next_Time + Milliseconds (500);
      delay until Next_Time;

   end loop;

end Main;