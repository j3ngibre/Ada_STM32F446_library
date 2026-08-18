with Ada.Real_Time; use Ada.Real_Time;
with GPIO;          use GPIO;
with Shared_Data;   use Shared_Data;
with USART_Driver;  use USART_Driver;

package body Tasks is
   task body Blink_Task is
      Next : Time := Clock;
      LED  : constant GPIO_Point := (Port => PORT_A, Pin => 9);
   begin
      Config_Output (LED);
      loop
         if Shared_Data.Counter.Get = 1 then
            Toggle (LED);
            Next := Clock + Milliseconds (500);
            delay until Next;
         else
            delay until Clock + Milliseconds (1000);
         end if;
         USART_Driver.Send_Line ("LED ON: " & Integer'Image (Shared_Data.Counter.Get));
      end loop;
   end Blink_Task;
end Tasks;