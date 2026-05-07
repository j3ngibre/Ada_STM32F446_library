-- ============================================================
--  W5500 Mini-Driver  (Arduino Ethernet Shield V2)
--  Protocolo SPI: modo 0 (CPOL=0, CPHA=0), MSB first
--  Frame W5500: [Addr_H][Addr_L][Control][Data...]
--    Control = BSB(4:2) | RWB(1) | OM(0)  (OM=0 -> VDM/1 byte)
--    BSB=00000 -> Common Register Block
--    BSB=00001 -> Socket 0 Register Block
--    BSB=00010 -> Socket 0 TX Buffer
--    BSB=00011 -> Socket 0 RX Buffer
--    RWB: 0=Read, 1=Write
-- ============================================================
with SPI_Driver;
with STM32F446; use STM32F446;

package W5500 is

   -- ---------------------------------------------------------
   --  Verificacion de comunicacion
   -- ---------------------------------------------------------
   --  Lee VERSIONR (0x0039) -> debe devolver 0x04
   function Read_Version return Uint8;

   -- ---------------------------------------------------------
   --  Configuracion de red (Common Registers)
   -- ---------------------------------------------------------
   procedure Set_MAC     (Mac : Uint8_Array);   -- 6 bytes
   procedure Set_IP      (IP  : Uint8_Array);   -- 4 bytes
   procedure Set_Subnet  (SN  : Uint8_Array);   -- 4 bytes
   procedure Set_Gateway (GW  : Uint8_Array);   -- 4 bytes

   -- Lectura de vuelta para verificar
   procedure Get_MAC     (Mac : out Uint8_Array);
   procedure Get_IP      (IP  : out Uint8_Array);

   -- ---------------------------------------------------------
   --  Socket 0
   -- ---------------------------------------------------------
   --  Abre Socket 0 en modo TCP como cliente o servidor
   --  Port: puerto local en network-byte-order (big-endian)
   procedure Socket0_Open_TCP (Local_Port : Uint16);

   --  Conectar a un servidor remoto (modo TCP cliente)
   procedure Socket0_Connect  (Dest_IP : Uint8_Array; Dest_Port : Uint16);

   --  Consulta estado del socket (registro Sn_SR)
   function  Socket0_Status return Uint8;

   --  Cierra el socket limpiamente
   procedure Socket0_Close;

   -- ---------------------------------------------------------
   --  Constantes utiles de estado (Sn_SR)
   -- ---------------------------------------------------------
   SOCK_CLOSED      : constant Uint8 := 16#00#;
   SOCK_INIT        : constant Uint8 := 16#13#;
   SOCK_LISTEN      : constant Uint8 := 16#14#;
   SOCK_SYNSENT     : constant Uint8 := 16#15#;
   SOCK_ESTABLISHED : constant Uint8 := 16#17#;
   SOCK_CLOSE_WAIT  : constant Uint8 := 16#1C#;



   -- ---------------------------------------------------------
   --  Primitivas SPI de bajo nivel W5500
   -- ---------------------------------------------------------
   procedure Write_Reg  (Addr : Uint16; Block : Uint8; Data : Uint8);
   function  Read_Reg   (Addr : Uint16; Block : Uint8) return Uint8;

   procedure Write_Buf  (Addr : Uint16; Block : Uint8; Data : Uint8_Array);
   procedure Read_Buf   (Addr : Uint16; Block : Uint8; Data : out Uint8_Array);
private
   -- ---------------------------------------------------------
   --  Bloques de seleccion (BSB << 3, bit RWB en posicion 2)
   -- ---------------------------------------------------------
   --  Control byte = (BSB shl 3) or (RW shl 2) or OM
   --  OM = 0  -> Variable Data Length
   COMMON_RD : constant Uint8 := 16#40#; 
   COMMON_WR : constant Uint8 := 16#00#;  
   S0_REG_RD : constant Uint8 := 16#08#;  --Leer  registros sockets0 --esto puedo estar mal
   S0_REG_WR : constant Uint8 := 16#0C#;  --Escribir registros de sockets0 --esto puedo estar mal
   S0_TX_WR  : constant Uint8 := 16#14#;  -- Escribir datos buffers de transmision  socket0 --esto puedo estar mal
   S0_RX_RD  : constant Uint8 := 16#18#;  --Leer datos del buffer de recepcion  socket0 --esto puedo estar mal

   
   --  Common Register offsets
 
   REG_MR      : constant Uint16 := 16#0000#; -- Mode
   REG_GAR     : constant Uint16 := 16#0001#; -- Gateway  (4 bytes)
   REG_SUBR    : constant Uint16 := 16#0005#; -- Subnet Mask (4 bytes)
   REG_SHAR    : constant Uint16 := 16#0009#; -- MAC Address (6 bytes)
   REG_SIPR    : constant Uint16 := 16#000F#; -- Source IP   (4 bytes)
   REG_VERSIONR: constant Uint16 := 16#0039#; -- 
 
   --  Socket 0 Register offsets (bloque S0_REG)
   
   Sn_MR   : constant Uint16 := 16#0000#; -- Socket Mode
   Sn_CR   : constant Uint16 := 16#0001#; -- Socket Command
   Sn_SR   : constant Uint16 := 16#0003#; -- Socket Status
   Sn_PORT : constant Uint16 := 16#0004#; -- (2 bytes)
   Sn_DIPR : constant Uint16 := 16#000C#; -- (4 bytes)
   Sn_DPORT: constant Uint16 := 16#0010#; --(2 bytes)

   -- Sn_MR valores
   MR_TCP  : constant Uint8 := 16#01#;

   -- Sn_CR comandos
   CR_OPEN    : constant Uint8 := 16#01#;
   CR_CONNECT : constant Uint8 := 16#04#;
   CR_DISCON  : constant Uint8 := 16#08#;
   CR_CLOSE   : constant Uint8 := 16#10#;

end W5500;