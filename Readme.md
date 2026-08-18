# 🚀 Desarrollo de un Sistema IoT en Lenguaje Ada con Fines Didácticos

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ada](https://img.shields.io/badge/Language-Ada-ff69b4.svg)](https://www.adacore.com/)
[![Hardware](https://img.shields.io/badge/Hardware-STM32F446-green.svg)](https://www.st.com/en/microcontrollers-microprocessors/stm32f4-series.html)

## Full documentation and examples of use
- [ Full documentation](./docs/Doc.pdf)


## 📄 Project Summary

This project presents the development of an **IoT system using the Ada programming language**, designed with educational purposes in mind. Built around the **STM32F446RE** microcontroller, it demonstrates that Ada—traditionally used in critical and real-time systems—is a viable and advantageous alternative to C/C++ for embedded IoT development.

### 🎯 Key Objectives

- Demonstrate Ada's viability for modern IoT and embedded systems
- Create an accessible development environment for Ada on ARM Cortex-M hardware
- Develop a modular and reusable framework of hardware abstraction packages
- Provide educational material for teaching embedded systems and real-time programming

### 🛠️ Technical Implementation

The system implements a complete software stack including:

- **Peripheral drivers:** GPIO, Timers, ADC, USART, I2C, SPI
- **Device controllers:** SSD1306 OLED display, W5500 Ethernet module
- **Network services:** TCP/IP, DHCP, DNS, mDNS discovery, HTTP server

### 💡 Why Ada Over C/C++?

| C/C++ Issues | Ada Advantages |
|--------------|----------------|
| Manual memory management | Strong typing |
| Buffer overflows | Runtime bounds checks |
| Undefined behavior | Static verification |
| Complex concurrency | Native tasking support |

### 📚 Educational Focus

The project serves as a complete learning resource for students and developers interested in:

- Embedded systems programming with Ada
- Real-time systems design
- IoT development with safe and reliable languages
- Hardware-software integration

### 🎯 Result

A **complete, reusable, and well-documented platform** that demonstrates the feasibility of using Ada for IoT applications while serving as both a functional system and educational material.

**Keywords:** `Ada` · `IoT` · `STM32` · `Embedded Systems` · `Real-Time` · `Education`
