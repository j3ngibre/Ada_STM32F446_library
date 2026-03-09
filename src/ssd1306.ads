with stm32f446; use stm32f446;
with I2C;use I2C;


package SSD1306 is

   -- Dirección 
   SSD1306_ADDR : constant Uint8 := 16#3C#;  --  0x3D)

   -- Dimensiones 
   WIDTH  : constant := 128;
   HEIGHT : constant := 64;
   PAGES  : constant := 8;  -- 64/8 = 8 páginas

  
   procedure Init;

   -- Comandos básicos
   procedure Clear_Display;
   procedure Display_On;
   procedure Display_Off;
   procedure Set_Contrast (Value : Uint8);
   procedure Set_Inverse (Inverse : Boolean);

   -- Dibujar px
   procedure Draw_Pixel (X : Uint8; Y : Uint8; b : Boolean);
   procedure Update_Display;

   -- Texto
   procedure Put_Char (X : Uint8; Y : Uint8; C : Character);
   procedure Put_String (X : Uint8; Y : Uint8; S : String);

   -- Formas 
   procedure Draw_Line (X0, Y0, X1, Y1 : Uint8; b : Boolean);
   procedure Draw_Rect (X, Y, W, H : Uint8; b : Boolean);
   procedure Fill_Rect (X, Y, W, H : Uint8; b : Boolean);

private

   -- Buffer
   type Display_Buffer is array (0 .. 1023) of Uint8;
   Frame_Buffer : Display_Buffer := (others => 0);

   
   procedure Write_Command (Cmd : Uint8);
   procedure Write_Data (Data : Uint8);
   procedure Write_Data_Buffer (Data : Display_Buffer; Len : Natural);

   -- Comandos 
   SSD1306_SETCONTRAST     : constant Uint8 := 16#81#;
   SSD1306_DISPLAYALLON_RESUME : constant Uint8 := 16#A4#;
   SSD1306_DISPLAYALLON    : constant Uint8 := 16#A5#;
   SSD1306_NORMALDISPLAY   : constant Uint8 := 16#A6#;
   SSD1306_INVERTDISPLAY   : constant Uint8 := 16#A7#;
   SSD1306_DISPLAYOFF      : constant Uint8 := 16#AE#;
   SSD1306_DISPLAYON       : constant Uint8 := 16#AF#;
   SSD1306_SETDISPLAYOFFSET : constant Uint8 := 16#D3#;
   SSD1306_SETCOMPINS      : constant Uint8 := 16#DA#;
   SSD1306_SETVCOMDETECT   : constant Uint8 := 16#DB#;
   SSD1306_SETDISPLAYCLOCKDIV : constant Uint8 := 16#D5#;
   SSD1306_SETPRECHARGE    : constant Uint8 := 16#D9#;
   SSD1306_SETMULTIPLEX    : constant Uint8 := 16#A8#;
   SSD1306_SETLOWCOLUMN    : constant Uint8 := 16#00#;
   SSD1306_SETHIGHCOLUMN   : constant Uint8 := 16#10#;
   SSD1306_SETSTARTLINE    : constant Uint8 := 16#40#;
   SSD1306_MEMORYMODE      : constant Uint8 := 16#20#;
   SSD1306_COLUMNADDR      : constant Uint8 := 16#21#;
   SSD1306_PAGEADDR        : constant Uint8 := 16#22#;
   SSD1306_COMSCANINC      : constant Uint8 := 16#C0#;
   SSD1306_COMSCANDEC      : constant Uint8 := 16#C8#;
   SSD1306_SEGREMAP        : constant Uint8 := 16#A0#;
   SSD1306_CHARGEPUMP      : constant Uint8 := 16#8D#;

   -- Fuente
   type Font_Type is array (Character range ' ' .. '~') of Uint8;
   Font : constant Font_Type := (
      ' ' => 16#00#, '!' => 16#5E#, '"' => 16#06#, '#' => 16#6C#,
      '$' => 16#7C#, '%' => 16#52#, '&' => 16#FE#, ''' => 16#06#,
      '(' => 16#38#, ')' => 16#40#, '*' => 16#7E#, '+' => 16#0C#,
      ',' => 16#40#, '-' => 16#04#, '.' => 16#40#, '/' => 16#22#,
      '0' => 16#7E#, '1' => 16#30#, '2' => 16#6D#, '3' => 16#79#,
      '4' => 16#33#, '5' => 16#5B#, '6' => 16#5F#, '7' => 16#70#,
      '8' => 16#7F#, '9' => 16#7B#, ':' => 16#48#, ';' => 16#48#,
      '<' => 16#0C#, '=' => 16#24#, '>' => 16#30#, '?' => 16#6D#,
      '@' => 16#7E#, 'A' => 16#77#, 'B' => 16#7F#, 'C' => 16#4E#,
      'D' => 16#3E#, 'E' => 16#4F#, 'F' => 16#47#, 'G' => 16#5E#,
      'H' => 16#37#, 'I' => 16#06#, 'J' => 16#38#, 'K' => 16#57#,
      'L' => 16#0E#, 'M' => 16#76#, 'N' => 16#56#, 'O' => 16#7E#,
      'P' => 16#67#, 'Q' => 16#7B#, 'R' => 16#77#, 'S' => 16#5B#,
      'T' => 16#0E#, 'U' => 16#3E#, 'V' => 16#2A#, 'W' => 16#7E#,
      'X' => 16#55#, 'Y' => 16#1D#, 'Z' => 16#6C#, '[' => 16#46#,
      '\' => 16#22#, ']' => 16#60#, '^' => 16#0E#, '_' => 16#40#,
      '`' => 16#02#, 'a' => 16#78#, 'b' => 16#1F#, 'c' => 16#0C#,
      'd' => 16#3C#, 'e' => 16#5E#, 'f' => 16#47#, 'g' => 16#7B#,
      'h' => 16#17#, 'i' => 16#04#, 'j' => 16#20#, 'k' => 16#57#,
      'l' => 16#06#, 'm' => 16#76#, 'n' => 16#16#, 'o' => 16#1E#,
      'p' => 16#67#, 'q' => 16#73#, 'r' => 16#06#, 's' => 16#4C#,
      't' => 16#0F#, 'u' => 16#1C#, 'v' => 16#2A#, 'w' => 16#3E#,
      'x' => 16#55#, 'y' => 16#6D#, 'z' => 16#64#, '{' => 16#46#,
      '|' => 16#06#, '}' => 16#60#, '~' => 16#14#
   );

end SSD1306;