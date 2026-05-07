with System;
with USART;        
with USART_Driver; use USART_Driver;
with stm32f446;     use stm32f446;
with Ada.Real_Time; use Ada.Real_Time;
with SPI;           
with SPI_driver; use SPI_driver;
--Pin 11 =PA7=MOSI y 12=PA6=MISO  para Nucleo

procedure Main is
 TX : Uint8 := 16#55#;
   RX : Uint8;
  Next_Time : Time := Clock;

begin 


 
   USART_Driver.Initialize (115200);
   USART_Driver.Send_Line ("USART INICIALIZADO");
   SPI_Driver.Initialize;
   USART_Driver.Send_Line ("SPI INICIALIZADO");
    loop
    RX := SPI_Driver.Transfer_8 (TX);
      if RX = TX then
         USART_Driver.Send_Line ("SPI OK");
      else
         USART_Driver.Send_Line ("SPI ERROR");
      end if;
         Next_Time := Next_Time + Milliseconds (500);
      delay until Next_Time;
   end loop;
end Main;