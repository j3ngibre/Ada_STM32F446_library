
with SPI; 
with STM32F446; use STM32F446;

package SPI_Driver is new SPI
(
   SPI_Base  => 16#4001_3000#,
   GPIO_SCK  => GPIOA,
   GPIO_MISO => GPIOA,
   GPIO_MOSI => GPIOA,
   GPIO_CS   => GPIOB,
   SCK_Pin   => 5,
   MISO_Pin  => 6,
   MOSI_Pin  => 7,
   CS_Pin    => 6
);