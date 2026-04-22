with stm32f446; use stm32f446;
with GPIO;      use GPIO;
with ADC;       use ADC;
with USART;            
with USART_Driver; use USART_Driver;
with Ada.Real_Time; use Ada.Real_Time;

procedure Main is



   --  Pines ADC
   PA0 : constant GPIO_Point := (Port => PORT_A, Pin => 0);
   PA1 : constant GPIO_Point := (Port => PORT_A, Pin => 1);

   --  Resultados
   Raw_CH0  : Uint32;
   Raw_CH1  : Uint32;
   mV_CH0   : Natural;
   mV_CH1   : Natural;
   Temp_Raw : Integer;
   Temp_Int : Integer;
   Temp_Dec : Integer;
   Vref_mV  : Natural;



   
   function To_String (V : Integer) return String is
      S      : String (1 .. 12) := (others => ' ');
      Idx    : Integer := 12;
      Val    : Integer := V;
      Neg    : Boolean := Val < 0;
   begin
      if Val = 0 then
         return "0";
      end if;
      if Neg then Val := -Val; end if;
      while Val > 0 loop
         S (Idx) := Character'Val (Character'Pos ('0') + Val mod 10);
         Idx := Idx - 1;
         Val := Val / 10;
      end loop;
      if Neg then
         S (Idx) := '-';
         Idx := Idx - 1;
      end if;
      return S (Idx + 1 .. 12);
   end To_String;

   function To_String (V : Uint32) return String is
   begin
      return To_String (Integer (V));
   end To_String;



begin


-- -/
-- ********************************+
-- 
-- 
-- 
-- 
-- La primera parte de configuracion está mal
-- 
-- 
-- ****************************************
-- 
-- -/
   ----------------------------------------
   --  1. Configurar PA0 y PA1 como entrada analógica
   --     MODER = 11 (analog mode)
   ----------------------------------------
    Initialize (115200);
      Send_Line ("=============================");
      Send_Line ("  STM32F446 ADC Test");
      Send_Line ("  Nucleo-F446RE");
      Send_Line ("=============================");
    delay(0.1);

   Config_Analog (PA0);
   Config_Analog (PA1);

   ----------------------------------------
   --  2. Inicializar ADC1
   ----------------------------------------
   Init (ADC_1, Res_12bit, Right, Single);

   Enable_Temp_Sensor;
   Enable_Vrefint;

 
      Send_Line ("=============================");
      Send_Line ("  STM32F446 ADC Test");
      Send_Line ("  Nucleo-F446RE");
      Send_Line ("=============================");
  delay(0.1);


   loop

  
      Raw_CH0 := Read    (ADC_1, 0);
      mV_CH0  := Read_mV (ADC_1, 0);
         Send_Line ("--- Lectura ADC ---");
         Send_Line ("CH0 (PA0) raw : " & To_String (Raw_CH0));
         Send_Line ("CH0 (PA0) mV  : " & To_String (mV_CH0));

      Raw_CH1 := Read    (ADC_1, 1);
      mV_CH1  := Read_mV (ADC_1, 1);
         Send_Line ("CH1 (PA1) raw : " & To_String (Raw_CH1));
         Send_Line ("CH1 (PA1) mV  : " & To_String (mV_CH1));

      Temp_Raw := Read_Temperature;
      Temp_Int := Temp_Raw / 100;
      Temp_Dec := abs (Temp_Raw mod 100);
         Send_Line ("Temp raw      : " & To_String (Temp_Raw));
         Send_Line ("Temp          : " & To_String (Temp_Int)
                                       & "."
                                       & To_String (Temp_Dec)
                                       & " C");

      Vref_mV := Read_Vrefint_mV;
         Send_Line ("Vrefint       : " & To_String (Vref_mV) & " mV");
         Send_Line ("-----------------------------");

      delay(5.0);
      

   end loop;

end Main;