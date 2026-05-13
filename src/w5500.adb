--  Frame SPI W5500: [Addr_H][Addr_L][Control][Data...]
--  Control = (BSB<<3) | (RWB<<2) | OM=0

with Ada.Real_Time; use Ada.Real_Time;
with SPI_Driver;
with USART_Driver; use USART_Driver;

package body W5500 is


   procedure Write_Reg (Addr : Uint16; Block : Uint8; Data : Uint8) is
   begin
      SPI_Driver.CS_Low;
      SPI_Driver.Write_8 (Uint8 (Addr / 256));
      SPI_Driver.Write_8 (Uint8 (Addr mod 256));
      SPI_Driver.Write_8 (Block);
      SPI_Driver.Write_8 (Data);
      SPI_Driver.CS_High;
   end Write_Reg;
   procedure Print_Hex (Label : String; Val : Uint8) is
      Hex : constant array (0 .. 15) of Character := "0123456789ABCDEF";
   begin
      USART_Driver.Send_Line (Label & "0x"
         & Hex (Natural (Val / 16))
         & Hex (Natural (Val mod 16)));
   end Print_Hex;

   function Read_Reg (Addr : Uint16; Block : Uint8) return Uint8 is
      Result : Uint8;
   begin
      SPI_Driver.CS_Low;
      SPI_Driver.Write_8 (Uint8 (Addr / 256));
      SPI_Driver.Write_8 (Uint8 (Addr mod 256));
      SPI_Driver.Write_8 (Block);
      Result := SPI_Driver.Read_8;
      SPI_Driver.CS_High;
      return Result;
   end Read_Reg;

   procedure Write_Buf (Addr : Uint16; Block : Uint8; Data : Uint8_Array) is
   begin
      SPI_Driver.CS_Low;
      SPI_Driver.Write_8 (Uint8 (Addr / 256));
      SPI_Driver.Write_8 (Uint8 (Addr mod 256));
      SPI_Driver.Write_8 (Block);
      SPI_Driver.Write_Buffer (Data);
      SPI_Driver.CS_High;
   end Write_Buf;

   procedure Read_Buf (Addr : Uint16; Block : Uint8; Data : out Uint8_Array) is
   begin
      SPI_Driver.CS_Low;
      SPI_Driver.Write_8 (Uint8 (Addr / 256));
      SPI_Driver.Write_8 (Uint8 (Addr mod 256));
      SPI_Driver.Write_8 (Block);
      SPI_Driver.Read_Buffer (Data);
      SPI_Driver.CS_High;
   end Read_Buf;

   -- Lee/escribe registro de 16 bits big-endian
   function Read_Reg16 (Addr : Uint16; Block : Uint8) return Uint16 is
   begin
      return Uint16 (Read_Reg (Addr,     Block)) * 256
           + Uint16 (Read_Reg (Addr + 1, Block));
   end Read_Reg16;

   procedure Write_Reg16 (Addr : Uint16; Block : Uint8; Data : Uint16) is
   begin
      Write_Reg (Addr,     Block, Uint8 (Data / 256));
      Write_Reg (Addr + 1, Block, Uint8 (Data mod 256));
   end Write_Reg16;



   function Read_Version return Uint8 is
   begin
      return Read_Reg (REG_VERSIONR, COMMON_RD);
   end Read_Version;

   function Read_PHYCFGR return Uint8 is
   begin
      return Read_Reg (REG_PHYCFGR, COMMON_RD);
   end Read_PHYCFGR;

   -- =========================================================
   --  Configuracion de red
   -- =========================================================

   procedure Set_Gateway (GW : Uint8_Array) is
   begin
      Write_Buf (REG_GAR, COMMON_WR, GW);
   end Set_Gateway;

   procedure Set_Subnet (SN : Uint8_Array) is
   begin
      Write_Buf (REG_SUBR, COMMON_WR, SN);
   end Set_Subnet;

   procedure Set_MAC (Mac : Uint8_Array) is
   begin
      Write_Buf (REG_SHAR, COMMON_WR, Mac);
   end Set_MAC;

   procedure Set_IP (IP : Uint8_Array) is
   begin
      Write_Buf (REG_SIPR, COMMON_WR, IP);
   end Set_IP;

   procedure Get_MAC (Mac : out Uint8_Array) is
   begin
      Read_Buf (REG_SHAR, COMMON_RD, Mac);
   end Get_MAC;

   procedure Get_IP (IP : out Uint8_Array) is
   begin
      Read_Buf (REG_SIPR, COMMON_RD, IP);
   end Get_IP;

   -- =========================================================
   --  Socket 0 TCP
   -- =========================================================

   procedure Socket0_Open_TCP (Local_Port : Uint16) is
   begin
      Write_Reg   (Sn_CR,   S0_REG_WR, CR_CLOSE);
      Write_Reg   (Sn_MR,   S0_REG_WR, MR_TCP);
      Write_Reg16 (Sn_PORT, S0_REG_WR, Local_Port);
      Write_Reg   (Sn_CR,   S0_REG_WR, CR_OPEN);
   end Socket0_Open_TCP;

   procedure Socket0_Connect (Dest_IP : Uint8_Array; Dest_Port : Uint16) is
   begin
      Write_Buf   (Sn_DIPR,  S0_REG_WR, Dest_IP);
      Write_Reg16 (Sn_DPORT, S0_REG_WR, Dest_Port);
      Write_Reg   (Sn_CR,    S0_REG_WR, CR_CONNECT);
   end Socket0_Connect;

   function Socket0_Status return Uint8 is
   begin
      return Read_Reg (Sn_SR, S0_REG_RD);
   end Socket0_Status;

   procedure Socket0_Close is
   begin
      Write_Reg (Sn_CR, S0_REG_WR, CR_DISCON);
      Write_Reg (Sn_CR, S0_REG_WR, CR_CLOSE);
   end Socket0_Close;

   -- 
   --  PING — ICMP Echo via socket IPRAW
   -- 
procedure Socket0_Open_Raw is
   T : Time;
begin
   Write_Reg (Sn_CR, S0_REG_WR, CR_CLOSE);
   T := Clock + Milliseconds (10);
   delay until T;

   --  MACRAW: Sn_MR = 0x04 (bit2=1, bits[1:0]=00)
   --  En W5500, 0x03 = MACRAW solo socket 0, pero 0x04 es el valor
   --  correcto segun datasheet v1.0.0 tabla 18: MF=0, MFEN=0, nd=0, MC=0, P=0100
   --  Usamos 0x04 que es MACRAW documentado
   Write_Reg (Sn_MR, S0_REG_WR, 16#04#);
   Write_Reg (Sn_CR, S0_REG_WR, CR_OPEN);
   T := Clock + Milliseconds (50);
   delay until T;
end Socket0_Open_Raw;

procedure Send_Ping_Request (Dest_IP : Uint8_Array; Seq : Uint16) is
   --  Frame completo: Ethernet(14) + IP(20) + ICMP(64) = 98 bytes
   Identifier : constant Uint16  := 16#1234#;
   ICMP_Len   : constant Natural := 64;   -- 8 header + 56 data
   IP_Len     : constant Natural := 20 + ICMP_Len;  -- 84
   Frame_Len  : constant Natural := 14 + IP_Len;    -- 98

   My_MAC  : constant Uint8_Array (1 .. 6) :=
      (16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#FE#, 16#ED#);
   GW_MAC  : constant Uint8_Array (1 .. 6) :=
      (16#C0#, 16#FD#, 16#84#, 16#D6#, 16#97#, 16#5F#);
   My_IP   : constant Uint8_Array (1 .. 4) :=
      (192, 168, 1, 180);

   F       : Uint8_Array (1 .. Frame_Len) := (others => 0);
   Chk     : Uint16;
   TX_Ptr  : Uint16;
   IR      : Uint8;
   Timeout : Natural;

   function IP_Checksum (Data : Uint8_Array; From, Len : Natural) return Uint16 is
      Sum : Uint32 := 0;
      I   : Natural := From;
   begin
      while I + 1 <= From + Len - 1 loop
         Sum := Sum + Uint32 (Data (I)) * 256 + Uint32 (Data (I + 1));
         I := I + 2;
      end loop;
      if I <= From + Len - 1 then
         Sum := Sum + Uint32 (Data (I)) * 256;
      end if;
      while Sum > 16#FFFF# loop
         Sum := (Sum and 16#FFFF#) + (Sum / 16#1_0000#);
      end loop;
      return Uint16 ((not Sum) and 16#FFFF#);
   end IP_Checksum;

begin
   --  === Cabecera Ethernet (bytes 1..14) ===
   --  MAC destino (6)
   F (1) := GW_MAC (1); F (2) := GW_MAC (2); F (3) := GW_MAC (3);
   F (4) := GW_MAC (4); F (5) := GW_MAC (5); F (6) := GW_MAC (6);
   --  MAC origen (6)
   F (7)  := My_MAC (1); F (8)  := My_MAC (2); F (9)  := My_MAC (3);
   F (10) := My_MAC (4); F (11) := My_MAC (5); F (12) := My_MAC (6);
   --  EtherType IPv4 = 0x0800
   F (13) := 16#08#; F (14) := 16#00#;

   --  === Cabecera IP (bytes 15..34) ===
   F (15) := 16#45#;                          -- Version=4, IHL=5
   F (16) := 0;                               -- DSCP/ECN
   F (17) := Uint8 (IP_Len / 256);           -- Total length H
   F (18) := Uint8 (IP_Len mod 256);         -- Total length L  (=84)
   F (19) := 16#00#; F (20) := 16#01#;       -- ID = 1
   F (21) := 0; F (22) := 0;                 -- Flags/Fragment = 0
   F (23) := 64;                              -- TTL
   F (24) := 1;                               -- Protocol = ICMP
   F (25) := 0; F (26) := 0;                 -- IP checksum (provisional)
   --  IP origen
   F (27) := My_IP (1); F (28) := My_IP (2);
   F (29) := My_IP (3); F (30) := My_IP (4);
   --  IP destino
   F (31) := Dest_IP (1); F (32) := Dest_IP (2);
   F (33) := Dest_IP (3); F (34) := Dest_IP (4);

   --  Calcular checksum IP (sobre bytes 15..34)
   Chk := IP_Checksum (F, 15, 20);
   F (25) := Uint8 (Chk / 256);
   F (26) := Uint8 (Chk mod 256);

   --  === ICMP Echo Request (bytes 35..98) ===
   F (35) := 8;   -- Type = Echo Request
   F (36) := 0;   -- Code
   F (37) := 0; F (38) := 0;                          -- Checksum provisional
   F (39) := Uint8 (Identifier / 256);
   F (40) := Uint8 (Identifier mod 256);
   F (41) := Uint8 (Seq / 256);
   F (42) := Uint8 (Seq mod 256);
   for I in 1 .. 56 loop
      F (42 + I) := Uint8 (I mod 256);               -- datos
   end loop;

   --  Calcular checksum ICMP (sobre bytes 35..98)
   Chk := IP_Checksum (F, 35, ICMP_Len);
   F (37) := Uint8 (Chk / 256);
   F (38) := Uint8 (Chk mod 256);

   --  === Escribir en buffer TX ===
   TX_Ptr := Read_Reg16 (Sn_TX_WR, S0_REG_RD);
   Write_Buf (TX_Ptr and 16#07FF#, S0_TX_WR, F);
   Write_Reg16 (Sn_TX_WR, S0_REG_WR, TX_Ptr + Uint16 (Frame_Len));
   Write_Reg (Sn_CR, S0_REG_WR, CR_SEND);

   --  Esperar CR = 0
   Timeout := 0;
   loop
      IR := Read_Reg (Sn_CR, S0_REG_RD);
      exit when IR = 0;
      Timeout := Timeout + 1;
      exit when Timeout > 1000;
      delay until Clock + Milliseconds (1);
   end loop;

   IR := Read_Reg (16#0002#, S0_REG_RD);
   Print_Hex ("DBG Sn_IR: ", IR);
   if (IR and 16#10#) /= 0 then
      USART_Driver.Send_Line ("DBG: SEND_OK");
   end if;
   if (IR and 16#08#) /= 0 then
      USART_Driver.Send_Line ("DBG: SEND TIMEOUT");
   end if;
   Write_Reg (16#0002#, S0_REG_WR, 16#FF#);

end Send_Ping_Request;

function Receive_Ping_Reply (Timeout_MS : Natural) return Boolean is
   Deadline : constant Time := Clock + Milliseconds (Timeout_MS);
   RX_Size  : Uint16;
   RX_Ptr   : Uint16;
   Read_Len : Natural;
   Got_Data : Boolean := False;
   --  En MACRAW el W5500 antepone 2 bytes con la longitud del frame
   --  Luego viene el frame Ethernet completo
   --  ICMP Type está en: 2(macraw_hdr) + 14(eth) + 20(ip) + 1 = byte 37
   ICMP_TYPE_OFF : constant Natural := 37;
begin
   loop
      exit when Clock >= Deadline;

      if Socket0_Status = SOCK_CLOSED then
         USART_Driver.Send_Line ("DBG: socket cerrado");
         return False;
      end if;

      RX_Size := Read_Reg16 (Sn_RX_RSR, S0_REG_RD);

      if RX_Size > 0 then
         Got_Data := True;
         Read_Len := Natural (RX_Size);
         if Read_Len > Ping_Buffer'Length then
            Read_Len := Ping_Buffer'Length;
         end if;

         RX_Ptr := Read_Reg16 (Sn_RX_RD, S0_REG_RD);
         Read_Buf (RX_Ptr, S0_RX_RD, Ping_Buffer (1 .. Read_Len));
         Write_Reg16 (Sn_RX_RD, S0_REG_WR, RX_Ptr + Uint16 (Read_Len));
         Write_Reg   (Sn_CR,    S0_REG_WR, CR_RECV);

         Print_Hex ("DBG RX bytes: ", Uint8 (Read_Len));
         --  Volcar primeros 40 bytes
         for I in 1 .. Natural'Min (Read_Len, 40) loop
            Print_Hex ("DBG[" & Integer'Image (I) & "]: ", Ping_Buffer (I));
         end loop;

         if Read_Len >= ICMP_TYPE_OFF then
            Print_Hex ("DBG ICMP_TYPE: ", Ping_Buffer (ICMP_TYPE_OFF));
            if Ping_Buffer (ICMP_TYPE_OFF) = ICMP_ECHO_REPLY then
               return True;
            end if;
         end if;
      end if;

      delay until Clock + Milliseconds (10);
   end loop;

   if not Got_Data then
      USART_Driver.Send_Line ("DBG: no llego ningun dato al RX");
   end if;
   return False;
end Receive_Ping_Reply;

   function Ping (Dest_IP    : Uint8_Array;
                  Timeout_MS : Natural := 3000) return Boolean is
      Success : Boolean;
      Status  : Uint8;
   begin
      USART_Driver.Send_Line ("=== PING ===");

      Socket0_Open_Raw;

      --  Verificar apertura — estado esperado tras OPEN en IPRAW = SOCK_IPRAW (0x32)
      Status := Socket0_Status;
      Print_Hex ("Socket Raw status: ", Status);
      if Status /= SOCK_IPRAW then
         USART_Driver.Send_Line ("ERROR: socket Raw no abrio (esperado 0x32)");
         Socket0_Close;
         return False;
      end if;

      Send_Ping_Request (Dest_IP, 1);
      USART_Driver.Send_Line ("Ping request enviado");

      Success := Receive_Ping_Reply (Timeout_MS);

      Socket0_Close;

      if Success then
         USART_Driver.Send_Line ("Ping OK!");
      else
         USART_Driver.Send_Line ("Ping timeout");
      end if;

      return Success;
   end Ping;



--  Socket 1 UDP (para DNS)

procedure Socket1_Open_UDP (Local_Port : Uint16) is
   T : constant Time := Clock + Milliseconds (10);
begin
   Write_Reg   (Sn_CR,   S1_REG_WR, CR_CLOSE);
   delay until T;
   Write_Reg   (Sn_MR,   S1_REG_WR, MR_UDP);
   Write_Reg16 (Sn_PORT, S1_REG_WR, Local_Port);
   Write_Reg   (Sn_CR,   S1_REG_WR, CR_OPEN);
   delay until Clock + Milliseconds (10);
end Socket1_Open_UDP;

procedure Socket1_Close is
begin
   Write_Reg (Sn_CR, S1_REG_WR, CR_CLOSE);
end Socket1_Close;

function Socket1_Status return Uint8 is
begin
   return Read_Reg (Sn_SR, S1_REG_RD);
end Socket1_Status;


--  DNS


function Resolve_DNS (Hostname   : String;
                      DNS_Server : Uint8_Array;
                      IP_Out     : out Uint8_Array;
                      Timeout_MS : Natural := 3000) return Boolean is

   --  Construye la sección QNAME del DNS a partir del hostname
   --  "www.google.com" -> 03 77 77 77 06 67 6F 6F 67 6C 65 03 63 6F 6D 00
   procedure Encode_Name (Buf    : in out Uint8_Array;
                           Offset : in out Natural;
                           Name   : String) is
      Label_Start : Natural := Name'First;
      Len         : Natural;
   begin
      for I in Name'First .. Name'Last + 1 loop
         if I = Name'Last + 1 or else Name (I) = '.' then
            Len := I - Label_Start;
            Buf (Offset) := Uint8 (Len);
            Offset := Offset + 1;
            for J in Label_Start .. I - 1 loop
               Buf (Offset) := Character'Pos (Name (J));
               Offset := Offset + 1;
            end loop;
            Label_Start := I + 1;
         end if;
      end loop;
      Buf (Offset) := 0;   -- terminador
      Offset := Offset + 1;
   end Encode_Name;

   TX_ID      : constant Uint16 := 16#ABCD#;
   Pkt_Len    : Natural;
   TX_Ptr     : Uint16;
   RX_Size    : Uint16;
   RX_Ptr     : Uint16;
   Read_Len   : Natural;
   Deadline   : constant Time := Clock + Milliseconds (Timeout_MS);
   Off        : Natural;
   Ancount    : Uint16;
   Qdcount    : Uint16;
   Rtype      : Uint16;
   Rdlen      : Uint16;
   Found      : Boolean := False;

begin
   IP_Out := (others => 0);
   Socket1_Open_UDP (16#0400#);   -- puerto local 1024

   if Socket1_Status /= SOCK_UDP then
      USART_Driver.Send_Line ("DNS: error abriendo socket UDP");
      return False;
   end if;

   --  Apuntar al servidor DNS
   Write_Buf   (Sn_DIPR,  S1_REG_WR, DNS_Server);
   Write_Reg16 (Sn_DPORT, S1_REG_WR, 53);

   --  Construir paquete DNS en DNS_Buffer
   DNS_Buffer := (others => 0);

   --  Header DNS (12 bytes)
   DNS_Buffer (1)  := Uint8 (TX_ID / 256);
   DNS_Buffer (2)  := Uint8 (TX_ID mod 256);
   DNS_Buffer (3)  := 16#01#;   -- QR=0 query, OPCODE=0, RD=1
   DNS_Buffer (4)  := 16#00#;
   DNS_Buffer (5)  := 16#00#; DNS_Buffer (6)  := 16#01#;  -- QDCOUNT=1
   DNS_Buffer (7)  := 16#00#; DNS_Buffer (8)  := 16#00#;  -- ANCOUNT=0
   DNS_Buffer (9)  := 16#00#; DNS_Buffer (10) := 16#00#;  -- NSCOUNT=0
   DNS_Buffer (11) := 16#00#; DNS_Buffer (12) := 16#00#;  -- ARCOUNT=0

   --  QNAME
   Off := 13;
   Encode_Name (DNS_Buffer, Off, Hostname);

   --  QTYPE=A (0x0001), QCLASS=IN (0x0001)
   DNS_Buffer (Off)     := 16#00#; DNS_Buffer (Off + 1) := 16#01#;
   DNS_Buffer (Off + 2) := 16#00#; DNS_Buffer (Off + 3) := 16#01#;
   Pkt_Len := Off + 3;

   --  Enviar por socket 1 UDP
   TX_Ptr := Read_Reg16 (Sn_TX_WR, S1_REG_RD);
   Write_Buf   (TX_Ptr and 16#07FF#, S1_TX_WR, DNS_Buffer (1 .. Pkt_Len));
   Write_Reg16 (Sn_TX_WR, S1_REG_WR, TX_Ptr + Uint16 (Pkt_Len));
   Write_Reg   (Sn_CR,    S1_REG_WR, CR_SEND);

   USART_Driver.Send_Line ("DNS: query enviada para " & Hostname);

   --  Esperar respuesta
   loop
      exit when Clock >= Deadline;

      RX_Size := Read_Reg16 (S1_RX_RSR, S1_REG_RD);

      if RX_Size > 0 then
         Read_Len := Natural (RX_Size);
         if Read_Len > DNS_Buffer'Length then
            Read_Len := DNS_Buffer'Length;
         end if;

         RX_Ptr := Read_Reg16 (S1_RX_RD_R, S1_REG_RD);
         Read_Buf (RX_Ptr, S1_RX_RD, DNS_Buffer (1 .. Read_Len));
         Write_Reg16 (S1_RX_RD_R, S1_REG_WR, RX_Ptr + Uint16 (Read_Len));
         Write_Reg   (Sn_CR, S1_REG_WR, CR_RECV);

         --  En UDP el W5500 antepone 8 bytes: IP(4) + Port(2) + Size(2)
         --  El paquete DNS empieza en offset 9
         Off := 9;

         --  Verificar ID de respuesta
         if Read_Len < Off + 12 then
            USART_Driver.Send_Line ("DNS: respuesta demasiado corta");
            Socket1_Close;
            return False;
         end if;

         declare
            RX_ID : constant Uint16 :=
               Uint16 (DNS_Buffer (Off)) * 256 +
               Uint16 (DNS_Buffer (Off + 1));
         begin
            if RX_ID /= TX_ID then
               USART_Driver.Send_Line ("DNS: ID no coincide");
               Socket1_Close;
               return False;
            end if;
         end;

         --  ANCOUNT (offset 7-8 del DNS)
         Ancount := Uint16 (DNS_Buffer (Off + 6)) * 256 +
                    Uint16 (DNS_Buffer (Off + 7));
         Qdcount := Uint16 (DNS_Buffer (Off + 4)) * 256 +
                    Uint16 (DNS_Buffer (Off + 5));

         Print_Hex ("DNS ANCOUNT: ", Uint8 (Ancount));

         if Ancount = 0 then
            USART_Driver.Send_Line ("DNS: sin respuestas (NXDOMAIN?)");
            Socket1_Close;
            return False;
         end if;

         --  Saltar cabecera DNS (12 bytes) + sección Question
         --  Off apunta al inicio del paquete DNS
         Off := Off + 12;  -- saltar cabecera

         --  Saltar QDCOUNT preguntas: cada una es QNAME + 4 bytes
         for Q in 1 .. Natural (Qdcount) loop
            --  Saltar QNAME (puede tener compresión o etiquetas)
            loop
               exit when Off > Read_Len;
               declare
                  Label_Len : constant Uint8 := DNS_Buffer (Off);
               begin
                  if Label_Len = 0 then
                     Off := Off + 1;   -- consumir el 0x00 final
                     exit;
                  elsif (Label_Len and 16#C0#) = 16#C0# then
                     Off := Off + 2;   -- puntero de compresión = 2 bytes
                     exit;
                  else
                     Off := Off + 1 + Natural (Label_Len);
                  end if;
               end;
            end loop;
            Off := Off + 4;   -- QTYPE + QCLASS
         end loop;

         --  Leer sección Answer
         for A in 1 .. Natural (Ancount) loop
            exit when Off > Read_Len;

            --  Saltar NAME (normalmente puntero de compresión 0xC0 XX)
            if (DNS_Buffer (Off) and 16#C0#) = 16#C0# then
               Off := Off + 2;
            else
               loop
                  exit when Off > Read_Len;
                  declare
                     L : constant Uint8 := DNS_Buffer (Off);
                  begin
                     if L = 0 then
                        Off := Off + 1; exit;
                     elsif (L and 16#C0#) = 16#C0# then
                        Off := Off + 2; exit;
                     else
                        Off := Off + 1 + Natural (L);
                     end if;
                  end;
               end loop;
            end if;

            exit when Off + 10 > Read_Len;

            Rtype := Uint16 (DNS_Buffer (Off))     * 256 +
                     Uint16 (DNS_Buffer (Off + 1));
            --  CLASS en Off+2, Off+3  (ignorar)
            --  TTL   en Off+4 .. Off+7 (ignorar)
            Rdlen := Uint16 (DNS_Buffer (Off + 8)) * 256 +
                     Uint16 (DNS_Buffer (Off + 9));
            Off := Off + 10;

            if Rtype = 1 and then Rdlen = 4 then
               --  Tipo A, IPv4
               IP_Out (1) := DNS_Buffer (Off);
               IP_Out (2) := DNS_Buffer (Off + 1);
               IP_Out (3) := DNS_Buffer (Off + 2);
               IP_Out (4) := DNS_Buffer (Off + 3);
               Found := True;
               exit;
            end if;

            Off := Off + Natural (Rdlen);   -- saltar RDATA si no es tipo A
         end loop;

         Socket1_Close;

         if Found then
            USART_Driver.Send_Line ("DNS OK: " &
               Integer'Image (Natural (IP_Out (1))) & "." &
               Integer'Image (Natural (IP_Out (2))) & "." &
               Integer'Image (Natural (IP_Out (3))) & "." &
               Integer'Image (Natural (IP_Out (4))));
            return True;
         else
            USART_Driver.Send_Line ("DNS: no se encontro registro A");
            return False;
         end if;
      end if;

      delay until Clock + Milliseconds (10);
   end loop;

   USART_Driver.Send_Line ("DNS: timeout esperando respuesta");
   Socket1_Close;
   return False;
end Resolve_DNS;


procedure Socket0_Listen (Local_Port : Uint16) is
begin
   Write_Reg   (Sn_CR,   S0_REG_WR, CR_CLOSE);
   delay until Clock + Milliseconds (5);
   Write_Reg   (Sn_MR,   S0_REG_WR, MR_TCP);
   Write_Reg16 (Sn_PORT, S0_REG_WR, Local_Port);
   Write_Reg   (Sn_CR,   S0_REG_WR, CR_OPEN);
   delay until Clock + Milliseconds (5);
   Write_Reg   (Sn_CR,   S0_REG_WR, CR_LISTEN);
   --  CR_LISTEN = 0x02
end Socket0_Listen;

procedure Socket0_Send (Data : Uint8_Array) is
   TX_Ptr  : Uint16;
   TX_Free : Uint16;
   Sent    : Natural := 0;
   Chunk   : Natural;
   Timeout : Natural;
   IR      : Uint8;
begin
   while Sent < Data'Length loop
      --  Esperar espacio libre en TX
      loop
         TX_Free := Read_Reg16 (Sn_TX_FSR, S0_REG_RD);
         exit when TX_Free > 0;
         delay until Clock + Milliseconds (1);
      end loop;

      Chunk := Natural'Min (Data'Length - Sent, Natural (TX_Free));

      TX_Ptr := Read_Reg16 (Sn_TX_WR, S0_REG_RD);
      Write_Buf   (TX_Ptr and 16#07FF#, S0_TX_WR,
                   Data (Data'First + Sent .. Data'First + Sent + Chunk - 1));
      Write_Reg16 (Sn_TX_WR, S0_REG_WR, TX_Ptr + Uint16 (Chunk));
      Write_Reg   (Sn_CR,    S0_REG_WR, CR_SEND);

      --  Esperar SEND_OK
      Timeout := 0;
      loop
         IR := Read_Reg (16#0002#, S0_REG_RD);  -- Sn_IR
         exit when (IR and 16#10#) /= 0;         -- SEND_OK
         exit when (IR and 16#08#) /= 0;         -- TIMEOUT
         exit when Timeout > 2000;
         Timeout := Timeout + 1;
         delay until Clock + Milliseconds (1);
      end loop;
      Write_Reg (16#0002#, S0_REG_WR, 16#FF#);  -- limpiar Sn_IR

      Sent := Sent + Chunk;
   end loop;
end Socket0_Send;

function Socket0_Recv (Max_Len : Natural) return Natural is
   RX_Size : Uint16;
   RX_Ptr  : Uint16;
   Read_Len : Natural;
begin
   RX_Size := Read_Reg16 (Sn_RX_RSR, S0_REG_RD);
   if RX_Size = 0 then
      return 0;
   end if;

   Read_Len := Natural'Min (Natural (RX_Size), Max_Len);
   RX_Ptr   := Read_Reg16 (Sn_RX_RD, S0_REG_RD);
   Read_Buf (RX_Ptr, S0_RX_RD, HTTP_Buffer (1 .. Read_Len));
   Write_Reg16 (Sn_RX_RD, S0_REG_WR, RX_Ptr + Uint16 (Read_Len));
   Write_Reg   (Sn_CR,    S0_REG_WR, CR_RECV);
   return Read_Len;
end Socket0_Recv;

--server http

procedure HTTP_Server (Port : Uint16 := 80) is

   HTML : constant String :=
      "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
      "Content-Type: text/html; charset=utf-8" & ASCII.CR & ASCII.LF &
      "Connection: close" & ASCII.CR & ASCII.LF &
      "Content-Length: 31" & ASCII.CR & ASCII.LF &
      ASCII.CR & ASCII.LF &
      "<h1>Pagina de prueba</h1>";
   --  Content-Length = 25 chars de <h1>Pagina de prueba</h1>
   --  Ajusta si cambias el body

   HTML_Buf : Uint8_Array (1 .. HTML'Length);
   Status   : Uint8;
   Timeout  : Natural;
   Got_Data : Boolean;

begin
   --  Convertir String a Uint8_Array
   for I in HTML'Range loop
      HTML_Buf (I - HTML'First + 1) := Character'Pos (HTML (I));
   end loop;

   USART_Driver.Send_Line ("HTTP: escuchando en puerto " &
      Integer'Image (Natural (Port)));

   Socket0_Listen (Port);

   --  Esperar conexión entrante (SOCK_ESTABLISHED = 0x17)
   Timeout := 0;
   loop
      Status := Socket0_Status;
      exit when Status = SOCK_ESTABLISHED;
      exit when Timeout > 30_000;   -- 30 segundos máximo
      Timeout := Timeout + 1;
      delay until Clock + Milliseconds (1);
   end loop;

   if Socket0_Status /= SOCK_ESTABLISHED then
      USART_Driver.Send_Line ("HTTP: timeout esperando conexion");
      Socket0_Close;
      return;
   end if;

   USART_Driver.Send_Line ("HTTP: cliente conectado");

   --  Esperar a recibir la petición GET (o cualquier dato)
   Got_Data := False;
   Timeout  := 0;
   loop
      if Socket0_Recv (HTTP_Buffer'Length) > 0 then
         Got_Data := True;
         exit;
      end if;
      --  El cliente puede cerrar tras enviar (CLOSE_WAIT)
      Status := Socket0_Status;
      exit when Status = SOCK_CLOSE_WAIT;
      exit when Timeout > 5000;
      Timeout := Timeout + 1;
      delay until Clock + Milliseconds (1);
   end loop;

   if Got_Data then
      --  Imprimir el método recibido (primeros bytes = "GET / HTTP/1.1")
      USART_Driver.Send_Line ("HTTP: peticion recibida");
   end if;

   --  Enviar respuesta
   Socket0_Send (HTML_Buf);
   USART_Driver.Send_Line ("HTTP: respuesta enviada");

   --  Cerrar conexión limpiamente
   delay until Clock + Milliseconds (10);
   Socket0_Close;
   USART_Driver.Send_Line ("HTTP: conexion cerrada");

end HTTP_Server;
end W5500;