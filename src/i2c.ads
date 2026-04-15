with System;
with stm32f446;use stm32f446;

generic
   I2C_Base : Uint32;
   SCL_PIN : Natural;
   SDA_PIN : Natural;
   GPIO_SCL: Uint32;
   GPIO_SDA: Uint32;

package I2C is

protected Bus is 
   procedure Initialize;



   function Write  (SlaveAddr : Uint8;
                        Data : Uint8) return Boolean;

   function Read (SlaveAddr : Uint8;
                       Data : out Uint8) return Boolean;


   function Write_Buffer (SlaveAddr : Uint8;
                               Data : Uint8_Array) return Boolean;

   function Read_Buffer (SlaveAddr : Uint8;
                              Data : out Uint8_Array) return Boolean;

--function Wait_Bus return Boolean;
function Wait_Flag (Flag_Mask : Uint32; Timeout_MS : Positive) return Boolean;
procedure Clear_Errors;
procedure Test_Hardware;
procedure Scan_I2C_Bus;
procedure Test_Minimo;
procedure Mostrar_Config;
private 
Initialized: Boolean:=false;

end Bus;
   function GPIO_To_AHB1_Bit (Base : Uint32) return Uint32 is
     (case Base is
        when GPIOA => 2**0,
        when GPIOB => 2**1,
        when GPIOC => 2**2,
        when GPIOD => 2**3,
        when GPIOE => 2**4,
        when GPIOF => 2**5,
        when GPIOG => 2**6,
        when GPIOH => 2**7,
        when others => 0);
   
      function I2C_To_APB1_Bit (Base : Uint32) return Uint32 is
     (case Base is
        when I2C1_Base => 2**21,
        when I2C2_Base => 2**22,
        when I2C3_Base => 2**23,
        when others    => 0);
   
   AHB1_SCL_Bit : constant Uint32 := GPIO_To_AHB1_Bit (GPIO_SCL);
   AHB1_SDA_Bit : constant Uint32 := GPIO_To_AHB1_Bit (GPIO_SDA);
   APB1_I2C_Bit : constant Uint32 := I2C_To_APB1_Bit  (I2C_Base);

   RCC_AHB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#30#);--bit 1

   RCC_APB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#40#);--23es I2C3 , 22 I2C2 , 21 I2C1 21




   GPIO_MODER_SCL : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SCL + 16#00#);
  

   GPIO_MODER_SDA : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SDA + 16#00#);


    GPIO_AFRL_SCL : Uint32 with
    Volatile,
    Address => System'To_Address (GPIO_SCL + 16#20#);  -- funcion alt (pines 0-7) no usamos pero si hay cambio de pin si

     GPIO_AFRL_SDA : Uint32 with
    Volatile,
    Address => System'To_Address (GPIO_SDA + 16#20#);  -- funcion alt (pines 0-7) no usamos pero si hay cambio de pin si

   GPIO_AFRH_SCL : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SCL + 16#24#);  -- funcion alternativa (pines 8-15) 

   GPIO_AFRH_SDA : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SDA + 16#24#);  -- funcion alternativa (pines 8-15) 




   GPIO_OTYPER_SCL : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SCL + 16#04#);  

   GPIO_OTYPER_SDA : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SDA + 16#04#); 

   

    GPIO_OSPEEDR_SCL : Uint32 with
    Volatile,
    Address => System'To_Address (GPIO_SCL + 16#08#);  -- velocidad de cambio de valor de pin conmutacion

   GPIO_OSPEEDR_SDA : Uint32 with
    Volatile,
    Address => System'To_Address (GPIO_SDA + 16#08#);  -- velocidad de cambio de valor de pin conmutacion




   GPIO_PUPDR_SCL : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SCL + 16#0C#);  -- pull-up/pull-down

   GPIO_PUPDR_SDA : Uint32 with
   Volatile,
   Address => System'To_Address (GPIO_SDA + 16#0C#);  -- pull-up/pull-down
    
    

   GPIO_ODR_SCL : Uint32 with
   Volatile, Address => System'To_Address (GPIO_SCL+ 16#14#);

   GPIO_ODR_SDA : Uint32 with
   Volatile, Address => System'To_Address (GPIO_SDA+ 16#14#);



   
    -- Registros I2C
    CR1 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR1);

    CR2 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR2);

    CCR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CCR);

   TRISE : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_TRISE);


    SR1 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_SR1);

    SR2 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_SR2);


    DR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_DR);


end I2C;
