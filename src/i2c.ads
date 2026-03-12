with System;
with stm32f446;use stm32f446;
package I2C is

   

   procedure Initialize;



   function I2C_Write  (SlaveAddr : Uint8;
                        Data : Uint8) return Boolean;

   function I2C_Read (SlaveAddr : Uint8;
                       Data : out Uint8) return Boolean;


   function I2C_WriteBuffer (SlaveAddr : Uint8;
                               Data : Uint8_Array) return Boolean;

   function I2C_ReadBuffer (SlaveAddr : Uint8;
                              Data : out Uint8_Array) return Boolean;

--function Wait_Bus return Boolean;
function Wait_Flag (Flag_Mask : Uint32; Timeout_MS : Positive) return Boolean;
procedure Clear_Errors;


   RCC_AHB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#30#);--bit 1

    RCC_APB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#40#);--23es I2C3 , 22 I2C2 , 21 I2C1 21

    GPIOB_MODER : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#00#);--HAy q poner funcion alternativa aqui

    GPIOB_AFRL : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#20#);  -- funcion alt (pines 0-7) no usamos pero si hay cambio de pin si

    GPIOB_AFRH : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#24#);  -- funcion alternativa (pines 8-15) 

    GPIOB_OTYPER : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#04#);  -- pones pull up o opendrin , para i2c para no cortocircuito ponemos opendrain

    GPIOB_OSPEEDR : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#08#);  -- velocidad de cambio de valor de pin conmutacion

    GPIOB_PUPDR : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#0C#);  -- pull-up/pull-down
    
    GPIOB_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIOB + 16#14#);

    -- Registros I2C
    I2C_CR1A : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_CR1);

    I2C_CR2A : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_CR2);

    I2C_CCRA : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_CCR);

    I2C_TRISEA : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_TRISE);


    I2C_SR1A : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_SR1);

    I2C_SR2A : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_SR2);


    I2C_DRA : Uint32 with
    Volatile,
    Address => System'To_Address (I2C1_Base + I2C_DR);

end I2C;
