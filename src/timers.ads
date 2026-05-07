with System;
with stm32f446; use stm32f446;

generic
   Timer_Base : Uint32;
   Timer_Name : String;  -- Para diagnóstico: "TIM2", "TIM3", etc.
package Timers is

   type Timer_Mode is (One_Shot, Periodic);
   type Timer_Prescaler is range 0 .. 65535;
   type Timer_Period is range 0 .. 4294967295;  -- 32 bits máximo para TIM2-TIM5

   protected Timer is
      procedure Initialize;
      
      procedure Start;
      procedure Stop;
      procedure Reset;
      
      procedure Set_Prescaler (Prescaler : Timer_Prescaler);
      procedure Set_Period (Period : Timer_Period);
      procedure Set_Mode (Mode : Timer_Mode);
      
      function Get_Counter return Uint32;
      function Get_Prescaler return Uint32;
      function Get_Period return Uint32;
      function Is_Running return Boolean;
      function Has_Elapsed return Boolean;
      
      -- Callback cuando el timer expira
      procedure Set_Callback (Callback : access procedure);
      procedure Clear_Callback;
      
      -- Diagnóstico
      procedure Diagnosticar_Timer;
      
   private
      Initialized : Boolean := False;
      Running : Boolean := False;
      Timer_Callback : access procedure := null;
   end Timer;
   
   -- Funciones auxiliares fuera del objeto protegido
   function Timer_To_APB1_Bit (Base : Uint32) return Uint32;
   function Timer_To_APB2_Bit (Base : Uint32) return Uint32;

   -- Nombres de registros según el timer
   function Get_CR1_Offset return Uint32;
   function Get_CR2_Offset return Uint32;
   function Get_SMCR_Offset return Uint32;
   function Get_DIER_Offset return Uint32;
   function Get_SR_Offset return Uint32;
   function Get_EGR_Offset return Uint32;
   function Get_CCMR1_Offset return Uint32;
   function Get_CCMR2_Offset return Uint32;
   function Get_CCER_Offset return Uint32;
   function Get_CNT_Offset return Uint32;
   function Get_PSC_Offset return Uint32;
   function Get_ARR_Offset return Uint32;
   function Get_RCR_Offset return Uint32;
   function Get_CCR1_Offset return Uint32;
   function Get_CCR2_Offset return Uint32;
   function Get_CCR3_Offset return Uint32;
   function Get_CCR4_Offset return Uint32;
   function Get_BDTR_Offset return Uint32;
   function Get_DCR_Offset return Uint32;
   function Get_DMAR_Offset return Uint32;

   -- Registros del timer
   TIM_CR1 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CR1_Offset);

   TIM_CR2 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CR2_Offset);

   TIM_SMCR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_SMCR_Offset);

   TIM_DIER : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_DIER_Offset);

   TIM_SR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_SR_Offset);

   TIM_EGR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_EGR_Offset);

   TIM_CCMR1 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCMR1_Offset);

   TIM_CCMR2 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCMR2_Offset);

   TIM_CCER : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCER_Offset);

   TIM_CNT : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CNT_Offset);

   TIM_PSC : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_PSC_Offset);

   TIM_ARR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_ARR_Offset);

   TIM_RCR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_RCR_Offset);

   TIM_CCR1 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCR1_Offset);

   TIM_CCR2 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCR2_Offset);

   TIM_CCR3 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCR3_Offset);

   TIM_CCR4 : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_CCR4_Offset);

   TIM_BDTR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_BDTR_Offset);

   TIM_DCR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_DCR_Offset);

   TIM_DMAR : Uint32 with
     Volatile,
     Address => System'To_Address (Timer_Base + Get_DMAR_Offset);


  

   PCLK1_MHz : constant := 42;    
   PCLK2_MHz : constant := 84;    

private
  --Tim 6,7 son basic , tim 1,8  advance control , tim9-14 generar purpose 16bits 2 camañes , tim2,5  32 bits 4 canales general puerpose,tim3,4 general purpose 16bits 4 canales
TIM_CR1_Offset   : constant := 16#00#;
   TIM_CR1_CEN  : constant := 0;  
   TIM_CR1_UDIS : constant := 1;   
   TIM_CR1_URS  : constant := 2;   
   TIM_CR1_OPM  : constant := 3;   
   TIM_CR1_DIR  : constant := 4;   
   TIM_CR1_CMS  : constant := 5;   
   TIM_CR1_ARPE : constant := 7;                               
   TIM_CR1_CKD  : constant := 8;   
TIM_CR2_Offset   : constant := 16#04#;
   TIM_CCPC:constant:=0;
   TIM_CCUS:constant:=2;
   TIM_CCDS:constant:=3;
   TIM_CR2_MMS:constant:=4; --4-6
   TIM_TI1S:constant:=7;
   TIM_OIS1:constant:=8;
    TIM_OIS1N:constant:=9;
   TIM_OIS2:constant:=10;
   TIM_OIS2N:constant:=11;
   TIM_OIS3:constant:=12;
   TIM_OIS3N:constant:=13;
   TIM_OIS4:constant:=14;
  --15 reserved
TIM_SMCR_offset:constant:= 16#08#;
   TIM_SMS:constant:=0;
TIM_TS:constant:=4;
TIM_MSM:constant:=7;
TIM_ETF:constant:=8;
TIM_ETPS:constant:=12;
TIM_ECE:constant:=14;
TIM_ETP:constant:=15;

TIM_DIER_Offset  : constant := 16#0C#;
   TIM_DIER_UIE : constant := 0;  
   TIM_DIER_CC1IE : constant := 1; 
   TIM_DIER_CC2IE : constant := 2;
   TIM_DIER_CC3IE : constant := 3;
   TIM_DIER_CC4IE : constant := 4;
    TIM_DIER_COMIE : constant := 5;
   TIM_DIER_TIE  : constant := 6; 
     TIM_DIER_BIE  : constant := 7; 
   TIM_DIER_UDE:constant:=8;
   TIM_DIER_CC1DE:constant:=9;
   TIM_DIER_CC2DE:constant:=10;
   TIM_DIER_CC3DE:constant:=11;
   TIM_DIER_CC4DE:constant:=12;
   TIM_DIER_COMDE:constant:=13;
    TIM_DIER_TDE:constant:=14;
 TIM_SR_Offset    : constant := 16#10#;
   TIM_SR_UIF   : constant := 0;  
   TIM_SR_CC1IF : constant := 1;  
   TIM_SR_CC2IF : constant := 2;
   TIM_SR_CC3IF : constant := 3;
   TIM_SR_CC4IF : constant := 4;
   TIM_SR_COMIF:constant:=5;
   TIM_SR_TIF   : constant := 6; 
   TIM_SR_BIF:constant:=7;
   TIM_CC1OF:constant:=9;
   TIM_CC2OF:constant:=10;
   TIM_CC3OF:constant:=11;
   TIM_CC4OF:constant:=12;
TIM_EGR_Offset   : constant := 16#14#;
   TIM_EGR_UG : constant := 0;  
   TIM_EGR_CC1G:constant:=1;
   TIM_EGR_CC2G:constant:=2;
   TIM_EGR_CC3G:constant:=3;
   TIM_EGR_CC4G:constant:=4;
   TIM_EGR_COMG:constant:=5;
   TIM_EGR_TG:constant:=6;
   TIM_EGR_BG:constant:=7;
  

    TIM_CCMR1_Offset : constant := 16#18#;--es un registro que segun el valor de cc1s tiene distinto funcionamiento
     TIM_CCMR1_CC1S:constant:=0;
      TIM_CCMR1_OC1_FE:constant:=2;
      TIM_CCMR1_OC1_PE:constant:=3;
      TIM_CCMR1_OC1M:constant:=4;
      TIM_CCMR1_OC1CE:constant:=7;
      TIM_CCMR1_CC2S:constant:=8;
      TIM_CCMR1_OC2_FE:constant:=10;
      TIM_CCMR1_OC2_PE:constant:=11;
      TIM_CCMR1_OC2M:constant:=14;
      TIM_CCMR1_OC2_CE:constant:=15;
      TIM_CCMR1_IC1PSC:constant:=2;
      TIM_CCMR1_IC1F:constant:=4;
      TIM_CCMR1_IC2PSC:constant:=10;
      TIM_CCMR1_IC2F:constant:=12;


   TIM_CCMR2_Offset : constant := 16#1C#;--es un registro que segun el valor de cc1s tiene distinto funcionamiento
     TIM_CCMR2_CC3S:constant:=0;
      TIM_CCMR2_OC3_FE:constant:=2;
      TIM_CCMR2_OC3_PE:constant:=3;
      TIM_CCMR2_OC3M:constant:=4;
      TIM_CCMR2_OC3CE:constant:=7;
      TIM_CCMR_CC4S:constant:=8;
      TIM_CCMR2_OC4_FE:constant:=10;
      TIM_CCMR2_OC4_PE:constant:=11;
      TIM_CCMR2_OC4M:constant:=14;
      TIM_CCMR2_OC4_CE:constant:=15;
      TIM_CCMR2_IC3PSC:constant:=2;
      TIM_CCMR2_IC3F:constant:=4;
      TIM_CCMR2_IC4PSC:constant:=10;
      TIM_CCMR2_IC4F:constant:=12;
 
 TIM_CCER_Offset  : constant := 16#20#;
   TIM_CCER_CC1E:constant:=0;
    TIM_CCER_CC1P:constant:=1;
     TIM_CCER_CC1NE:constant:=2;
      TIM_CCER_CC1NP:constant:=3;
       TIM_CCER_CC2E:constant:=4;
        TIM_CCER_CC2P:constant:=5;
         TIM_CCER_CC2NE:constant:=6;
         TIM_CCER_CC2NP:constant:=7;
         TIM_CCER_CC3E:constant:=8;
         TIM_CCER_CC3P:constant:=9;
         TIM_CCER_CC3NE:constant:=10;
         TIM_CCER_CC3NP:constant:=11;
         TIM_CCER_CC4E:constant:=12;
         TIM_CCER_CC4P:constant:=13;
        
TIM_CNT_Offset   : constant := 16#24#;--counter value
  TIM_PSC_Offset   : constant := 16#28#;
 TIM_ARR_Offset   : constant := 16#2C#;
TIM_RCR_Offset   : constant := 16#30#;--0-7
   
   TIM_CCR1_Offset  : constant := 16#34#;
   TIM_CCR2_Offset  : constant := 16#38#;
   TIM_CCR3_Offset  : constant := 16#3C#;
   TIM_CCR4_Offset  : constant := 16#40#;
 
   TIM_BDTR_Offset  : constant := 16#44#;
      TIM_BDTR_DGT:constant:=0;
       TIM_BDTR_LOCK:constant:=8;
        TIM_BDTR_OSSI:constant:=10;
         TIM_BDTR_OSSR:constant:=11;
          TIM_BDTR_BKE:constant:=12;
           TIM_BDTR_BKP:constant:=13;
            TIM_BDTR_AOE:constant:=14;
             TIM_BDTR_MOE:constant:=15;
   TIM_DCR_Offset   : constant := 16#48#;
   TIM_DCR_DBA:constant:=0;
   TIM_DCR_DBL:constant:=8;

   TIM_DMAR_Offset  : constant := 16#4C#;
   TIM_OR_Offset:constant:=16#50#;
      TIM2_OR_ITR1_RMP:constant:=10;
       TIM5_OR_ITR1_RMP:constant:=6;


   
end Timers;