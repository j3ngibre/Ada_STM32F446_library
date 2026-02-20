#!/bin/bash

echo "=== Programando NUCLEO-F446RE con OpenOCD ==="


echo "Compilando..."
alr clean
alr build

echo "Generando firmware.bin..."
arm-eabi-objcopy -O binary bin/main firmware.bin


echo "Programando..."
openocd -f interface/stlink.cfg \
        -f target/stm32f4x.cfg \
        -c "init" \
        -c "reset halt" \
        -c "flash write_image erase firmware.bin 0x08000000" \
        -c "verify_image firmware.bin 0x08000000" \
        -c "reset run" \
        -c "exit"

echo "=== Programación completada ==="
