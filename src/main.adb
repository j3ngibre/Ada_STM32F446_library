
with USART_Driver;   use USART_Driver;
with STM32F446;      use STM32F446;
with Ada.Real_Time;  use Ada.Real_Time;
with SPI_Driver;
with W5500;          use W5500;
with System;

procedure Main is

   --  Configuracion de red se tiene q ajustar no puedo hacer ping a google no sé pq
   My_MAC  : Uint8_Array (1 .. 6) := (16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#FE#, 16#ED#);
   My_IP   : Uint8_Array (1 .. 4) := (192, 168, 1, 180);
   My_SN   : Uint8_Array (1 .. 4) := (255, 255, 255, 0);
   My_GW   : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   My_IP2  : Uint8_Array(1 .. 4);
   --  Servidor al que conectar
   Server_IP   : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   Server_Port : constant Uint16 := 80;
   Local_Port  : constant Uint16 := 5000;

   Version : Uint8;
   Status  : Uint8;
   Timeout : Natural;

   Next_Time : Time := Clock;


   W5500_RESET_Pin : constant Natural := 7;  -- PC7

   --  Registros GPIO de PC7 
   GPIOC_MODER : Uint32 with
      Volatile, Address => System'To_Address (GPIOC + 16#00#);
   GPIOC_OSPEEDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOC + 16#08#);
   GPIOC_PUPDR : Uint32 with
      Volatile, Address => System'To_Address (GPIOC + 16#0C#);
   GPIOC_ODR : Uint32 with
      Volatile, Address => System'To_Address (GPIOC + 16#14#);
   RCC_AHB1ENR : Uint32 with
      Volatile, Address => System'To_Address (RCC + 16#30#);

   procedure W5500_HW_Reset is
   begin
      --  Habilitar reloj GPIOC
      RCC_AHB1ENR := RCC_AHB1ENR or Uint32 (2**GPIOCEN);

      --  PC7 como salida push-pull, sin pull, velocidad media
      GPIOC_MODER := (GPIOC_MODER
         and not (Uint32 (2**(2*W5500_RESET_Pin)))
         and not (Uint32 (2**((2*W5500_RESET_Pin)+1))))
         or Uint32 (2**(2*W5500_RESET_Pin));  -- MODER=01 (salida)

      GPIOC_OSPEEDR := (GPIOC_OSPEEDR
         and not (Uint32 (2**(2*W5500_RESET_Pin)))
         and not (Uint32 (2**((2*W5500_RESET_Pin)+1))));  -- baja velocidad

      GPIOC_PUPDR := (GPIOC_PUPDR
         and not (Uint32 (2**(2*W5500_RESET_Pin)))
         and not (Uint32 (2**((2*W5500_RESET_Pin)+1))));  -- sin pull

   
      GPIOC_ODR := GPIOC_ODR and not (Uint32 (2**W5500_RESET_Pin));
      Next_Time := Clock + Milliseconds (2);   -- 2 ms >> 500 us minimo
      delay until Next_Time;

      --  FIX #1b: Soltar RESET y esperar >=150 ms para PLL interno W5500
      GPIOC_ODR := GPIOC_ODR or Uint32 (2**W5500_RESET_Pin);
      Next_Time := Clock + Milliseconds (200); -- 200 ms >> 150 ms minimo
      delay until Next_Time;
   end W5500_HW_Reset;

   --  Utilidad: imprime un byte en hex 
   procedure Print_Hex (Label : String; Val : Uint8) is
      Hex : constant array (0 .. 15) of Character := "0123456789ABCDEF";
   begin
      USART_Driver.Send_Line (Label & "0x"
         & Hex (Natural (Val / 16))
         & Hex (Natural (Val mod 16)));
   end Print_Hex;


   -- Prueba de enlace físico
procedure Check_Link is
   Phy_Status : Uint8;
begin
   -- Leer registro PHYCFGR 
   Phy_Status := W5500.Read_Reg (16#002E#, 16#00#);
   Print_Hex ("PHYCFGR: ", Phy_Status);
   
   -- Bit 0 es Link Status 1 = link OK
   if (Phy_Status and 16#01#) = 16#01# then
      USART_Driver.Send_Line ("Cable Ethernet conectado y link OK");
   else
      USART_Driver.Send_Line (" No hay link Ethernet");
      USART_Driver.Send_Line ("   Verifica cable y router");
   end if;
end Check_Link;


begin
   -- ----------------------------------------------------------
   --  1. Inicializar perifericos
   -- ----------------------------------------------------------
   USART_Driver.Initialize (115200);
   USART_Driver.Send_Line ("=== W5500 Test ===");
   
  
   SPI_Driver.Initialize;
  
 
   USART_Driver.Send_Line ("SPI OK");
   Check_Link;

   USART_Driver.Send_Line ("Reseteando W5500...");
  -- W5500_HW_Reset;
  -- USART_Driver.Send_Line ("Reset OK");
    
   -- ----------------------------------------------------------
   --  2. Verificar comunicacion - leer VERSIONR (debe ser 0x04)
   -- ----------------------------------------------------------
   Version := W5500.Read_Version;
   Print_Hex ("W5500 VERSION: ", Version);
   SPI_Driver.CS_Low;
   if Version = 16#04# then
      USART_Driver.Send_Line ("W5500 detectado OK");
   else
      USART_Driver.Send_Line ("ERROR: W5500 no responde");
      loop null; end loop;   -- halt
   end if;

   -- ----------------------------------------------------------
   --  3. Configurar red
   -- ----------------------------------------------------------
   W5500.Set_Gateway (My_GW);
   W5500.Get_IP(My_IP2);
    USART_Driver.Send_Line("IP configurada: " &
      Integer'Image(Integer(My_IP2(1))) & "." &
      Integer'Image(Integer(My_IP2(2))) & "." &
      Integer'Image(Integer(My_IP2(3))) & "." &
      Integer'Image(Integer(My_IP2(4))));
   
   W5500.Set_Subnet  (My_SN);
   W5500.Set_MAC     (My_MAC);
   W5500.Set_IP      (My_IP);
   USART_Driver.Send_Line ("Red configurada");


     -- ----------------------------------------------------------
   --  4. Abrir Socket 0 en modo TCP
   -- ----------------------------------------------------------
   W5500.Socket0_Open_TCP (Local_Port);
   USART_Driver.Send_Line ("Socket0 OPEN enviado");

   --  Esperar a SOCK_INIT (0x13)
   Timeout := 0;
   loop
      Status := W5500.Socket0_Status;
      exit when Status = SOCK_INIT;
      Timeout := Timeout + 1;
      exit when Timeout > 1000;
      Next_Time := Clock + Milliseconds (1);
      delay until Next_Time;
   end loop;
   Print_Hex ("Socket0 status: ", Status);

      -- ----------------------------------------------------------
   --  5. Conectar al servidor
   -- ----------------------------------------------------------
   W5500.Socket0_Connect (Server_IP, Server_Port);
   USART_Driver.Send_Line ("CONNECT enviado");

   --  Esperar ESTABLISHED (0x17) 
   Timeout := 0;
   loop
      Status := W5500.Socket0_Status;
      exit when Status = SOCK_ESTABLISHED;
      exit when Status = SOCK_CLOSED;
      Timeout := Timeout + 1;
      exit when Timeout > 3000;
      Next_Time := Clock + Milliseconds (1);
      delay until Next_Time;
   end loop;
   Print_Hex ("Socket0 final status: ", Status);

   if Status = SOCK_ESTABLISHED then
      USART_Driver.Send_Line ("TCP CONNECTED!");
   else
      USART_Driver.Send_Line ("Conexion fallida");
   end if;

   -- ----------------------------------------------------------
   --  6. Cerrar socket
   -- ----------------------------------------------------------
   W5500.Socket0_Close;
   USART_Driver.Send_Line ("Socket cerrado");

   loop
      Next_Time := Clock + Milliseconds (1000);
      delay until Next_Time;
   end loop;

end Main;