with stm32f446; use stm32f446;
with System;

package GPIO is

   type GPIO_Port is
     (PORT_A, PORT_B, PORT_C, PORT_D,
      PORT_E, PORT_F, PORT_G, PORT_H);

   subtype Pin_Number is Integer range 0 .. 15;

   type GPIO_Point is record
      Port : GPIO_Port;
      Pin  : Pin_Number;
   end record;

   type GPIO_Mode is (Input, Output);

   type GPIO_Pull is (No_Pull, Pull_Up, Pull_Down);

   procedure Config_Output (GPIO_P : GPIO_Point);
   procedure Config_Input  (GPIO_P : GPIO_Point;
                            Pull   : GPIO_Pull := No_Pull);
   procedure Set    (GPIO_P : GPIO_Point);
   procedure Clear  (GPIO_P : GPIO_Point);
   procedure Toggle (GPIO_P : GPIO_Point);
   function  Read   (GPIO_P : GPIO_Point) return Boolean;


    RCC_AHB1ENR : Uint32 with
     Volatile,
     Address => System'To_Address (RCC + AHB1ENR_A);

end GPIO;