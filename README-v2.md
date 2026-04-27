# Tilt-Controlled Catch Game
### Made by Panav, Ananya and Manvik

This is an interactive game developed for the nRF52833 SoC (micro:bit v2). Built in ARM assembly at the register level, the system operates without any OS/libraries . It demonstrates seamless hardware-software integration where byte of movement and sound is controlled directly by the CPU through manual register manipulation.

### Key Features
* **Tilt-Based Navigation:** Moves a 3-LED basket across the bottom row using real-time accelerometer data.
* **Dynamic Physics Engine:** Handles falling ball mechanics where the speed increases automatically as the player scores.
* **Advanced Game Logic:** Features a FSM to manage states like "Playing," "Caught," and "Game Over".
* **Immersive Feedback:** Provides major-chord for successful catches and minor-keys for misses.
* **Visual HUD:** Displays remaining lives as a shrinking LED block in the corner of the matrix.
* **Interactive Challenges:** Includes a "Hard Mode" that allows players to manually shrink the basket size for increased difficulty.

### Architecture Concepts Covered
* **Memory-mapped I/O:** Direct control of the LED matrix, speaker, and buttons via specific memory addresses.
* **Stack operations:** Every subroutine utilizes explicit `push`/`pop` instructions to manage the stack and link register correctly.
* **Finite State Machine (FSM):** Structured with 4 primary states (Playing, Caught, Missed, Game Over) and well-defined transition triggers.
* **I2C peripheral communication:** Implemented via the TWIM0 EasyDMA controller to interface with the on-board accelerometer.
* **Bit manipulation:** High-speed LED multiplexing using precomputed bitmasks to eliminate runtime overhead.

### Technical Components
* **LSM303AGR Accelerometer:** Polled via I2C to provide responsive movement based on physical board orientation.
* **Dual-Port GPIO Management:** Utilizes both GPIO Port 0 and Port 1 registers to drive the 5x5 LED matrix, including a dedicated handler for Column 4.
* **LED Matrix Multiplexing:** Cycles through rows at approximately 2000 cycles per row to create the illusion of a fully lit display using only 10 pins.
* **Sound Generation:** Square-wave generation achieved by toggling GPIO pins at audio frequencies derived from the 64 MHz CPU clock.
* **Bare-Metal Toolchain:** Developed using the `arm-none-eabi-gcc` assembler and debugged via GDB and OpenOCD.
