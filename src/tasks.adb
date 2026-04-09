with Ada.Real_Time; use Ada.Real_Time;

package body Tasks is

   task body Blink is
      Period  : constant Time_Span := Milliseconds (500);
      Next    : Time := Clock;
      Running : Boolean := True;
   begin
      while Running loop
         select
            accept Stop do
               Running := False;
            end Stop;
         or
            delay until Next;
            Next := Next + Period;
         end select;
      end loop;
   end Blink;

   task body Heartbeat is
      Period : constant Time_Span := Milliseconds (1000);
      Next   : Time := Clock;
   begin
      loop
         Next := Next + Period;
         delay until Next;
      end loop;
   end Heartbeat;

end Tasks;