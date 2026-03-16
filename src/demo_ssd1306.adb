with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Real_Time;    use Ada.Real_Time;
with stm32f446;        use stm32f446;
with I2C;              use I2C;
with SSD1306;          use SSD1306;
with USART;            use USART;

procedure Main is

   procedure Wait (ms : Natural) is
   begin
      delay Duration (ms) / 1000.0;
   end Wait;


   procedure Test_Text is
   begin
      Clear_Display;
      
      Put_String (0, 0,  "HOLA MUNDO!");
      Put_String (0, 8,  "SSD1306 OLED");
      Put_String (0, 16, "Ada + I2C");
      Put_String (0, 24, "1234567890");
      Update_Display;
      Wait (2000);
   end Test_Text;


   procedure Test_Pixels is
   begin
      Clear_Display;
      -- Bordes para 128x32
      for I in 0 .. 31 loop
         Draw_Pixel (0,   Uint8 (I), True);   -- borde izquierdo
         Draw_Pixel (127, Uint8 (I), True);   -- borde derecho
      end loop;
      for I in 0 .. 127 loop
         Draw_Pixel (Uint8 (I), 0,  True);    -- borde superior
         Draw_Pixel (Uint8 (I), 31, True);    -- borde inferior
      end loop;
      Update_Display;
      Wait (2000);
   end Test_Pixels;


   procedure Test_Lines is
   begin
      Clear_Display;
      -- Bordes
      Draw_Line (0,   0,  127, 0,  True);   -- top
      Draw_Line (0,   31, 127, 31, True);   -- bottom
      Draw_Line (0,   0,  0,   31, True);   -- left
      Draw_Line (127, 0,  127, 31, True);   -- right
      -- Diagonales
      Draw_Line (0, 0,  127, 31, True);
      Draw_Line (0, 31, 127, 0,  True);
      -- Cruz central
      Draw_Line (0,  16, 127, 16, True);    -- horizontal
      Draw_Line (64,  0,  64, 31, True);    -- vertical
      Update_Display;
      Wait (2000);
   end Test_Lines;


   procedure Test_Rectangles is
   begin
      Clear_Display;
      -- 3 rectángulos concéntricos (adaptados a 32px de alto)
      Draw_Rect (0,  0,  128, 32, True);
      Draw_Rect (10, 4,  108, 24, True);
      Draw_Rect (20, 8,  88,  16, True);
      Update_Display;
      Wait (2000);
   end Test_Rectangles;


   procedure Test_Filled_Rectangles is
   begin
      Clear_Display;
      Put_String (0, 0, "Barras:");
      Fill_Rect (0,  8,  100, 6, True);
      Fill_Rect (0,  16, 75,  6, True);
      Fill_Rect (0,  24, 50,  6, True);
      Update_Display;
      Wait (2000);
   end Test_Filled_Rectangles;


   procedure Test_Effects is
   begin
      -- Fade in/out de contraste
      for C in 0 .. 255 loop
         Set_Contrast (Uint8 (C));
         Wait (3);
      end loop;
      for C in reverse 0 .. 255 loop
         Set_Contrast (Uint8 (C));
         Wait (3);
      end loop;
      -- Inversión
      Set_Inverse (True);  Wait (500);
      Set_Inverse (False); Wait (500);
      -- Restaurar contraste
      Set_Contrast (CONTRAST_VAL);
   end Test_Effects;


   procedure Test_Animation is
      X_Pos : Integer := 0;
      Y_Pos : Integer := 0;
      Step  : Integer := 0;
   begin
      for Frame in 1 .. 50 loop
         Clear_Display;
         for DX in 0 .. 5 loop
            for DY in 0 .. 5 loop
               if X_Pos + DX <= 127 and Y_Pos + DY <= 31 then
                  Draw_Pixel (Uint8 (X_Pos + DX),
                              Uint8 (Y_Pos + DY), True);
               end if;
            end loop;
         end loop;
        
         Put_String (0, 24, "Frame:");
         declare
            Frame_Str : String := Integer'Image (Frame);
         begin
            Put_String (44, 24,
               Frame_Str (Frame_Str'First + 1 .. Frame_Str'Last));
         end;
         Update_Display;

         Step := Step + 1;
         case Step mod 4 is
            when 0 => X_Pos := X_Pos + 5;
            when 1 => Y_Pos := Y_Pos + 5;
            when 2 => X_Pos := X_Pos - 5;
            when 3 => Y_Pos := Y_Pos - 5;
            when others => null;
         end case;

      
         if X_Pos < 0   then X_Pos := 0;   Step := 0; end if;
         if X_Pos > 122 then X_Pos := 122;  Step := 2; end if;
         if Y_Pos < 0   then Y_Pos := 0;    Step := 1; end if;
         if Y_Pos > 26  then Y_Pos := 26;   Step := 3; end if;  -- 32-6=26

         Wait (100);
      end loop;
   end Test_Animation;


   procedure Test_Full_Demo is
   begin
     
      Clear_Display;
      Put_String (10, 8,  "SSD1306 DEMO");
      Put_String (10, 18, "Ada + I2C");
      Update_Display;
      Wait (2000);

    
      Clear_Display;
      for Line in 0 .. 3 loop
         declare
            Y_Pos : Uint8 := Uint8 (Line * 8);
            Msg   : String := "Linea " & Integer'Image (Line + 1);
         begin
            Put_String (0, Y_Pos, Msg);
         end;
      end loop;
      Update_Display;
      Wait (2000);


      Clear_Display;
      Draw_Rect (0,  0, 60, 32, True);
      Fill_Rect (65, 4, 60, 24, True);
      Draw_Line (0, 0, 127, 31, True);
      Update_Display;
      Wait (2000);

 
      Clear_Display;
      Put_String (0, 0,  "!@#$%^&*()_+");
      Put_String (0, 8,  "{}[]:;<>?,./");
      Put_String (0, 16, "`~-=|\\");
      Update_Display;
      Wait (2000);

   end Test_Full_Demo;


begin
   USART.Initialize (115200);
   USART.Send_Line ("USART INICIALIZADO");
   Wait (100);
   USART.Send_Line ("USART INICIALIZADO2");
   I2C.Initialize;
   USART.Send_Line ("I2C INICIALIZADO");

   declare
      SR2 : constant Uint32 := I2C_SR2A;
      CR1 : constant Uint32 := I2C_CR1A;
   begin
      if (SR2 and Uint32 (2)) /= 0 then
         USART.Send_Line ("DIAG: bus BUSY!");
      else
         USART.Send_Line ("DIAG: bus libre OK");
      end if;
      if (CR1 and Uint32 (2**I2C_CR1_PE)) /= 0 then
         USART.Send_Line ("DIAG: PE=1 OK");
      else
         USART.Send_Line ("DIAG: PE=0 PROBLEMA");
      end if;
   end;

   Wait (100);
   SSD1306.Init;
   USART.Send_Line ("SSD1306 INICIALIZADO");
   Wait (1500);

   Test_Text;             USART.Send_Line ("Test_Text OK");
   Test_Pixels;           USART.Send_Line ("Test_Pixels OK");
   Test_Lines;            USART.Send_Line ("Test_Lines OK");
   Test_Rectangles;       USART.Send_Line ("Test_Rectangles OK");
   Test_Filled_Rectangles; USART.Send_Line ("Test_Filled OK");
   Test_Effects;          USART.Send_Line ("Test_Effects OK");
   Test_Animation;        USART.Send_Line ("Test_Animation OK");
   Test_Full_Demo;        USART.Send_Line ("Test_Full_Demo OK");

   Clear_Display;
   Put_String (20, 12, "PRUEBAS OK");
   Update_Display;

exception
   when others => null;
end Main;