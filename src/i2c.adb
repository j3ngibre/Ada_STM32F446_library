--Por aqui explicación y eso
--pero vamos linea clock y linea datos fin
with System;

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

    -- Registros I2C1
    I2C1_CR1 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR1);

    I2C1_CR2 : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_CR2);

    I2C1_TIMINGR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_TIMING);

    I2C1_ISR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_ISR);

    I2C1_ICR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_ICR);

    I2C1_RXDR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_RXD);

    I2C1_TXDR : Uint32 with
    Volatile,
    Address => System'To_Address (I2C_Base + I2C_TXD);





    -- El de USART por si ac a


    procedure Delay_Loop (Cycles : Uint32) is
        C : Uint32 := Cycles;
    begin
        while C > 0 loop
            C := C - 1;
        end loop;
    end Delay_Loop;

    -- Inicialización I2C1 a 100 kHz modo normal
    procedure Initialize is
    begin

        RCC_AHB1ENR := RCC_AHB1ENR or (2**1);

    RCC_APB1ENR := RCC_APB1ENR or (2**21);

        Delay_Loop (1000);

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


        -- Para 100 kHz: PRESC=1, SCLL=0x79, SCLH=0x4B, SDADEL=0x2, SCLDEL=0x4 tienes que calcular el valor , haré programita para estas cosas de forma rpida
        I2C_TIMING := 16#00207A4B#;


        I2C_CR1 := I2C_CR1 or (2**I2C_CR1_PE);

        Delay_Loop (10000);
    end Initialize;

    -- Esperar hasta que el bus esté libre
    function Wait_For_Bus return Boolean is
        t : Uint32 := 100000;
    begin
        while (I2C1_ISR and (2**I2C_ISR_BUSY)) /= 0 loop
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;
        return True;
    end Wait_For_Bus;

    -- Limpiar flags de error
    procedure Clear_Errors is
    begin
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_NACKF);
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_STOPF);
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_BERR);
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_ARLO);
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_OVR);
    end Clear_Errors;

    -- Escribir y leer un byte (para dispositivos como sensores)
    function I2C1_Write_Read (Slave_Addr : Uint8;
                              Write_Data : Uint8;
                              Read_Data : out Uint8) return Boolean is
        t : Uint32 := 100000;
    begin
        -- Esperar bus libre
        if not Wait_For_Bus then
            return False;
        end if;

        Clear_Errors;

        -- Configurar CR2 para escritura (1 byte)
        I2C1_CR2 := (Uint32 (Slave_Addr) and 16#7F#) * 2**I2C2_SADD or( 2**I2C_CR2_NBYTES)or (2**I2C_CR2_AUTOEND) or  (2**I2C_CR2_START);

        -- Esperar TXIS (Transmit Interrupt Status)
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_TXIS)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Enviar dato
        I2C1_TXDR := Uint32 (Write_Data);

        -- Esperar TC (Transfer Complete)
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_TC)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Ahora leer (1B)
        I2C1_CR2 := (Uint32 (Slave_Addr) and 16#7F#) * 2**I2C2_SADD or (2**I2C_CR2_RD_WRN) or ( 2**I2C_CR2_NBYTES) or (2**I2C_CR2_AUTOEND) or (2**I2C_CR2_START); -- Esperar RXNE (Receive Data Register Not Empty)
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_RXNE)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Leer dato
        Read_Data := Uint8 (I2C1_RXDR and 16#FF#);

        -- Esperar STOPF
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_STOPF)) = 0 loop
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Limpiar STOPF
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_STOPF);

        return True;
    end I2C1_Write_Read;

    -- Escribir un byte a un dispositivo
    function I2C1_Write (Slave_Addr : Uint8;
                         Data : Uint8) return Boolean is
        t : Uint32 := 100000;
    begin
        if not Wait_For_Bus then
            return False;
        end if;

        Clear_Errors;

        -- Configurar CR2 para escritura (1 byte)
        I2C1_CR2 := (Uint32 (Slave_Addr) and 16#7F#) * 2**I2C2_SADD or
                                            ( 2**I2C_CR2_NBYTES) or
                                                                                                    (2**I2C_CR2_AUTOEND) or
                                                                                                                             (2**I2C_CR2_START);

        -- Esperar TXIS
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_TXIS)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Enviar dato
        I2C1_TXDR := Uint32 (Data);

        -- Esperar STOPF
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_STOPF)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Limpiar STOPF
        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_STOPF);

        return True;
    end I2C1_Write;

    -- Leer un byte 
    function I2C1_Read (Slave_Addr : Uint8;
                        Data : out Uint8) return Boolean is
        t : Uint32 := 100000;
    begin
        if not Wait_For_Bus then
            return False;
        end if;

        Clear_Errors;

        -- Configurar CR2 para lectura (1 byte)
        I2C1_CR2 := (Uint32 (Slave_Addr) and 16#7F#) * 2**I2C2_SADD or(2**I2C_CR2_RD_WRN) or ( 2**I2C_CR2_NBYTES) or (2**I2C_CR2_AUTOEND) or (2**I2C_CR2_START);

                                                                                                -- Esperar RXNE
                                                                                                t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_RXNE)) = 0 loop
            if (I2C1_ISR and (2**I2C_ISR_NACKF)) /= 0 then
                Clear_Errors;
                return False;
            end if;
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;

        -- Leer dato
        Data := Uint8 (I2C1_RXDR and 16#FF#);

        -- Esperar STOPF
        t := 100000;
        while (I2C1_ISR and (2**I2C_ISR_STOPF)) = 0 loop
            t := t - 1;
            if t = 0 then
                return False;
            end if;
        end loop;


        I2C1_ICR := I2C1_ICR or (2**I2C_ISR_STOPF);

        return True;
    end I2C1_Read;


    function I2C1_Write_Buffer (Slave_Addr : Uint8;
                                Buffer : Uint8;
                                Len : Uint8) return Boolean is
        pragma Unreferenced (Buffer, Len);
    begin

        return False;
    end I2C1_Write_Buffer;


    function I2C1_Read_Buffer (Slave_Addr : Uint8;
                               Buffer : out Uint8;
                               Len : Uint8) return Boolean is
        pragma Unreferenced (Buffer, Len);
    begin
        
        return False;
    end I2C1_Read_Buffer;

end I2C;
