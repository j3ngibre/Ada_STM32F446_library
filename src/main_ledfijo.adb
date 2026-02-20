with System;

procedure Main is

        -- Definiciones de direcciones de memoria
        RCC_Base   : constant := 16#4002_3800#;
        GPIOA_Base : constant := 16#4002_0000#;

        -- Desplazamientos (offsets)
        RCC_AHB1ENR_Offset : constant := 16#30#;
        GPIOx_MODER_Offset  : constant := 16#00#;
        GPIOx_ODR_Offset    : constant := 16#14#;

        -- Tipos
        type Uint32 is mod 2**32;
        for Uint32'Size use 32;

        -- Registros mapeados en memoria
        RCC_AHB1ENR : Uint32 with
        Volatile,
        Address => System'To_Address (RCC_Base + RCC_AHB1ENR_Offset);

        GPIOA_MODER : Uint32 with
        Volatile,
        Address => System'To_Address (GPIOA_Base + GPIOx_MODER_Offset);

        GPIOA_ODR : Uint32 with
        Volatile,
        Address => System'To_Address (GPIOA_Base + GPIOx_ODR_Offset);

        -- Constantes
        IOPAEN_Bit    : constant := 0;
        MODER5_Offset : constant := 10;  -- 5 * 2
        PIN5_High     : constant := 2**5;

begin
        -- Habilitar reloj para GPIOA
        RCC_AHB1ENR := RCC_AHB1ENR or (2**IOPAEN_Bit);

        -- Configurar PA5 como salida
        GPIOA_MODER := GPIOA_MODER and not (3 * 2**MODER5_Offset);
        GPIOA_MODER := GPIOA_MODER or (1 * 2**MODER5_Offset);

        -- Encender LED
        GPIOA_ODR := GPIOA_ODR or PIN5_High;

        -- Bucle infinito
        loop
                null;
        end loop;

end Main;
