
--  Frame SPI W5500 (3 bytes cabecera + datos):
--    Byte 0 : Addr[15:8]
--    Byte 1 : Addr[7:0]
--    Byte 2 : Control  (BSB | RWB | OM)
--    Byte N : Data bytes

with SPI_Driver;
with USART_Driver; use USART_Driver;

package body W5500 is


  

   --  Escribe un byte en (Addr, Block)
   procedure Write_Reg (Addr : Uint16; Block : Uint8; Data : Uint8) is
   begin
      SPI_Driver.CS_Low;
      SPI_Driver.Write_8 (Uint8 (Addr / 256));       -- Addr high
      SPI_Driver.Write_8 (Uint8 (Addr mod 256));      -- Addr low
      SPI_Driver.Write_8 (Block);                     -- Control
      SPI_Driver.Write_8 (Data);                      -- Dato
      SPI_Driver.CS_High;
   end Write_Reg;

   --  Lee un byte de (Addr, Block)
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

 
   function Read_Version return Uint8 is
   begin
      return Read_Reg (REG_VERSIONR, 16#40#);
    
   end Read_Version;


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

  
   procedure Socket0_Open_TCP (Local_Port : Uint16) is
   begin
      --   Cerrar por si acaso habia algo abierto
      Write_Reg (Sn_CR, S0_REG_WR, CR_CLOSE);

      --Modo TCP
      Write_Reg (Sn_MR, S0_REG_WR, MR_TCP);

      --Puerto local (big-endian)
      Write_Reg (Sn_PORT,     S0_REG_WR, Uint8 (Local_Port / 256));
      Write_Reg (Sn_PORT + 1, S0_REG_WR, Uint8 (Local_Port mod 256));

      -- Comando OPEN -> estado pasa a SOCK_INIT (0x13)
      Write_Reg (Sn_CR, S0_REG_WR, CR_OPEN);
   end Socket0_Open_TCP;

   procedure Socket0_Connect (Dest_IP : Uint8_Array; Dest_Port : Uint16) is
   begin
      --  Escribe IP destino (4 bytes a partir de Sn_DIPR)
      Write_Buf (Sn_DIPR, S0_REG_WR, Dest_IP);

      --  Escribe puerto destino (2 bytes big-endian)
      Write_Reg (Sn_DPORT,     S0_REG_WR, Uint8 (Dest_Port / 256));
      Write_Reg (Sn_DPORT + 1, S0_REG_WR, Uint8 (Dest_Port mod 256));

      --  Comando CONNECT -> estado va a SOCK_SYNSENT (0x15)
      --  y luego a SOCK_ESTABLISHED (0x17) si el servidor acepta
      Write_Reg (Sn_CR, S0_REG_WR, CR_CONNECT);
   end Socket0_Connect;

   function Socket0_Status return Uint8 is
   begin
      return Read_Reg (Sn_SR, S0_REG_RD);
   end Socket0_Status;

   procedure Socket0_Close is
   begin
      Write_Reg (Sn_CR, S0_REG_WR, CR_DISCON);
      -- Espera a SOCK_CLOSED antes de forzar CLOSE
      Write_Reg (Sn_CR, S0_REG_WR, CR_CLOSE);
   end Socket0_Close;

end W5500;