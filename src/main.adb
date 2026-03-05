

with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Real_Time;    use Ada.Real_Time;
with I2C;              use I2C;
with SSD1306;          use SSD1306;




procedure Main is

   
   procedure Wait (ms : Natural) is
   begin
      delay Duration (ms) / 1000.0;
   end Wait;



   
   procedure Test_Text is
   begin
     
      Clear_Display;
      
      
      Put_String (10, 0, "HOLA MUNDO!");
      Put_String (10, 8, "SSD1306 OLED");
      Put_String (10, 16, "Ada con I2C");
      Put_String (10, 24, "1234567890");
      Put_String (10, 32, "ABCDEFGHIJK");
      Put_String (10, 40, "abcdefghijk");
      
      Update_Display;
      Wait (2000);
   end Test_Text;

   
   procedure Test_Pixels is
   begin


      Clear_Display;
      

      for I in 0 .. 63 loop
         Draw_Pixel (I2C.Uint8 (I * 2), I2C.Uint8 (I), True);
         Draw_Pixel (I2C.Uint8 (I * 2), I2C.Uint8 (63 - I), True);
      end loop;
    
      for I in 0 .. 127 loop
         Draw_Pixel (I2C.Uint8 (I), 0, True);        
         Draw_Pixel (I2C.Uint8 (I), 63, True);          
      end loop;
      
      for I in 0 .. 63 loop
         Draw_Pixel (0, I2C.Uint8 (I), True);          
         Draw_Pixel (127, I2C.Uint8 (I), True);       
      end loop;
      
      Update_Display;
      Wait (2000);
   end Test_Pixels;

   
  procedure Test_Lines is
begin
   Clear_Display;
   
      Draw_Line (0, 0, 127, 0, True);       
      Draw_Line (0, 63, 127, 63, True);     
         Draw_Line (0, 0, 0, 63, True);      
          Draw_Line (127, 0, 127, 63, True);        
  
   Draw_Line (0, 0, 127, 63, True);      
      Draw_Line (0, 63, 127, 0, True);     
   
   
   Draw_Line (64, 32, 0, 0, True);       
   Draw_Line (64, 32, 127, 0, True);     
      Draw_Line (64, 32, 0, 63, True);      
   Draw_Line (64, 32, 127, 63, True);    
   
   
   Draw_Line (0, 32, 127, 32, True);     
      Draw_Line (64, 0, 64, 63, True);       
   Update_Display;
   Wait (2000);
end Test_Lines;
  
   procedure Test_Rectangles is
   begin
  
      Clear_Display;
      
   
      for I in 0 .. 5 loop
         declare
            Offset : I2C.Uint8 := I2C.Uint8 (I * 10);
            Rect_X : I2C.Uint8 := 10 + Offset;
            Rect_Y : I2C.Uint8 := 5 + Offset;
            Rect_W : I2C.Uint8 := 108 - I2C.Uint8 (I * 20);
            Rect_H : I2C.Uint8 := 54 - I2C.Uint8 (I * 10);
         begin
            Draw_Rect (Rect_X, Rect_Y, Rect_W, Rect_H, True);
         end;
      end loop;
      
      Update_Display;
      Wait (2000);
   end Test_Rectangles;

   procedure Test_Filled_Rectangles is
   begin

      Clear_Display;
      

      Fill_Rect (10, 10, 100, 8, True);    
      Fill_Rect (10, 25, 75, 8, True);      
      Fill_Rect (10, 40, 50, 8, True);      
      Fill_Rect (10, 55, 25, 8, True);    
      
    
      Put_String (10, 0, "Barras:");
      Update_Display;
      Wait (2000);
   end Test_Filled_Rectangles;


   procedure Test_Effects is
   begin
  
      
      for I in 1 .. 3 loop
       
         for C in 0 .. 255 loop
            Set_Contrast (I2C.Uint8 (C));
            Wait (5);
            exit when C mod 64 = 0;  
         end loop;
         
       
         Set_Inverse (True);
         Wait (500);
         Set_Inverse (False);
         Wait (500);
      end loop;
      
   
      Set_Contrast (16#CF#);
   end Test_Effects;

procedure Test_Animation is
   X_Pos : Integer := 0;
   Y_Pos : Integer := 0;
   Step : Integer := 0;
begin
   for Frame in 1 .. 50 loop
      Clear_Display;
      
     
      for DX in 0 .. 5 loop
         for DY in 0 .. 5 loop
            Draw_Pixel (I2C.Uint8 (X_Pos + DX), 
                       I2C.Uint8 (Y_Pos + DY), True);
         end loop;
      end loop;
      
      Put_String (0, 56, "Frame:");
      declare
         Frame_Str : String := Integer'Image (Frame);
      begin
         Put_String (50, 56, Frame_Str (Frame_Str'First + 1 .. Frame_Str'Last));
      end;
      
      Update_Display;
      
     
      Step := Step + 1;
      case Step mod 4 is
         when 0 => X_Pos := X_Pos + 5;  -- Derecha
         when 1 => Y_Pos := Y_Pos + 5;  -- Abajo
         when 2 => X_Pos := X_Pos - 5;  -- Izquierda
         when 3 => Y_Pos := Y_Pos - 5;  -- Arriba
         when others => null;
      end case;
      
      
      if X_Pos < 0 then X_Pos := 0; Step := 0; end if;
      if X_Pos > 122 then X_Pos := 122; Step := 2; end if;
      if Y_Pos < 0 then Y_Pos := 0; Step := 1; end if;
      if Y_Pos > 58 then Y_Pos := 58; Step := 3; end if;
      
      Wait (100);
   end loop;
end Test_Animation;
 
   procedure Test_Full_Demo is
   begin

      
  
      Clear_Display;
      Put_String (20, 20, "SSD1306 DEMO");
      Put_String (20, 35, "Ada + I2C");
      Update_Display;
      Wait (2000);
      
   
      Clear_Display;
      for Line in 0 .. 7 loop
         declare
            Y_Pos : I2C.Uint8 := I2C.Uint8 (Line * 8);
            Msg   : String := "Linea " & Integer'Image (Line + 1);
         begin
            Put_String (0, Y_Pos, Msg);
         end;
      end loop;
      Update_Display;
      Wait (2000);
      
   
      Clear_Display;
      Draw_Rect (10, 10, 40, 20, True);
      Fill_Rect (70, 10, 40, 20, True);
      Draw_Line (10, 40, 117, 55, True);
      Draw_Line (10, 55, 117, 40, True);
      Update_Display;
      Wait (2000);
      
   
      Clear_Display;
      for X in 0 .. 12 loop
         Draw_Line (I2C.Uint8 (X * 10), 0, I2C.Uint8 (X * 10), 63, (X mod 2 = 0));
      end loop;
      for Y in 0 .. 6 loop
         Draw_Line (0, I2C.Uint8 (Y * 9), 127, I2C.Uint8 (Y * 9), (Y mod 2 = 0));
      end loop;
      Update_Display;
      Wait (2000);
      

      Clear_Display;
      Put_String (0, 0, "!@#$%^&*()_+");
      Put_String (0, 8, "{}[]:;'<>?,./");
      Put_String (0, 16, "`~-= ");
      Update_Display;
      Wait (2000);
      

   end Test_Full_Demo;

begin
 
 

   I2C.Initialize;
   SSD1306.Init;
   Wait (1500); 

   Test_Text;
   Test_Pixels;
   Test_Lines;
   Test_Rectangles;
   Test_Filled_Rectangles;
   Test_Effects;
   Test_Animation;
   Test_Full_Demo;
  
   Clear_Display;
   Put_String (20, 20, "PRUEBAS OK");
   Update_Display;
   
exception
   when others =>
      null;
 
end Main;