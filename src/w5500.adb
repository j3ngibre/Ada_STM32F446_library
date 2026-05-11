--  Frame SPI W5500: [Addr_H][Addr_L][Control][Data...]
--  Control = (BSB<<3) | (RWB<<2) | OM=0

with Ada.Real_Time; use Ada.Real_Time;
with SPI_Driver;
with USART_Driver; use USART_Driver;

package body W5500 is

   -- =========================================================
   --  Primitivas SPI
   -- =========================================================

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

   -- =========================================================
   --  Verificacion
   -- =========================================================

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

end W5500;