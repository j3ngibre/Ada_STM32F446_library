with USART; 
with STM32F446; use STM32F446;

package USART_Driver is new USART
  (
   GPIO_RX => GPIOA ,
   GPIO_TX => GPIOA ,
   RX_PIN  => 3,
   TX_PIN  => 2,
   AF_RX  => 7,
   AF_TX  => 7,
   USART_Base => USART2_Base
  );