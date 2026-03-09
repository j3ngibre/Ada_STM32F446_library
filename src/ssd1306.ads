with stm32f446; use stm32f446;
with I2C; use I2C;

package SSD1306 is


   type Display_Model is (SSD1306_128x64, SSD1306_128x32, SSD1306_96x16);
   Model : constant Display_Model := SSD1306_128x32;  --cambiar_modelo_con_fe

   
   WIDTH  : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 128,
         when SSD1306_128x32 => 128,
         when SSD1306_96x16  => 96);

   HEIGHT : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 64,
         when SSD1306_128x32 => 32,
         when SSD1306_96x16  => 16);

   PAGES  : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 8,
         when SSD1306_128x32 => 4,
         when SSD1306_96x16  => 2);

   BUFFER_SIZE : constant Natural :=
      (case Model is
         when SSD1306_128x64 => 1024,
         when SSD1306_128x32 => 512,
         when SSD1306_96x16  => 192);

   SSD1306_ADDR : constant Uint8 := 16#3C#;

   
   procedure Init;
   procedure Clear_Display;
   procedure Display_On;
   procedure Display_Off;
   procedure Set_Contrast  (Value   : Uint8);
   procedure Set_Inverse   (Inverse : Boolean);
   procedure Draw_Pixel    (X : Uint8; Y : Uint8; b : Boolean);
   procedure Update_Display;
   procedure Put_Char      (X : Uint8; Y : Uint8; C : Character);
   procedure Put_String    (X : Uint8; Y : Uint8; S : String);
   procedure Draw_Line     (X0, Y0, X1, Y1 : Uint8; b : Boolean);
   procedure Draw_Rect     (X, Y, W, H : Uint8; b : Boolean);
   procedure Fill_Rect     (X, Y, W, H : Uint8; b : Boolean);

private

   type Display_Buffer is array (0 .. BUFFER_SIZE - 1) of Uint8;
   Frame_Buffer : Display_Buffer := (others => 0);

   procedure Write_Command     (Cmd  : Uint8);
   procedure Write_Data        (Data : Uint8);
   procedure Write_Data_Buffer (Data : Display_Buffer; Len : Natural);

   -- Comandos
   SSD1306_SETCONTRAST         : constant Uint8 := 16#81#;
   SSD1306_DISPLAYALLON_RESUME : constant Uint8 := 16#A4#;
   SSD1306_DISPLAYALLON        : constant Uint8 := 16#A5#;
   SSD1306_NORMALDISPLAY       : constant Uint8 := 16#A6#;
   SSD1306_INVERTDISPLAY       : constant Uint8 := 16#A7#;
   SSD1306_DISPLAYOFF          : constant Uint8 := 16#AE#;
   SSD1306_DISPLAYON           : constant Uint8 := 16#AF#;
   SSD1306_SETDISPLAYOFFSET    : constant Uint8 := 16#D3#;
   SSD1306_SETCOMPINS          : constant Uint8 := 16#DA#;
   SSD1306_SETVCOMDETECT       : constant Uint8 := 16#DB#;
   SSD1306_SETDISPLAYCLOCKDIV  : constant Uint8 := 16#D5#;
   SSD1306_SETPRECHARGE        : constant Uint8 := 16#D9#;
   SSD1306_SETMULTIPLEX        : constant Uint8 := 16#A8#;
   SSD1306_SETLOWCOLUMN        : constant Uint8 := 16#00#;
   SSD1306_SETHIGHCOLUMN       : constant Uint8 := 16#10#;
   SSD1306_SETSTARTLINE        : constant Uint8 := 16#40#;
   SSD1306_MEMORYMODE          : constant Uint8 := 16#20#;
   SSD1306_COLUMNADDR          : constant Uint8 := 16#21#;
   SSD1306_PAGEADDR            : constant Uint8 := 16#22#;
   SSD1306_COMSCANINC          : constant Uint8 := 16#C0#;
   SSD1306_COMSCANDEC          : constant Uint8 := 16#C8#;
   SSD1306_SEGREMAP            : constant Uint8 := 16#A0#;
   SSD1306_CHARGEPUMP          : constant Uint8 := 16#8D#;
   SSD1306_DEACTIVATE_SCROLL   : constant Uint8 := 16#2E#;

   -- Valores que cambian según modelo
   MULTIPLEX_VAL : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 16#3F#,
         when SSD1306_128x32 => 16#1F#,
         when SSD1306_96x16  => 16#0F#);

   COMPINS_VAL : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 16#12#,
         when SSD1306_128x32 => 16#02#,
         when SSD1306_96x16  => 16#02#);

   CONTRAST_VAL : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 16#CF#,
         when SSD1306_128x32 => 16#8F#,
         when SSD1306_96x16  => 16#AF#);

   PRECHARGE_VAL : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 16#F1#,
         when SSD1306_128x32 => 16#F1#,
         when SSD1306_96x16  => 16#22#);

   PAGE_MAX : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 7,
         when SSD1306_128x32 => 3,
         when SSD1306_96x16  => 1);

   COL_MAX : constant Uint8 :=
      (case Model is
         when SSD1306_128x64 => 127,
         when SSD1306_128x32 => 127,
         when SSD1306_96x16  => 95);

   -- Fuente 5x7
   type Font_Col  is array (0 .. 4) of Uint8;
   type Font_Type is array (Character range '!' .. '~') of Font_Col;
   Font : constant Font_Type := (
      '!' => (16#00#, 16#00#, 16#4F#, 16#00#, 16#00#),
      '"' => (16#00#, 16#03#, 16#00#, 16#03#, 16#00#),
      '#' => (16#14#, 16#3E#, 16#14#, 16#3E#, 16#14#),
      '$' => (16#24#, 16#2A#, 16#7F#, 16#2A#, 16#12#),
      '%' => (16#63#, 16#13#, 16#08#, 16#64#, 16#63#),
      '&' => (16#36#, 16#49#, 16#55#, 16#22#, 16#50#),
      ''' => (16#00#, 16#00#, 16#07#, 16#00#, 16#00#),
      '(' => (16#00#, 16#1C#, 16#22#, 16#41#, 16#00#),
      ')' => (16#00#, 16#41#, 16#22#, 16#1C#, 16#00#),
      '*' => (16#0A#, 16#04#, 16#1F#, 16#04#, 16#0A#),
      '+' => (16#04#, 16#04#, 16#1F#, 16#04#, 16#04#),
      ',' => (16#50#, 16#30#, 16#00#, 16#00#, 16#00#),
      '-' => (16#08#, 16#08#, 16#08#, 16#08#, 16#08#),
      '.' => (16#60#, 16#60#, 16#00#, 16#00#, 16#00#),
      '/' => (16#00#, 16#60#, 16#1C#, 16#03#, 16#00#),
      '0' => (16#3E#, 16#41#, 16#49#, 16#41#, 16#3E#),
      '1' => (16#00#, 16#02#, 16#7F#, 16#00#, 16#00#),
      '2' => (16#46#, 16#61#, 16#51#, 16#49#, 16#46#),
      '3' => (16#21#, 16#49#, 16#4D#, 16#4B#, 16#31#),
      '4' => (16#18#, 16#14#, 16#12#, 16#7F#, 16#10#),
      '5' => (16#4F#, 16#49#, 16#49#, 16#49#, 16#31#),
      '6' => (16#3E#, 16#51#, 16#49#, 16#49#, 16#32#),
      '7' => (16#01#, 16#01#, 16#71#, 16#0D#, 16#03#),
      '8' => (16#36#, 16#49#, 16#49#, 16#49#, 16#36#),
      '9' => (16#26#, 16#49#, 16#49#, 16#49#, 16#3E#),
      ':' => (16#00#, 16#33#, 16#33#, 16#00#, 16#00#),
      ';' => (16#00#, 16#53#, 16#33#, 16#00#, 16#00#),
      '<' => (16#00#, 16#08#, 16#14#, 16#22#, 16#41#),
      '=' => (16#14#, 16#14#, 16#14#, 16#14#, 16#14#),
      '>' => (16#41#, 16#22#, 16#14#, 16#08#, 16#00#),
      '?' => (16#06#, 16#01#, 16#51#, 16#09#, 16#06#),
      '@' => (16#3E#, 16#41#, 16#49#, 16#15#, 16#1E#),
      'A' => (16#78#, 16#16#, 16#11#, 16#16#, 16#78#),
      'B' => (16#7F#, 16#49#, 16#49#, 16#49#, 16#36#),
      'C' => (16#3E#, 16#41#, 16#41#, 16#41#, 16#22#),
      'D' => (16#7F#, 16#41#, 16#41#, 16#41#, 16#3E#),
      'E' => (16#7F#, 16#49#, 16#49#, 16#49#, 16#49#),
      'F' => (16#7F#, 16#09#, 16#09#, 16#09#, 16#09#),
      'G' => (16#3E#, 16#41#, 16#41#, 16#49#, 16#7B#),
      'H' => (16#7F#, 16#08#, 16#08#, 16#08#, 16#7F#),
      'I' => (16#00#, 16#00#, 16#7F#, 16#00#, 16#00#),
      'J' => (16#38#, 16#40#, 16#40#, 16#41#, 16#3F#),
      'K' => (16#7F#, 16#08#, 16#08#, 16#14#, 16#63#),
      'L' => (16#7F#, 16#40#, 16#40#, 16#40#, 16#40#),
      'M' => (16#7F#, 16#06#, 16#18#, 16#06#, 16#7F#),
      'N' => (16#7F#, 16#06#, 16#18#, 16#60#, 16#7F#),
      'O' => (16#3E#, 16#41#, 16#41#, 16#41#, 16#3E#),
      'P' => (16#7F#, 16#09#, 16#09#, 16#09#, 16#06#),
      'Q' => (16#3E#, 16#41#, 16#51#, 16#21#, 16#5E#),
      'R' => (16#7F#, 16#09#, 16#19#, 16#29#, 16#46#),
      'S' => (16#26#, 16#49#, 16#49#, 16#49#, 16#32#),
      'T' => (16#01#, 16#01#, 16#7F#, 16#01#, 16#01#),
      'U' => (16#3F#, 16#40#, 16#40#, 16#40#, 16#7F#),
      'V' => (16#0F#, 16#30#, 16#40#, 16#30#, 16#0F#),
      'W' => (16#1F#, 16#60#, 16#1C#, 16#60#, 16#1F#),
      'X' => (16#63#, 16#14#, 16#08#, 16#14#, 16#63#),
      'Y' => (16#03#, 16#04#, 16#78#, 16#04#, 16#03#),
      'Z' => (16#61#, 16#51#, 16#49#, 16#45#, 16#43#),
      '[' => (16#00#, 16#7F#, 16#41#, 16#00#, 16#00#),
      '\' => (16#03#, 16#1C#, 16#60#, 16#00#, 16#00#),
      ']' => (16#00#, 16#41#, 16#7F#, 16#00#, 16#00#),
      '^' => (16#0C#, 16#02#, 16#01#, 16#02#, 16#0C#),
      '_' => (16#40#, 16#40#, 16#40#, 16#40#, 16#40#),
      '`' => (16#00#, 16#01#, 16#02#, 16#04#, 16#00#),
      'a' => (16#20#, 16#54#, 16#54#, 16#54#, 16#78#),
      'b' => (16#7F#, 16#48#, 16#44#, 16#44#, 16#38#),
      'c' => (16#38#, 16#44#, 16#44#, 16#44#, 16#44#),
      'd' => (16#38#, 16#44#, 16#44#, 16#48#, 16#7F#),
      'e' => (16#38#, 16#54#, 16#54#, 16#54#, 16#18#),
      'f' => (16#08#, 16#7E#, 16#09#, 16#09#, 16#00#),
      'g' => (16#0C#, 16#52#, 16#52#, 16#54#, 16#3E#),
      'h' => (16#7F#, 16#08#, 16#04#, 16#04#, 16#78#),
      'i' => (16#00#, 16#00#, 16#7D#, 16#00#, 16#00#),
      'j' => (16#00#, 16#40#, 16#3D#, 16#00#, 16#00#),
      'k' => (16#7F#, 16#10#, 16#28#, 16#44#, 16#00#),
      'l' => (16#00#, 16#00#, 16#3F#, 16#40#, 16#00#),
      'm' => (16#7C#, 16#04#, 16#18#, 16#04#, 16#78#),
      'n' => (16#7C#, 16#08#, 16#04#, 16#04#, 16#78#),
      'o' => (16#38#, 16#44#, 16#44#, 16#44#, 16#38#),
      'p' => (16#7F#, 16#12#, 16#11#, 16#11#, 16#0E#),
      'q' => (16#0E#, 16#11#, 16#11#, 16#12#, 16#7F#),
      'r' => (16#00#, 16#7C#, 16#08#, 16#04#, 16#04#),
      's' => (16#48#, 16#54#, 16#54#, 16#54#, 16#24#),
      't' => (16#04#, 16#3E#, 16#44#, 16#44#, 16#00#),
      'u' => (16#3C#, 16#40#, 16#40#, 16#20#, 16#7C#),
      'v' => (16#1C#, 16#20#, 16#40#, 16#20#, 16#1C#),
      'w' => (16#1C#, 16#60#, 16#18#, 16#60#, 16#1C#),
      'x' => (16#44#, 16#28#, 16#10#, 16#28#, 16#44#),
      'y' => (16#46#, 16#28#, 16#10#, 16#08#, 16#06#),
      'z' => (16#44#, 16#64#, 16#54#, 16#4C#, 16#44#),
      '{' => (16#00#, 16#08#, 16#77#, 16#41#, 16#00#),
      '|' => (16#00#, 16#00#, 16#7F#, 16#00#, 16#00#),
      '}' => (16#00#, 16#41#, 16#77#, 16#08#, 16#00#),
      '~' => (16#10#, 16#08#, 16#18#, 16#10#, 16#08#)
   );

end SSD1306;