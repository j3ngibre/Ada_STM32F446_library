with stm32f446;                       use stm32f446;
with System;
with System.Storage_Elements;         use System.Storage_Elements;
with System.Address_To_Access_Conversions;

package body ADC is

   package Conv is new System.Address_To_Access_Conversions (Uint32);

   ----------------------------------------
   -- Bit helpers
   ----------------------------------------

   Bit_Table : constant array (0 .. 31) of Uint32 :=
     (0  => 16#0000_0001#, 1  => 16#0000_0002#,
      2  => 16#0000_0004#, 3  => 16#0000_0008#,
      4  => 16#0000_0010#, 5  => 16#0000_0020#,
      6  => 16#0000_0040#, 7  => 16#0000_0080#,
      8  => 16#0000_0100#, 9  => 16#0000_0200#,
      10 => 16#0000_0400#, 11 => 16#0000_0800#,
      12 => 16#0000_1000#, 13 => 16#0000_2000#,
      14 => 16#0000_4000#, 15 => 16#0000_8000#,
      16 => 16#0001_0000#, 17 => 16#0002_0000#,
      18 => 16#0004_0000#, 19 => 16#0008_0000#,
      20 => 16#0010_0000#, 21 => 16#0020_0000#,
      22 => 16#0040_0000#, 23 => 16#0080_0000#,
      24 => 16#0100_0000#, 25 => 16#0200_0000#,
      26 => 16#0400_0000#, 27 => 16#0800_0000#,
      28 => 16#1000_0000#, 29 => 16#2000_0000#,
      30 => 16#4000_0000#, 31 => 16#8000_0000#);

   function Bit (N : Natural) return Uint32 is
   begin
      return Bit_Table (N);
   end Bit;

   ----------------------------------------
   -- Acceso a registros
   ----------------------------------------

   function Reg (Base   : Storage_Offset;
                 Offset : Storage_Offset) return access Uint32 is
   begin
      return Conv.To_Pointer (System'To_Address (Base + Offset));
   end Reg;

   function ADC_Base (A : ADC_Instance) return Storage_Offset is
   begin
      case A is
         when ADC_1 => return Storage_Offset (ADC1_Base);
         when ADC_2 => return Storage_Offset (ADC2_Base);
         when ADC_3 => return Storage_Offset (ADC3_Base);
      end case;
   end ADC_Base;

   function SR    (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_SR_Offset));    end SR;
   function CR1   (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_CR1_Offset));   end CR1;
   function CR2   (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_CR2_Offset));   end CR2;
   function SMPR1 (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_SMPR1_Offset)); end SMPR1;
   function SMPR2 (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_SMPR2_Offset)); end SMPR2;
   function SQR1  (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_SQR1_Offset));  end SQR1;
   function SQR3  (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_SQR3_Offset));  end SQR3;
   function DR    (A : ADC_Instance) return access Uint32 is
   begin return Reg (ADC_Base (A), Storage_Offset (ADC_DR_Offset));    end DR;

   --  Registro CCR del ADC Common (Vrefint, Tsensor, Vbat)
   function CCR return access Uint32 is
   begin
      return Reg (Storage_Offset (ADC_Common_Registers),
                  Storage_Offset (ADC_CCR_Offset));
   end CCR;

   ----------------------------------------
   -- Enable Clock APB2
   ----------------------------------------

   procedure Enable_ADC_Clock (A : ADC_Instance) is
      RCC_APB2ENR : constant access Uint32 :=
        Reg (Storage_Offset (RCC), Storage_Offset (APB2ENR_A));
   begin
      case A is
         when ADC_1 => RCC_APB2ENR.all := RCC_APB2ENR.all or Bit (ADC1EN);
         when ADC_2 => RCC_APB2ENR.all := RCC_APB2ENR.all or Bit (ADC2EN);
         when ADC_3 => RCC_APB2ENR.all := RCC_APB2ENR.all or Bit (ADC3EN);
      end case;
   end Enable_ADC_Clock;



   procedure Set_Sample_Time (A : ADC_Instance; Ch : ADC_Channel) is
      Val   : constant Uint32 := 7;   -- 111b = 480 cycles
      Shift : Natural;
      Mask  : Uint32;
   begin
      if Ch <= 9 then
         Shift := Ch * 3;
         Mask  := Bit (Shift) or Bit (Shift + 1) or Bit (Shift + 2);
         SMPR2 (A).all := (SMPR2 (A).all and not Mask)
                          or (Val * Bit (Shift));
      else
         Shift := (Ch - 10) * 3;
         Mask  := Bit (Shift) or Bit (Shift + 1) or Bit (Shift + 2);
         SMPR1 (A).all := (SMPR1 (A).all and not Mask)
                          or (Val * Bit (Shift));
      end if;
   end Set_Sample_Time;

   ----------------------------------------
   -- Seleccionar canal en SQR3
   ----------------------------------------

   procedure Set_Channel (A : ADC_Instance; Ch : ADC_Channel) is
      Ch_Mask : constant Uint32 :=
        Bit (0) or Bit (1) or Bit (2) or Bit (3) or Bit (4);
   begin
      Set_Sample_Time (A, Ch);
      SQR3 (A).all := (SQR3 (A).all and not Ch_Mask) or Uint32 (Ch);
   end Set_Channel;

   ----------------------------------------
   -- Init
   ----------------------------------------

   procedure Init (ADC  : ADC_Instance;
                   Res  : ADC_Resolution := Res_12bit;
                   Align: ADC_Alignment  := Right;
                   Mode : ADC_Mode       := Single) is
      Res_Val : Uint32;
   begin
      Enable_ADC_Clock (ADC);

      --  Apagar ADC
      CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_ADON);

      --  CR1: resolución, scan off
      case Res is
         when Res_12bit => Res_Val := 0;
         when Res_10bit => Res_Val := 1;
         when Res_8bit  => Res_Val := 2;
         when Res_6bit  => Res_Val := 3;
      end case;

      CR1 (ADC).all :=
        (CR1 (ADC).all
           and not (Bit (ADC_CR1_RES) or Bit (ADC_CR1_RES + 1))
           and not Bit (ADC_CR1_SCAN))
        or (Res_Val * Bit (ADC_CR1_RES));

      --  CR2: alineación
      if Align = Left then
         CR2 (ADC).all := CR2 (ADC).all or  Bit (ADC_CR2_ALIGN);
      else
         CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_ALIGN);
      end if;

      --  CR2: modo continuo o single
      if Mode = Continuous then
         CR2 (ADC).all := CR2 (ADC).all or  Bit (ADC_CR2_CONT);
      else
         CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_CONT);
      end if;

      CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_DMA);

      --  SQR1: L=0 → 1 conversión en secuencia
      SQR1 (ADC).all :=
        SQR1 (ADC).all
        and not (Bit (20) or Bit (21) or Bit (22) or Bit (23));

      --  Encender ADC
      CR2 (ADC).all := CR2 (ADC).all or Bit (ADC_CR2_ADON);

      --  Esperar estabilización
      for I in 1 .. 1000 loop
         null;
      end loop;

   end Init;

   ----------------------------------------
   -- Read — single shot
   ----------------------------------------

   function Read (ADC : ADC_Instance;
                  Ch  : ADC_Channel) return Uint32 is
   begin
      Set_Channel (ADC, Ch);

      --  Limpiar EOC
      SR (ADC).all := SR (ADC).all and not Bit (ADC_SR_EOC);

      --  Disparar
      CR2 (ADC).all := CR2 (ADC).all or Bit (ADC_CR2_SWSTART);

      --  Esperar EOC
      while (SR (ADC).all and Bit (ADC_SR_EOC)) = 0 loop
         null;
      end loop;

      return DR (ADC).all and 16#0FFF#;
   end Read;

   function Read_mV (ADC : ADC_Instance;
                     Ch  : ADC_Channel) return Natural is
      Raw : constant Uint32 := Read (ADC, Ch);
   begin
      return Natural ((Raw * 3300) / 4095);
   end Read_mV;

   ----------------------------------------
   -- Lectura continua
   ----------------------------------------

   procedure Start_Continuous (ADC : ADC_Instance;
                                Ch  : ADC_Channel) is
   begin
      --  Asegurarse de que CONT está activo
      CR2 (ADC).all := CR2 (ADC).all or Bit (ADC_CR2_CONT);

      Set_Channel (ADC, Ch);

      --  Limpiar EOC
      SR (ADC).all := SR (ADC).all and not Bit (ADC_SR_EOC);

      --  Primer disparo — el hardware sigue solo
      CR2 (ADC).all := CR2 (ADC).all or Bit (ADC_CR2_SWSTART);
   end Start_Continuous;

   function Read_Continuous (ADC : ADC_Instance) return Uint32 is
   begin
      --  Devuelve el último valor sin esperar
      --  El caller puede comprobar EOC si quiere dato fresco:
      --    while (SR and EOC) = 0 loop null; end loop;
      return DR (ADC).all and 16#0FFF#;
   end Read_Continuous;

   procedure Stop_Continuous (ADC : ADC_Instance) is
   begin
      --  Quitar CONT y apagar ADC
      CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_CONT);
      CR2 (ADC).all := CR2 (ADC).all and not Bit (ADC_CR2_ADON);
   end Stop_Continuous;

   ----------------------------------------
   -- Sensor de temperatura interno
   -- CCR bit 23 = TSVREFE (habilita Tsensor y Vrefint)
   ----------------------------------------

   CCR_TSVREFE : constant := 23;
   CCR_VBATE   : constant := 22;

   procedure Enable_Temp_Sensor is
   begin
      CCR.all := CCR.all or Bit (CCR_TSVREFE);
      --  Esperar tiempo de arranque del sensor (~10 µs)
      for I in 1 .. 10_000 loop
         null;
      end loop;
   end Enable_Temp_Sensor;

   --  Constantes de calibración del STM32F4 (datasheet tabla 68)
   --  V25   = voltaje a 25°C = 0.76 V
   --  Slope = 2.5 mV/°C (promedio)
   --  Temp  = ((V25 - Vsense) / Avg_slope) + 25
   --
   --  En cuentas ADC (12 bits, Vref=3.3V):
   --  V25_counts  = (760 * 4095) / 3300 = 943
   --  Slope_counts = (2.5 * 4095) / 3300 = 3.1 counts/°C

   function Read_Temperature return Integer is
      Raw     : constant Uint32  := Read (ADC_1, ADC_CH_Temp);
      V25     : constant Integer := 943;    -- cuentas a 25 °C
      Raw_Int : constant Integer := Integer (Raw);
      --  resultado en centésimas: × 100 para evitar float
      --  Temp*100 = ((V25 - Raw) * 100 * 10) / 31 + 2500
      --             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      --             slope = 3.1 counts/°C → ×10 = 31
   begin
      return ((V25 - Raw_Int) * 1000) / 31 + 2500;
   end Read_Temperature;

   ----------------------------------------
   -- Vrefint interna
   -- Canal 17, nominal 1210 mV
   ----------------------------------------

   procedure Enable_Vrefint is
   begin
      CCR.all := CCR.all or Bit (CCR_TSVREFE);
      for I in 1 .. 10_000 loop
         null;
      end loop;
   end Enable_Vrefint;

   function Read_Vrefint_mV return Natural is
      Raw : constant Uint32 := Read (ADC_1, ADC_CH_Vrefint);
   begin
      --  Vrefint_mV = (Raw * Vref_supply) / 4095
      --  Vref_supply = 3300 mV
      return Natural ((Raw * 3300) / 4095);
   end Read_Vrefint_mV;

end ADC;