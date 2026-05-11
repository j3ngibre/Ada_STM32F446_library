-- ============================================================
--  W5500 Mini-Driver
--  SPI Mode 0 (CPOL=0, CPHA=0), MSB first
--  Frame: [Addr_H][Addr_L][(BSB<<3)|(RWB<<2)|OM][Data...]
-- ============================================================
with SPI_Driver;
with STM32F446; use STM32F446;

package W5500 is

   function  Read_Version return Uint8;       -- debe devolver 0x04
   function  Read_PHYCFGR return Uint8;       -- bit 0 = link up

   procedure Set_MAC     (Mac : Uint8_Array); -- 6 bytes
   procedure Set_IP      (IP  : Uint8_Array); -- 4 bytes
   procedure Set_Subnet  (SN  : Uint8_Array); -- 4 bytes
   procedure Set_Gateway (GW  : Uint8_Array); -- 4 bytes
   procedure Get_MAC     (Mac : out Uint8_Array);
   procedure Get_IP      (IP  : out Uint8_Array);

   procedure Socket0_Open_TCP (Local_Port : Uint16);
   procedure Socket0_Connect  (Dest_IP : Uint8_Array; Dest_Port : Uint16);
   function  Socket0_Status   return Uint8;
   procedure Socket0_Close;

   function Ping (Dest_IP    : Uint8_Array;
                  Timeout_MS : Natural := 3000) return Boolean;

   SOCK_CLOSED      : constant Uint8 := 16#00#;
   SOCK_INIT        : constant Uint8 := 16#13#;
   SOCK_LISTEN      : constant Uint8 := 16#14#;
   SOCK_SYNSENT     : constant Uint8 := 16#15#;
   SOCK_ESTABLISHED : constant Uint8 := 16#17#;
   SOCK_CLOSE_WAIT  : constant Uint8 := 16#1C#;
   SOCK_IPRAW       : constant Uint8 := 16#42#;

      procedure Print_Hex (Label : String; Val : Uint8);
private

   procedure Write_Reg  (Addr : Uint16; Block : Uint8; Data : Uint8);
   function  Read_Reg   (Addr : Uint16; Block : Uint8) return Uint8;
   procedure Write_Reg16 (Addr : Uint16; Block : Uint8; Data : Uint16);
   function  Read_Reg16  (Addr : Uint16; Block : Uint8) return Uint16;
   procedure Write_Buf  (Addr : Uint16; Block : Uint8; Data : Uint8_Array);
   procedure Read_Buf   (Addr : Uint16; Block : Uint8; Data : out Uint8_Array);



   -- Control bytes: (BSB<<3) | (RWB<<2) | OM=0
   COMMON_RD : constant Uint8 := 16#00#;
   COMMON_WR : constant Uint8 := 16#04#;
   S0_REG_RD : constant Uint8 := 16#08#;
   S0_REG_WR : constant Uint8 := 16#0C#;
   S0_TX_WR  : constant Uint8 := 16#14#;
   S0_RX_RD  : constant Uint8 := 16#18#;

   -- Common Registers
   REG_MR       : constant Uint16 := 16#0000#;
   REG_GAR      : constant Uint16 := 16#0001#;
   REG_SUBR     : constant Uint16 := 16#0005#;
   REG_SHAR     : constant Uint16 := 16#0009#;
   REG_SIPR     : constant Uint16 := 16#000F#;
   REG_PHYCFGR  : constant Uint16 := 16#002E#;
   REG_VERSIONR : constant Uint16 := 16#0039#;

   -- Socket 0 Registers
   Sn_MR    : constant Uint16 := 16#0000#;
   Sn_CR    : constant Uint16 := 16#0001#;
   Sn_SR    : constant Uint16 := 16#0003#;
   Sn_PORT  : constant Uint16 := 16#0004#;
   Sn_DIPR  : constant Uint16 := 16#000C#;
   Sn_DPORT : constant Uint16 := 16#0010#;
   Sn_TX_FSR : constant Uint16 := 16#0020#;
   Sn_TX_RD  : constant Uint16 := 16#0022#;
   Sn_TX_WR  : constant Uint16 := 16#0024#;
   Sn_RX_RSR : constant Uint16 := 16#0026#;
   Sn_RX_RD  : constant Uint16 := 16#0028#;

   -- Modos Sn_MR
   MR_TCP  : constant Uint8 := 16#01#;
   MR_UDP  : constant Uint8 := 16#02#;
   MR_RAW  : constant Uint8 := 16#03#; -- IPRAW en W5500 (con Sn_PROTO=0x001C)

   -- Comandos Sn_CR
   CR_OPEN    : constant Uint8 := 16#01#;
   CR_CONNECT : constant Uint8 := 16#04#;
   CR_DISCON  : constant Uint8 := 16#08#;
   CR_CLOSE   : constant Uint8 := 16#10#;
   CR_SEND    : constant Uint8 := 16#20#;
   CR_RECV    : constant Uint8 := 16#40#;

   ICMP_ECHO_REQUEST : constant Uint8 := 8;
   ICMP_ECHO_REPLY   : constant Uint8 := 0;

   Ping_Buffer : Uint8_Array (1 .. 128);

   --function  ICMP_Checksum     (Data : Uint8_Array; Length : Natural) return Uint16;
   procedure Socket0_Open_Raw;
   procedure Send_Ping_Request  (Dest_IP : Uint8_Array; Seq : Uint16);
   function  Receive_Ping_Reply (Timeout_MS : Natural) return Boolean;
   Sn_DHAR : constant Uint16 := 16#0006#;
end W5500;