with USART_Driver;  use USART_Driver;
with STM32F446;     use STM32F446;
with Ada.Real_Time; use Ada.Real_Time;
with SPI_Driver;     use SPI_Driver;
with W5500;         use W5500;
with System;

procedure Main is

   My_MAC : Uint8_Array (1 .. 6) := (16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#FE#, 16#ED#);
   My_IP  : Uint8_Array (1 .. 4) := (192, 168, 1, 180);
   My_SN  : Uint8_Array (1 .. 4) := (255, 255, 255, 0);
   My_GW  : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   Google  : Uint8_Array (1 .. 4) := (8, 8, 8, 8);
   DNS_IP  : Uint8_Array (1 .. 4);
   DNS_Server : constant Uint8_Array (1 .. 4) := (192, 168, 1, 1);

   Server_IP   : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   Server_Port : constant Uint16 := 80;
   Local_Port  : constant Uint16 := 5000;

   Version   : Uint8;
   Status    : Uint8;
   Timeout   : Natural;
   Next_Time : Time := Clock;

   --  Reset hardware W5500 
   W5500_RST : constant Natural := 7;

   GPIOC_MODER   : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#00#);
   GPIOC_OSPEEDR : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#08#);
   GPIOC_PUPDR   : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#0C#);
   GPIOC_ODR     : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#14#);
   RCC_AHB1ENR   : Uint32 with Volatile, Address => System'To_Address (RCC   + 16#30#);

   procedure W5500_HW_Reset is
   begin
      RCC_AHB1ENR := RCC_AHB1ENR or Uint32 (2**GPIOCEN);
      GPIOC_MODER := (GPIOC_MODER
            and not (Uint32 (2**(2*W5500_RST)))
            and not (Uint32 (2**((2*W5500_RST)+1))))
         or Uint32 (2**(2*W5500_RST));
      GPIOC_OSPEEDR := GPIOC_OSPEEDR
         and not (Uint32 (2**(2*W5500_RST)))
         and not (Uint32 (2**((2*W5500_RST)+1)));
      GPIOC_PUPDR := GPIOC_PUPDR
         and not (Uint32 (2**(2*W5500_RST)))
         and not (Uint32 (2**((2*W5500_RST)+1)));
      GPIOC_ODR := GPIOC_ODR and not (Uint32 (2**W5500_RST));
      Next_Time := Clock + Milliseconds (2);
      delay until Next_Time;
      GPIOC_ODR := GPIOC_ODR or Uint32 (2**W5500_RST);
      Next_Time := Clock + Milliseconds (200);
      delay until Next_Time;
   end W5500_HW_Reset;

   

   procedure Print_IP (Label : String; IP : Uint8_Array) is
   begin
      USART_Driver.Send_Line (Label
         & Integer'Image (Integer (IP (IP'First)))     & "."
         & Integer'Image (Integer (IP (IP'First + 1))) & "."
         & Integer'Image (Integer (IP (IP'First + 2))) & "."
         & Integer'Image (Integer (IP (IP'First + 3))));
   end Print_IP;

   procedure Check_Link is
      Phy : Uint8;
   begin
      Phy := W5500.Read_PHYCFGR;
      W5500.Print_Hex ("PHYCFGR: ", Phy);
      if (Phy and 16#01#) /= 0 then
         USART_Driver.Send_Line ("Link Ethernet OK");
      else
         USART_Driver.Send_Line ("Sin link - verifica cable");
      end if;
   end Check_Link;

   procedure Verify_Configuration is
      MAC_R : Uint8_Array (1 .. 6);
      IP_R  : Uint8_Array (1 .. 4);
   begin
      W5500.Get_MAC (MAC_R);
      USART_Driver.Send_Line ("--- Verificacion ---");
      for I in MAC_R'Range loop
         Print_Hex ("MAC[" & Integer'Image (I) & "]: ", MAC_R (I));
      end loop;
      W5500.Get_IP (IP_R);
      Print_IP ("IP leida: ", IP_R);
   end Verify_Configuration;

begin

   USART_Driver.Initialize (115200);
   USART_Driver.Send_Line ("=== W5500 Test ===");
   SPI_Driver.Initialize;
   USART_Driver.Send_Line ("SPI OK");

   
   USART_Driver.Send_Line ("Reseteando W5500...");
   W5500_HW_Reset;
   USART_Driver.Send_Line ("Reset OK");


   Version := W5500.Read_Version;
   Print_Hex ("W5500 VERSION: ", Version);
   if Version /= 16#04# then
      USART_Driver.Send_Line ("ERROR: W5500 no responde");
      loop null; end loop;
   end if;
   USART_Driver.Send_Line ("W5500 OK");

 
   Check_Link;

   W5500.Set_Gateway (My_GW);
   W5500.Set_Subnet  (My_SN);
   W5500.Set_MAC     (My_MAC);
   W5500.Set_IP      (My_IP);
   USART_Driver.Send_Line ("Red configurada");
   Verify_Configuration;

   if W5500.Ping (Google, 3000) then
      USART_Driver.Send_Line ("Gateway alcanzable");
   else
      USART_Driver.Send_Line ("Gateway no responde");
   end if;


   W5500.Socket0_Open_TCP (Local_Port);
   USART_Driver.Send_Line ("Socket0 OPEN");

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

   if Status /= SOCK_INIT then
      USART_Driver.Send_Line ("ERROR: socket no llego a INIT");
      loop null; end loop;
   end if;

   W5500.Socket0_Connect (Server_IP, Server_Port);
   USART_Driver.Send_Line ("CONNECT enviado");

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
   Print_Hex ("Socket0 final: ", Status);

   if Status = SOCK_ESTABLISHED then
      USART_Driver.Send_Line ("TCP CONNECTED");
   else
      USART_Driver.Send_Line ("Conexion fallida");
   end if;

   
   W5500.Socket0_Close;
   USART_Driver.Send_Line ("Socket cerrado");




    if Resolve_DNS ("uhu.es", DNS_Server, DNS_IP) then --150.214.167.13
      if Ping (DNS_IP) then
       Print_IP ("IP de url: ", DNS_IP);
         USART_Driver.Send_Line (" Dns funcional y destino alcanzable");
      end if;
   end if;


  mDNS_Announce("ejemplo.local");
  
loop
   HTTP_Server_mDNS (80, "ejemplo.local");
end loop;

 loop
     Next_Time := Clock + Milliseconds (1000);
      delay until Next_Time;
  end loop;
end Main;with USART_Driver;  use USART_Driver;
with STM32F446;     use STM32F446;
with Ada.Real_Time; use Ada.Real_Time;
with SPI_Driver;     use SPI_Driver;
with W5500;         use W5500;
with System;

procedure Main is

   My_MAC : Uint8_Array (1 .. 6) := (16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#FE#, 16#ED#);
   My_IP  : Uint8_Array (1 .. 4) := (192, 168, 1, 180);
   My_SN  : Uint8_Array (1 .. 4) := (255, 255, 255, 0);
   My_GW  : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   Google  : Uint8_Array (1 .. 4) := (8, 8, 8, 8);
   DNS_IP  : Uint8_Array (1 .. 4);
   DNS_Server : constant Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   DHCP :  DHCP_Result ;

   Server_IP   : Uint8_Array (1 .. 4) := (192, 168, 1, 1);
   Server_Port : constant Uint16 := 80;
   Local_Port  : constant Uint16 := 5000;

   Version   : Uint8;
   Status    : Uint8;
   Timeout   : Natural;
   Next_Time : Time := Clock;

   --  Reset hardware W5500 
   W5500_RST : constant Natural := 7;

   GPIOC_MODER   : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#00#);
   GPIOC_OSPEEDR : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#08#);
   GPIOC_PUPDR   : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#0C#);
   GPIOC_ODR     : Uint32 with Volatile, Address => System'To_Address (GPIOC + 16#14#);
   RCC_AHB1ENR   : Uint32 with Volatile, Address => System'To_Address (RCC   + 16#30#);

   procedure W5500_HW_Reset is
   begin
      RCC_AHB1ENR := RCC_AHB1ENR or Uint32 (2**GPIOCEN);
      GPIOC_MODER := (GPIOC_MODER
            and not (Uint32 (2**(2*W5500_RST)))
            and not (Uint32 (2**((2*W5500_RST)+1))))
         or Uint32 (2**(2*W5500_RST));
      GPIOC_OSPEEDR := GPIOC_OSPEEDR
         and not (Uint32 (2**(2*W5500_RST)))
         and not (Uint32 (2**((2*W5500_RST)+1)));
      GPIOC_PUPDR := GPIOC_PUPDR
         and not (Uint32 (2**(2*W5500_RST)))
         and not (Uint32 (2**((2*W5500_RST)+1)));
      GPIOC_ODR := GPIOC_ODR and not (Uint32 (2**W5500_RST));
      Next_Time := Clock + Milliseconds (2);
      delay until Next_Time;
      GPIOC_ODR := GPIOC_ODR or Uint32 (2**W5500_RST);
      Next_Time := Clock + Milliseconds (200);
      delay until Next_Time;
   end W5500_HW_Reset;

   

   procedure Print_IP (Label : String; IP : Uint8_Array) is
   begin
      USART_Driver.Send_Line (Label
         & Integer'Image (Integer (IP (IP'First)))     & "."
         & Integer'Image (Integer (IP (IP'First + 1))) & "."
         & Integer'Image (Integer (IP (IP'First + 2))) & "."
         & Integer'Image (Integer (IP (IP'First + 3))));
   end Print_IP;

   procedure Check_Link is
      Phy : Uint8;
   begin
      Phy := W5500.Read_PHYCFGR;
      W5500.Print_Hex ("PHYCFGR: ", Phy);
      if (Phy and 16#01#) /= 0 then
         USART_Driver.Send_Line ("Link Ethernet OK");
      else
         USART_Driver.Send_Line ("Sin link - verifica cable");
      end if;
   end Check_Link;

   procedure Verify_Configuration is
      MAC_R : Uint8_Array (1 .. 6);
      IP_R  : Uint8_Array (1 .. 4);
   begin
      W5500.Get_MAC (MAC_R);
      USART_Driver.Send_Line ("--- Verificacion ---");
      for I in MAC_R'Range loop
         Print_Hex ("MAC[" & Integer'Image (I) & "]: ", MAC_R (I));
      end loop;
      W5500.Get_IP (IP_R);
      Print_IP ("IP leida: ", IP_R);
   end Verify_Configuration;

begin

   USART_Driver.Initialize (115200);
   USART_Driver.Send_Line ("=== W5500 Test ===");
   SPI_Driver.Initialize;
   USART_Driver.Send_Line ("SPI OK");

   
   USART_Driver.Send_Line ("Reseteando W5500...");
   W5500_HW_Reset;
   USART_Driver.Send_Line ("Reset OK");


   Version := W5500.Read_Version;
   Print_Hex ("W5500 VERSION: ", Version);
   if Version /= 16#04# then
      USART_Driver.Send_Line ("ERROR: W5500 no responde");
      loop null; end loop;
   end if;
   USART_Driver.Send_Line ("W5500 OK");

 
   Check_Link;

  
 W5500.Set_MAC     (My_MAC);
 DHCP:=W5500.DHCP_Request;
   if DHCP.Success then
      w5500.Set_IP      (DHCP.IP);
        w5500.Set_Subnet  (DHCP.Subnet);
        w5500.Set_Gateway (DHCP.Gateway);
   else
     
   W5500.Set_Gateway (My_GW);
   W5500.Set_Subnet  (My_SN);
   W5500.Set_IP      (My_IP);

   end if;
   USART_Driver.Send_Line ("Red configurada");
   Verify_Configuration;

   if W5500.Ping (Google, 3000) then
      USART_Driver.Send_Line ("Gateway alcanzable");
   else
      USART_Driver.Send_Line ("Gateway no responde");
   end if;


   W5500.Socket0_Open_TCP (Local_Port);
   USART_Driver.Send_Line ("Socket0 OPEN");

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

   if Status /= SOCK_INIT then
      USART_Driver.Send_Line ("ERROR: socket no llego a INIT");
      loop null; end loop;
   end if;

   W5500.Socket0_Connect (Server_IP, Server_Port);
   USART_Driver.Send_Line ("CONNECT enviado");

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
   Print_Hex ("Socket0 final: ", Status);

   if Status = SOCK_ESTABLISHED then
      USART_Driver.Send_Line ("TCP CONNECTED");
   else
      USART_Driver.Send_Line ("Conexion fallida");
   end if;

   
   W5500.Socket0_Close;
   USART_Driver.Send_Line ("Socket cerrado");




    if Resolve_DNS ("uhu.es", DNS_Server, DNS_IP) then --150.214.167.13
      if Ping (DNS_IP) then
       Print_IP ("IP de url: ", DNS_IP);
         USART_Driver.Send_Line (" Dns funcional y destino alcanzable");
      end if;
   end if;


  mDNS_Announce("ejemplo.local");
  
loop
   HTTP_Server_mDNS (80, "ejemplo.local");
end loop;

 loop
     Next_Time := Clock + Milliseconds (1000);
      delay until Next_Time;
  end loop;
end Main;