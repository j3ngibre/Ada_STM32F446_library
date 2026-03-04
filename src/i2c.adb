--Por aqui explicación y eso
--pero vamos linea clock y linea datos fin
--linea 200
--idea en 239
with System;
with Ada.Real_Time; use Ada.Real_Time;

package body I2C is

    -- Registros mapeados en memoria
    RCC_AHB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#30#);

    RCC_APB1ENR : Uint32 with
    Volatile,
    Address => System'To_Address (RCC + 16#40#);

    GPIOB_MODER : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#00#);

    GPIOB_AFRL : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#20#);  -- funcion alt low (pines 0-7)

    GPIOB_AFRH : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#24#);  -- funcion alternativa high (pines 8-15)

    GPIOB_OTYPER : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#04#);  -- open drain

    GPIOB_PUPDR : Uint32 with
    Volatile,
    Address => System'To_Address (GPIOB + 16#0C#);  -- pull-up/pull-down

    -- Registros I2C
    I2C_CR1 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR1A);

    I2C_CR2 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR2A);

    I2C_TIMINGR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_TIMING);

    I2C_ISR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_ISRA);

    I2C_ICR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_ICRA);

    I2C_RXD : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_RXDA);

    I2C_TXD : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_TXDA);

    -- Inicialización I2C a 100 kHz modo normal
    procedure Initialize is
    begin
        RCC_AHB1ENR := RCC_AHB1ENR or (2**1);

        RCC_APB1ENR := RCC_APB1ENR or (2**21);

        delay(0.001);

        GPIOB_AFRH := GPIOB_AFRH and not (16#F# * 2**(0 * 4));
        GPIOB_AFRH := GPIOB_AFRH or (4 * 2**(0 * 4));  -- AF4 = 4

        GPIOB_AFRH := GPIOB_AFRH and not (16#F# * 2**(1 * 4));  -- Limpiar bits para PB9
        GPIOB_AFRH := GPIOB_AFRH or (4 * 2**(1 * 4));  -- AF4 = 4

        --pines funcion alt moder 10
        GPIOB_MODER := GPIOB_MODER and not (3 * 2**(SCL_Pin * 2));
        GPIOB_MODER := GPIOB_MODER or (2 * 2**(SCL_Pin * 2));

        GPIOB_MODER := GPIOB_MODER and not (3 * 2**(SDA_Pin * 2));
        GPIOB_MODER := GPIOB_MODER or (2 * 2**(SDA_Pin * 2));

        --open drain hay que meter pullp
        GPIOB_OTYPER := GPIOB_OTYPER or (2**SCL_Pin);
        GPIOB_OTYPER := GPIOB_OTYPER or (2**SDA_Pin);

        GPIOB_PUPDR := GPIOB_PUPDR or (1 * 2**(SCL_Pin * 2));--los pull
        GPIOB_PUPDR := GPIOB_PUPDR or (1 * 2**(SDA_Pin * 2));

        -- Para 100 kHz: PRESC=1, SCLL=0x79, SCLH=0x4B, SDADEL=0x2, SCLDEL=0x4
        I2C_TIMINGR := 16#00207A4B#;

        I2C_CR1 := I2C_CR1 or (2**I2C_CR1_PE);

        delay(0.01);
    end Initialize;

    -- Select no va
    function Wait_Bus return Boolean is
        Deadline : constant Time := Clock + Milliseconds (100);
    begin
        while (I2C_ISR and (2**I2C_ISR_BUSY)) /= 0 loop
            delay 0.001;  -- Pequeña pausa para no saturar
            if Clock > Deadline then
                return False;
            end if;
        end loop;
        return True;
    end Wait_Bus;

    function Wait_Flag (Flag_Mask : Uint32; Timeout_MS : Positive) return Boolean is
        Deadline : constant Time := Clock + Milliseconds (Timeout_MS);
    begin
        while (I2C_ISR and Flag_Mask) = 0 loop
            if (I2C_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            if Clock > Deadline then
                return False;
            end if;
            delay 0.0001;  -- Pequeña pausa
        end loop;
        return True;
    end Wait_Flag;

    procedure Clear_Errors is
    begin
        I2C_ICR := I2C_ICR or (2**I2C_ISR_NACKF);
        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);
        I2C_ICR := I2C_ICR or (2**I2C_ISR_BERR);
        I2C_ICR := I2C_ICR or (2**I2C_ISR_ARLO);
        I2C_ICR := I2C_ICR or (2**I2C_ISR_OVR);
    end Clear_Errors;

    function I2C_Write (SlaveAddr : Uint8; Data : Uint8) return Boolean is
    begin
        if not Wait_Bus then
            return False;
        end if;

        Clear_Errors;

        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

        if not Wait_Flag (2**I2C_ISR_TXIS, 100) then
            return False;
        end if;

        -- Dato al registro
        I2C_TXD := Uint32 (Data);

        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);
        return True;
    end I2C_Write;

    function I2C_Read (SlaveAddr : Uint8; Data : out Uint8) return Boolean is
    begin
        if not Wait_Bus then
            return False;
        end if;

        Clear_Errors;

        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (2**I2C_CR2_RD_WRN)
                   or (1 * 2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

        if not Wait_Flag (2**I2C_ISR_RXNE, 100) then
            return False;
        end if;

        Data := Uint8 (I2C_RXD and 16#FF#);

        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);
        return True;
    end I2C_Read;

    function I2C_WriteBuffer (SlaveAddr : Uint8;
                              Buffer    : Uint8_Array;
                              Len       : Uint8) return Boolean is
        Index : Uint8 := 0;
    begin
        if not Wait_Bus then
            return False;
        end if;

        Clear_Errors;

        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (Uint32 (Len) * 2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

        while Index < Len loop
            if not Wait_Flag (2**I2C_ISR_TXIS, 100) then
                return False;
            end if;

            I2C_TXD := Uint32 (Buffer (Positive (Index + 1)));  -- Buffer empieza en 1
            Index := Index + 1;
        end loop;

        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);
        return True;
    end I2C_WriteBuffer;

    function I2C_ReadBuffer (SlaveAddr : Uint8;
                             Buffer    : out Uint8_Array;
                             Len       : Uint8) return Boolean is
        Index : Uint8 := 0;
    begin
        if not Wait_Bus then
            return False;
        end if;

        Clear_Errors;

        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (2**I2C_CR2_RD_WRN)
                   or (Uint32 (Len) * 2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

        while Index < Len loop
            if not Wait_Flag (2**I2C_ISR_RXNE, 100) then
                return False;
            end if;

            Buffer (Positive (Index + 1)) := Uint8 (I2C_RXD and 16#FF#);
            Index := Index + 1;
        end loop;

        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);
        return True;
    end I2C_ReadBuffer;

   
    function I2C_WriteRead (SlaveAddr  : Uint8;
                            Write_Data : Uint8;
                            Read_Data  : out Uint8) return Boolean is
    begin
        if not Wait_Bus then
            return False;
        end if;

        Clear_Errors;

        --escritura de 1 byte con AUTOEND
        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (1 * 2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

       
        if not Wait_Flag (2**I2C_ISR_TXIS, 100) then
            return False;
        end if;

    
        I2C_TXD := Uint32 (Write_Data);

       
        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);

       
        I2C_CR2 := ((Uint32 (SlaveAddr) and 16#7F#) * 2**I2C_CR2_SADD)
                   or (2**I2C_CR2_RD_WRN)
                   or (1 * 2**I2C_CR2_NBYTES)
                   or (2**I2C_CR2_AUTOEND)
                   or (2**I2C_CR2_START);

       
        if not Wait_Flag (2**I2C_ISR_RXNE, 100) then
            return False;
        end if;

      
        Read_Data := Uint8 (I2C_RXD and 16#FF#);

  
        if not Wait_Flag (2**I2C_ISR_STOPF, 100) then
            return False;
        end if;

      
        I2C_ICR := I2C_ICR or (2**I2C_ISR_STOPF);

        return True;
    end I2C_WriteRead;

end I2C;