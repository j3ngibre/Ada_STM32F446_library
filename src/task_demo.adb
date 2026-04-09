with Tasks;
with Ada.Real_Time; use Ada.Real_Time;

procedure Main is
begin
   delay until Clock + Milliseconds (3000);
   Tasks.Blink.Stop;  
end Main;