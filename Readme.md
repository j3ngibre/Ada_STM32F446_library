
# 🚀 Desarrollo de un Sistema IoT en Lenguaje Ada con Fines Didácticos

[![Licencia](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ada](https://img.shields.io/badge/Language-Ada-ff69b4.svg)](https://www.adacore.com/)
[![Hardware](https://img.shields.io/badge/Hardware-STM32F446-green.svg)](https://www.st.com/en/microcontrollers-microprocessors/stm32f4-series.html)

## Documentación completa y ejemplos de uso

* [Documentación completa](./docs/Doc.pdf)

## 📄 Resumen del Proyecto

Este proyecto presenta el desarrollo de un **sistema IoT utilizando el lenguaje de programación Ada**, diseñado con fines educativos. Basado en el microcontrolador **STM32F446RE**, demuestra que Ada —tradicionalmente utilizado en sistemas críticos y de tiempo real— es una alternativa viable y ventajosa a C/C++ para el desarrollo de sistemas embebidos e IoT.

### 🎯 Objetivos Principales

* Demostrar la viabilidad de Ada para sistemas embebidos e IoT modernos.
* Crear un entorno de desarrollo accesible para Ada sobre hardware ARM Cortex-M.
* Desarrollar un marco modular y reutilizable de paquetes de abstracción de hardware.
* Proporcionar material educativo para la enseñanza de sistemas embebidos y programación en tiempo real.

### 🛠️ Implementación Técnica

El sistema implementa una pila de software completa que incluye:

* **Controladores de periféricos:** GPIO, Temporizadores (Timers), ADC, USART, I2C y SPI.
* **Controladores de dispositivos:** Pantalla OLED SSD1306 y módulo Ethernet W5500.
* **Servicios de red:** TCP/IP, DHCP, DNS, descubrimiento mDNS y servidor HTTP.

### 💡 ¿Por qué Ada en lugar de C/C++?

| Problemas de C/C++        | Ventajas de Ada                                |
| ------------------------- | ---------------------------------------------- |
| Gestión manual de memoria | Tipado fuerte                                  |
| Desbordamientos de búfer  | Verificación de límites en tiempo de ejecución |
| Comportamiento indefinido | Verificación estática                          |
| Concurrencia compleja     | Soporte nativo para tareas (tasking)           |

### 📚 Enfoque Educativo

El proyecto sirve como un recurso de aprendizaje completo para estudiantes y desarrolladores interesados en:

* Programación de sistemas embebidos con Ada.
* Diseño de sistemas en tiempo real.
* Desarrollo IoT con lenguajes seguros y fiables.
* Integración hardware-software.

### 🎯 Resultado

Una **plataforma completa, reutilizable y bien documentada** que demuestra la viabilidad del uso de Ada en aplicaciones IoT, sirviendo tanto como sistema funcional como material educativo.

**Palabras clave:** `Ada` · `IoT` · `STM32` · `Sistemas Embebidos` · `Tiempo Real` · `Educación`
