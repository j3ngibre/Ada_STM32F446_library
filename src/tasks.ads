
with Ada.Real_Time; use Ada.Real_Time;

package Tasks is

   task Blink with
     Storage_Size => 4096 is
      entry Stop;
   end Blink;

   task Heartbeat with
     Storage_Size => 4096;

end Tasks;