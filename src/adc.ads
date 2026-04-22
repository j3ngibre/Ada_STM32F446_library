with stm32f446; use stm32f446;

package ADC is

   subtype ADC_Channel    is Natural range 0 .. 18;
   subtype ADC_Channel_Regular is Natural range 0 .. 16;

   --  Canales especiales internos
   ADC_CH_Temp     : constant ADC_Channel := 18;  -- sensor temperatura
   ADC_CH_Vrefint  : constant ADC_Channel := 17;  -- referencia interna
   ADC_CH_Vbat     : constant ADC_Channel := 18;  -- Vbat (ADC1 solo)

   type ADC_Resolution is
     (Res_12bit,
      Res_10bit,
      Res_8bit,
      Res_6bit);

   type ADC_Alignment is (Right, Left);

   type ADC_Instance is (ADC_1, ADC_2, ADC_3);

   type ADC_Mode is
     (Single,      --  una conversión por disparo
      Continuous);  --  conversión continua automática

   ----------------------------------------
   -- Init
   ----------------------------------------

 
   procedure Init (ADC  : ADC_Instance;
                   Res  : ADC_Resolution := Res_12bit;
                   Align: ADC_Alignment  := Right;
                   Mode : ADC_Mode       := Single);

   ----------------------------------------
   -- Lectura single-shot (bloquea hasta tener dato)
   ----------------------------------------
   function Read      (ADC : ADC_Instance;
                       Ch  : ADC_Channel) return Uint32;

   function Read_mV   (ADC : ADC_Instance;
                       Ch  : ADC_Channel) return Natural;

   ----------------------------------------
   -- Lectura continua
   ----------------------------------------

   --  Arranca la conversión continua en el canal indicado
   procedure Start_Continuous (ADC : ADC_Instance;
                                Ch  : ADC_Channel);

   --  Lee el último valor convertido (no bloquea)
   function  Read_Continuous  (ADC : ADC_Instance) return Uint32;

   --  Para la conversión continua
   procedure Stop_Continuous  (ADC : ADC_Instance);

   ----------------------------------------
   -- Sensor de temperatura interno
   ----------------------------------------

   --  Activa el sensor de temperatura (solo ADC1)
   procedure Enable_Temp_Sensor;

   --  Lee temperatura en centésimas de grado (ej: 2534 = 25.34 °C)
   function Read_Temperature return Integer;

   ----------------------------------------
   -- Referencia de voltaje interna (Vrefint)
   ----------------------------------------

   --  Activa Vrefint (solo ADC1)
   procedure Enable_Vrefint;

   --  Lee Vrefint en mV (nominal 1210 mV)
   function Read_Vrefint_mV return Natural;

end ADC;