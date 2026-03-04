--https://www.reddit.com/r/embedded/comments/mjzp53/oled_ssd1306_1_how_to_operate_it_using_i2c/?tl=es-es
--https://programarfacil.com/blog/arduino-blog/ssd1306-pantalla-oled-con-arduino/
--https://www.youtube.com/watch?v=-d18xp2F3H8
with I2C;
with Ada.Real_Time; use Ada.Real_Time;
package body SSD1306 is

   CONTROL_BYTE_CMD  : constant I2C.Uint8 := 16#00#;
   CONTROL_BYTE_DATA : constant I2C.Uint8 := 16#40#;

   
   -- Enviar comando 
   procedure Write_Command (Cmd : I2C.Uint8) is
      Cmd_Buffer : I2C.Uint8_Array (1 .. 2) := (CONTROL_BYTE_CMD, Cmd);
      Success : Boolean;
   begin
      Success := I2C.I2C_Write_Buffer (SSD1306_ADDR, Cmd_Buffer, 2);
      if not Success then
         null;  -- pues mensaje de error o excepcion
      end if;
   end Write_Command;
   
  
   procedure Write_Data (Data : I2C.Uint8) is
      Success : Boolean;
      Data_Buffer : I2C.Uint8;
   begin
      Data_Buffer := Data;
      Success := I2C.I2C_WriteBuffer (SSD1306_ADDR, Data_Buffer, 1); --Solo cambia el size
   end Write_Data;
   
--para enviar varios datos
     procedure Write_Data_Buffer (Data : Display_Buffer; Len : I2C.Uint8) is
      Tx_Buffer : I2C.Uint8_Array (1 .. Integer (Len) + 1);
      Success : Boolean;
   begin
      Tx_Buffer (1) := CONTROL_BYTE_DATA;
      for I in 0 .. Integer (Len) - 1 loop
         Tx_Buffer (I + 2) := Data (I);
      end loop;
      
      Success := I2C.I2C_Write_Buffer (SSD1306_ADDR, Tx_Buffer, 
                                       I2C.Uint8 (Len + 1));
   end Write_Data_Buffer;

   
   -- Inicialización del display
   procedure Init is
   begin
      -- Esperar estabilización
      delay 0.010;
      Write_Command (SSD1306_DISPLAYOFF);
      Write_Command (SSD1306_SETDISPLAYCLOCKDIV);
      Write_Command (16#80#);  
      Write_Command (SSD1306_SETMULTIPLEX);
      Write_Command (16#3F#);  
      Write_Command (SSD1306_SETDISPLAYOFFSET);
      Write_Command (16#00#);  
      Write_Command (SSD1306_SETSTARTLINE or 16#00#);
      Write_Command (SSD1306_CHARGEPUMP);
      Write_Command (16#14#);  -- Enable
      Write_Command (SSD1306_MEMORYMODE);
      Write_Command (16#00#);  -- Horizontal
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
      Clear_Display;
      Write_Command (SSD1306_DISPLAYON);
      
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
   

      procedure Set_Contrast (Value : I2C.Uint8) is
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



   procedure Draw_Pixel (X : I2C.Uint8; Y : I2C.Uint8; b : Boolean) is
      Page  : I2C.Uint8;
      Bit   : I2C.Uint8;
      Index : Integer;
   begin
      if X >= WIDTH or Y >= HEIGHT then
         return;  -- Fuera de pantalla
      end if;
      
      Page  := Y / 8;
      Bit   := Y mod 8;
      Index := Integer (Page) * 128 + Integer (X);
      
      if b then
         Frame_Buffer (Index) := Frame_Buffer (Index) or (Shift_Left (1, Integer (Bit)));
      else
         Frame_Buffer (Index) := Frame_Buffer (Index) and not (Shift_Left (1, Integer (Bit)));
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
      
     
 -- antes se orientaba horizontal creo q ahora si
   procedure Put_Char (X : I2C.Uint8; Y : I2C.Uint8; C : Character) is
      Char_Data : I2C.Uint8;
   begin
      if C not in Font'Range then
         return;
      end if;
      
      Char_Data := Font (C);
      
      -- Cada bit del patron en fonts
      for Row in 0 .. 7 loop
         if (Char_Data and (Shift_Left (1, Row))) /= 0 then
            Draw_Pixel (X, Y + I2C.Uint8 (Row), True);
         end if;
      end loop;
   end Put_Char;
  

--String
   procedure Put_String (X : I2C.Uint8; Y : I2C.Uint8; S : String) is
      Pos_X : I2C.Uint8 := X;
   begin
      for I in S'Range loop
         if Pos_X < WIDTH then
            Put_Char (Pos_X, Y, S (I));
            Pos_X := Pos_X + 6;  -- 5 px de w + 1 de sep
         else
            exit;
         end if;
      end loop;
   end Put_String;


   -- Bresenham , codigo aaltamente inspirado
--https://abreojosensamblador.epizy.com/?Tarea=1&SubTarea=23&i=1
   procedure Draw_Line (X0, Y0, X1, Y1 : I2C.Uint8; b : Boolean) is
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
         Draw_Pixel (I2C.Uint8 (X), I2C.Uint8 (Y), b);
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

  -- a ver es debujar lineas a linea
   procedure Draw_Rect (X, Y, W, H : I2C.Uint8; b : Boolean) is
      X_End : I2C.Uint8 := X + W - 1;
      Y_End : I2C.Uint8 := Y + H - 1;
   begin
      Draw_Line (X, Y, X_End, Y, b);
      Draw_Line (X_End, Y, X_End, Y_End, b);
      Draw_Line (X_End, Y_End, X, Y_End, b);
      Draw_Line (X, Y_End, X, Y, b);
   end Draw_Rect;

 -- pos linea a linea vas hasta rekkebar
   procedure Fill_Rect (X, Y, W, H : I2C.Uint8; b : Boolean) is
   begin
      for J in 0 .. H - 1 loop
         for I in 0 .. W - 1 loop
            Draw_Pixel (X + I, Y + J, b);
         end loop;
      end loop;
   end Fill_Rect;

end SSD1306;




 











