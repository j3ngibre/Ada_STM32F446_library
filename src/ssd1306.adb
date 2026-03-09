-- https://www.reddit.com/r/embedded/comments/mjzp53/oled_ssd1306_1_how_to_operate_it_using_i2c/?tl=es-es
-- https://programarfacil.com/blog/arduino-blog/ssd1306-pantalla-oled-con-arduino/
-- https://www.youtube.com/watch?v=-d18xp2F3H8

--Alguna direccion está mal 

with Ada.Text_IO;
with I2C; use I2C;  -- IMPORTANTE: AÑADIR "use I2C"
with Ada.Real_Time; use Ada.Real_Time;
with USART; use USART;

package body SSD1306 is

   CONTROL_BYTE_CMD  : constant Uint8 := 16#00#;
   CONTROL_BYTE_DATA : constant Uint8 := 16#40#;

   -- Máscaras precalculadas para cada bit (0-7)
   Bit_Masks : constant array (0 .. 7) of Uint8 :=
     (2#0000_0001#, 2#0000_0010#, 2#0000_0100#, 2#0000_1000#,
      2#0001_0000#, 2#0010_0000#, 2#0100_0000#, 2#1000_0000#);

   procedure Write_Command (Cmd : Uint8) is
      Cmd_Buffer : Uint8_Array (1 .. 2) := (CONTROL_BYTE_CMD, Cmd);
      Success : Boolean;
   begin
      Success := I2C_WriteBuffer (SSD1306_ADDR, Cmd_Buffer);  
      if not Success then
      USART.Send_Line ("Error aaqui");
      end if;
   end Write_Command;

   procedure Write_Data (Data : Uint8) is
      Data_Buffer : Uint8_Array (1 .. 2) := (CONTROL_BYTE_DATA, Data);
      Success : Boolean;
   begin
      Success := I2C_WriteBuffer (SSD1306_ADDR, Data_Buffer);  -- CORREGIDO: tercer parámetro es 2
   end Write_Data;

   procedure Write_Data_Buffer (Data : Display_Buffer; Len :Natural) is
      Tx_Buffer : Uint8_Array (1 .. Integer (Len) + 1);
      Success : Boolean;
   begin
      Tx_Buffer (1) := CONTROL_BYTE_DATA;
      for I in 0 .. Integer (Len) - 1 loop
         Tx_Buffer (I + 2) := Data (I);
      end loop;

      Success := I2C_WriteBuffer (SSD1306_ADDR, Tx_Buffer);  -- CORREGIDO: tercer parámetro correcto
   end Write_Data_Buffer;

   procedure Init is
   begin
      -- Esperar estabilización
      delay 0.010;
     USART.Send_Line("DEntro de la inicializacion");
      Write_Command (SSD1306_DISPLAYOFF);
      Write_Command (SSD1306_SETDISPLAYCLOCKDIV);
      Write_Command (16#80#);
      Write_Command (SSD1306_SETMULTIPLEX);
      Write_Command (16#3F#);
      Write_Command (SSD1306_SETDISPLAYOFFSET);
      Write_Command (16#00#);
      Write_Command (SSD1306_SETSTARTLINE or 16#00#);
      Write_Command (SSD1306_CHARGEPUMP);
      Write_Command (16#14#);  -- Enable charge pump
      Write_Command (SSD1306_MEMORYMODE);
      Write_Command (16#00#);  -- Horizontal addressing mode
      Write_Command (SSD1306_SEGREMAP or 16#01#);
      Write_Command (SSD1306_COMSCANDEC);
      Write_Command (SSD1306_SETCOMPINS);
      Write_Command (16#12#);
      Write_Command (SSD1306_SETCONTRAST);
      Write_Command (16#CF#);
      Write_Command (SSD1306_SETPRECHARGE);
      Write_Command (16#F1#);
      Write_Command (SSD1306_SETVCOMDETECT);
      Write_Command (16#40#);
     
      Write_Command (SSD1306_DISPLAYALLON_RESUME);
  
      Write_Command (SSD1306_NORMALDISPLAY);
    


      Clear_Display; --error aqui 
   
      Write_Command (SSD1306_DISPLAYON);
   USART.Send_Line("DEntro  error ");
      delay 0.010;
   end Init;

 
   procedure Clear_Display is
   begin
      Frame_Buffer := (others => 0);
    
      Update_Display;
   end Clear_Display;

   procedure Display_On is
   begin
      Write_Command (SSD1306_DISPLAYON);
   end Display_On;

   procedure Display_Off is
   begin
      Write_Command (SSD1306_DISPLAYOFF);
   end Display_Off;

   procedure Set_Contrast (Value : Uint8) is
   begin
      Write_Command (SSD1306_SETCONTRAST);
      Write_Command (Value);
   end Set_Contrast;


   procedure Set_Inverse (Inverse : Boolean) is
   begin
      if Inverse then
         Write_Command (SSD1306_INVERTDISPLAY);
      else
         Write_Command (SSD1306_NORMALDISPLAY);
      end if;
   end Set_Inverse;


   procedure Draw_Pixel (X : Uint8; Y : Uint8; b : Boolean) is
      Page  : Uint8;
      Bit   : Uint8;
      Index : Integer;
   begin
      if X >= WIDTH or else Y >= HEIGHT then 
         return;  -- Fuera de pantalla
      end if;

      Page  := Y / 8;
      Bit   := Y mod 8;
      Index := Integer (Page) * 128 + Integer (X);

      if b then
         Frame_Buffer (Index) := Frame_Buffer (Index) or Bit_Masks (Integer (Bit));
      else
         Frame_Buffer (Index) := Frame_Buffer (Index) and not Bit_Masks (Integer (Bit));
      end if;
   end Draw_Pixel;


   procedure Update_Display is
   begin
      Write_Command (SSD1306_COLUMNADDR);
      Write_Command (0);
      Write_Command (127);
 
      Write_Command (SSD1306_PAGEADDR);
      Write_Command (0);
      Write_Command (7);

      Write_Data_Buffer (Frame_Buffer, 1024);
   end Update_Display;


   procedure Put_Char (X : Uint8; Y : Uint8; C : Character) is
      Char_Data : Uint8;
   begin
      if C not in Font'Range then
         return;
      end if;

      Char_Data := Font (C);
      
  
      for Row in 0 .. 7 loop
         if (Char_Data and Bit_Masks (Row)) /= 0 then
            Draw_Pixel (X, Y + Uint8 (Row), True);
         end if;
      end loop;
   end Put_Char;
function I2C_WriteBuffer (SlaveAddr : Uint8; 
                          Data : Uint8_Array) return Boolean is
   Status : Uint32;
begin

   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_START);
   
   
   if not Wait_Flag (Uint32(2**I2C_SR1_SB), 100) then
      return False;
   end if;
   

   I2C_DRA := Uint32(SlaveAddr * 2) and 16#FE#;
   
   if not Wait_Flag (Uint32(2**I2C_SR1_ADDR), 100) then
      return False;
   end if;
   

   Status := I2C_SR1A;
   Status := I2C_SR2A;
   
 
   for I in Data'Range loop
      I2C_DRA := Uint32(Data(I));
      if I < Data'Last then
         if not Wait_Flag (Uint32(2**I2C_SR1_TxE), 100) then
            I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
            return False;
         end if;
      end if;
   end loop;
 
   if not Wait_Flag (Uint32(2**I2C_SR1_BTF), 100) then
      I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
      return False;
   end if;

   I2C_CR1A := I2C_CR1A or Uint32(2**I2C_CR1_STOP);
   
   return True;
end I2C_WriteBuffer;

   procedure Put_String (X : Uint8; Y : Uint8; S : String) is
      Pos_X : Uint8 := X;
   begin
      for I in S'Range loop
         if Pos_X < WIDTH then
            Put_Char (Pos_X, Y, S (I));
            Pos_X := Pos_X + 6;  -- 5 px de ancho + 1 de separación
         else
            exit;
         end if;
      end loop;
   end Put_String;


   procedure Draw_Line (X0, Y0, X1, Y1 : Uint8; b : Boolean) is
      DX : Integer := Integer (X1) - Integer (X0);
      DY : Integer := Integer (Y1) - Integer (Y0);
      X  : Integer := Integer (X0);
      Y  : Integer := Integer (Y0);
      SX : Integer := 1;
      SY : Integer := 1;
      Err : Integer;
      E2  : Integer;
   begin
      if DX < 0 then
         DX := -DX;
         SX := -1;
      end if;
      if DY < 0 then
         DY := -DY;
         SY := -1;
      end if;

      Err := DX - DY;

      loop
         Draw_Pixel (Uint8 (X), Uint8 (Y), b);
         exit when X = Integer (X1) and Y = Integer (Y1);

         E2 := 2 * Err;
         if E2 > -DY then
            Err := Err - DY;
            X := X + SX;
         end if;
         if E2 < DX then
            Err := Err + DX;
            Y := Y + SY;
         end if;
      end loop;
   end Draw_Line;


   procedure Draw_Rect (X, Y, W, H : Uint8; b : Boolean) is
      X_End : Uint8 := X + W - 1;
      Y_End : Uint8 := Y + H - 1;
   begin
      Draw_Line (X, Y, X_End, Y, b);
      Draw_Line (X_End, Y, X_End, Y_End, b);
      Draw_Line (X_End, Y_End, X, Y_End, b);
      Draw_Line (X, Y_End, X, Y, b);
   end Draw_Rect;

 
   procedure Fill_Rect (X, Y, W, H : Uint8; b : Boolean) is
   begin
      for J in 0 .. H - 1 loop
         for I in 0 .. W - 1 loop
            Draw_Pixel (X + I, Y + J, b);
         end loop;
      end loop;
   end Fill_Rect;

end SSD1306;