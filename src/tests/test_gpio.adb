with GPIO;    use GPIO;
with stm32f446; use stm32f446;
with Ada.Real_Time; use Ada.Real_Time;

procedure Main is

   LED : constant GPIO_Point := (Port => PORT_A, Pin => 9); --Corresponde a D8 en nucleo
   In_Pin : constant GPIO_Point := (Port => PORT_A, Pin => 8);--Corresponde a D7 en nucleo

begin

   Config_Output (LED);
   Config_Input(In_Pin , Pull_Down); -- para que no se quede floating
loop
   if Read(In_Pin) then 
      Set (LED);
      delay(1.0);
      Clear (LED);
      delay(1.0);
      Toggle (LED);
      delay(1.0);
      Clear (LED);
   end if;
end loop;




end Main;