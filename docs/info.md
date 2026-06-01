## How it works

The **Hardware Anomaly Detector** is an Application-Specific Integrated Circuit (ASIC) designed to perform real-time threat analysis on 64-bit Vehicle-to-Everything (V2X) data payloads. It utilizes a custom 6-stage hardware pipeline to process data without the overhead of a standard CPU.

The internal architecture is divided into the following stages:
1. **V2X SIPO Ingestion:** A Serial-In, Parallel-Out shift register that securely ingests the 64-bit payload using a valid-bit handshake protocol.
2. **Feature Extractor:** Parses the parallel bus to extract critical telemetry nodes (`node_x0` and `node_x1`) from specific byte locations in the packet.
3. **AXI-Stream DMA:** A flow-control module that regulates data movement between the extractor and the neural core.
4. **Systolic Neural Core:** A hardware multiplier-accumulator (MAC) array containing pre-trained, signed 8-bit weights ($W_{00}=12$, $W_{01}=88$, $W_{10}=-5$, $W_{11}=22$). It performs parallel matrix multiplication on the extracted features.
5. **Threat Scoring:** Compares the MAC results against a hardcoded `THREAT_THRESHOLD` of 1500. 
6. **Output Endpoints:** A registered output block that safely latches the diagnostic score.

If the calculated score exceeds the threshold, the chip immediately drives a `0xFF` to the parallel output bus and spikes a dedicated Hardware Interrupt (IRQ) pin to trigger an external alarm system.

## How to test

To successfully evaluate the anomaly detector, you must simulate the serial data stream and observe the parallel outputs. 

**Pin Setup:**
* `ui_in[0]`: Primary serial data input
* `ui_in[1]`: Data valid signal (pull high during transmission)
* `uo_out[7:0]`: Parallel Diagnostic Score
* `uio_out[1]`: Hardware Interrupt (IRQ) Alarm

**Testing Sequence:**
1. **Reset & Flush:** Apply a low signal to `rst_n` for 10 clock cycles, then pull it high. Send a dummy payload of `0x0000000000000000` to flush any uninitialized (`X`) gate states out of the physical flip-flops.
2. **Send Payload:** To inject a payload, pull `ui_in[1]` HIGH. Over the next 64 clock cycles, feed your 64-bit packet into `ui_in[0]` sequentially from MSB to LSB. **Note:** Data should be transitioned on the *falling edge* of the clock to ensure stable sampling on the rising edge.
3. **Wait for Pipeline:** Once all 64 bits are sent, pull `ui_in[1]` and `ui_in[0]` LOW. Wait 10 clock cycles for the data to propagate through the systolic array and scoring modules.
4. **Read Results:**
   * **Safe Payload (e.g., `0x0000000000000000`):** `uo_out` will read `0x00` and the IRQ pin (`uio_out[1]`) will remain `0`.
   * **Malicious Payload (e.g., `0x0000320000000000`):** `uo_out` will read `0xFF` and the IRQ pin (`uio_out[1]`) will spike to `1`, successfully blocking the threat.

## External hardware

To operate this chip in the real world, you will need:
* **Microcontroller:** An external MCU (such as a Raspberry Pi Pico, Arduino, or ESP32) to manage the clock generation, shift the 64-bit V2X packets serially into `ui_in`, and monitor the IRQ line.
* **Status LEDs (Optional):** LEDs connected to the `uo_out` pins to visualize the diagnostic score, and a dedicated RED warning LED tied to `uio_out[1]` to visually indicate a trapped cyber attack.
