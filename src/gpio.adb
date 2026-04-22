with stm32f446; use stm32f446;
with System;
with System.Storage_Elements;  use System.Storage_Elements;
with System.Address_To_Access_Conversions;

package body GPIO is

  --conversion de punteros
   package Conv is new System.Address_To_Access_Conversions (Uint32);


function Bit (N : Natural) return Uint32 is
begin
   if N > 31 then
      raise Constraint_Error;
   end if;
   
   return Uint32 (2 ** N);
end Bit;


--aux pq error
   function Bit2_Mask (N : Natural) return Uint32 is
   begin
      return Uint32 (3) * Uint32 (2 ** (2 * N));
   end Bit2_Mask;

   --  Valor V colocado en el campo de 2 bits en posición N
   function Bit2_Val (N : Natural; V : Uint32) return Uint32 is
   begin
      return (V and 3) * Uint32 (2 ** (2 * N));
   end Bit2_Val;


   function Port_Base (P : GPIO_Port) return Storage_Offset is
   begin
      case P is
         when PORT_A => return Storage_Offset (GPIOA);
         when PORT_B => return Storage_Offset (GPIOB);
         when PORT_C => return Storage_Offset (GPIOC);
         when PORT_D => return Storage_Offset (GPIOD);
         when PORT_E => return Storage_Offset (GPIOE);
         when PORT_F => return Storage_Offset (GPIOF);
         when PORT_G => return Storage_Offset (GPIOG);
         when PORT_H => return Storage_Offset (GPIOH);
      end case;
   end Port_Base;

 

   function Reg (Base   : Storage_Offset;
                 Offset : Storage_Offset) return access Uint32 is
   begin
      return Conv.To_Pointer (System'To_Address (Base + Offset));
   end Reg;

   function MODER (P : GPIO_Port) return access Uint32 is
   begin
      return Reg (Port_Base (P), Storage_Offset (GPIO_MODER_Offset));
   end MODER;

   function PUPDR (P : GPIO_Port) return access Uint32 is
   begin
      return Reg (Port_Base (P), Storage_Offset (GPIO_PUPDR_Offset));
   end PUPDR;

   function ODR (P : GPIO_Port) return access Uint32 is
   begin
      return Reg (Port_Base (P), Storage_Offset (GPIO_ODR_Offset));
   end ODR;

   function IDR (P : GPIO_Port) return access Uint32 is
   begin
      return Reg (Port_Base (P), Storage_Offset (GPIO_IDR_Offset));
   end IDR;

   function BSRR (P : GPIO_Port) return access Uint32 is
   begin
      return Reg (Port_Base (P), Storage_Offset (GPIO_BSRR_Offset));
   end BSRR;

  

   procedure Enable_Clock (P : GPIO_Port) is
   begin
      case P is
         when PORT_A => RCC_AHB1ENR := RCC_AHB1ENR or Bit (0);
         when PORT_B => RCC_AHB1ENR := RCC_AHB1ENR or Bit (1);
         when PORT_C => RCC_AHB1ENR := RCC_AHB1ENR or Bit (2);
         when PORT_D => RCC_AHB1ENR := RCC_AHB1ENR or Bit (3);
         when PORT_E => RCC_AHB1ENR := RCC_AHB1ENR or Bit (4);
         when PORT_F => RCC_AHB1ENR := RCC_AHB1ENR or Bit (5);
         when PORT_G => RCC_AHB1ENR := RCC_AHB1ENR or Bit (6);
         when PORT_H => RCC_AHB1ENR := RCC_AHB1ENR or Bit (7);
      end case;
   end Enable_Clock;



   procedure Config_Output (GPIO_P : GPIO_Point) is
      P   : constant GPIO_Port := GPIO_P.Port;
      Pin : constant Natural   := GPIO_P.Pin;
   begin
      Enable_Clock (P);
      MODER (P).all :=
        (MODER (P).all and not Bit2_Mask (Pin))
        or Bit2_Val (Pin, 1);
   end Config_Output;


 procedure Config_Analog (GPIO_P : GPIO_Point ;Pull:GPIO_Pull:=No_Pull) is
      P   : constant GPIO_Port := GPIO_P.Port;
      Pin : constant Natural   := GPIO_P.Pin;
       Val : Uint32;
   begin
      Enable_Clock (P);
      MODER (P).all :=
        (MODER (P).all and not Bit2_Mask (Pin))
        or Bit2_Val (Pin, 3);

         case Pull is
         when No_Pull   => Val := Bit2_Val (Pin, 0);
         when Pull_Up   => Val := Bit2_Val (Pin, 1);
         when Pull_Down => Val := Bit2_Val (Pin, 2);
      end case;
      PUPDR (P).all :=
        (PUPDR (P).all and not Bit2_Mask (Pin)) or Val;

   end Config_Analog;


   procedure Config_Input (GPIO_P : GPIO_Point;
                           Pull   : GPIO_Pull := No_Pull) is
      P   : constant GPIO_Port := GPIO_P.Port;
      Pin : constant Natural   := GPIO_P.Pin;
      Val : Uint32;
   begin
      Enable_Clock (P);

     
      MODER (P).all := MODER (P).all and not Bit2_Mask (Pin);

  
      case Pull is
         when No_Pull   => Val := Bit2_Val (Pin, 0);
         when Pull_Up   => Val := Bit2_Val (Pin, 1);
         when Pull_Down => Val := Bit2_Val (Pin, 2);
      end case;
      PUPDR (P).all :=
        (PUPDR (P).all and not Bit2_Mask (Pin)) or Val;
   end Config_Input;


   procedure Set (GPIO_P : GPIO_Point) is
   begin
      BSRR (GPIO_P.Port).all := 2**GPIO_P.Pin;
   end Set;

  

   procedure Clear (GPIO_P : GPIO_Point) is
   begin
      BSRR (GPIO_P.Port).all := 2**(GPIO_P.Pin+16);
   end Clear;

 

   procedure Toggle (GPIO_P : GPIO_Point) is
   begin
      if (ODR (GPIO_P.Port).all and Bit (GPIO_P.Pin)) /= 0 then
         Clear (GPIO_P);
      else
         Set (GPIO_P);
      end if;
   end Toggle;


   function Read (GPIO_P : GPIO_Point) return Boolean is
   begin
      return (IDR (GPIO_P.Port).all and Bit (GPIO_P.Pin)) /= 0;
   end Read;

end GPIO;