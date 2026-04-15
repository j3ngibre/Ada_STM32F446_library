with I2C; 
with STM32F446; use STM32F446;

package I2C_Driver is new I2C
  (
   I2C_Base => I2C1_Base,
   SCL_PIN  => 8,
   SDA_PIN  => 9,
   GPIO_SCL => GPIOB,
   GPIO_SDA => GPIOB
  );