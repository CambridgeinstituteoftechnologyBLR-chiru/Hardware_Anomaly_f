Hardware Anomaly Detector
Tiny Tapeout 130nm ASIC Shuttle Author: Chirantan J Tilavalli

Overview
This project implements a Hardware Anomaly Detector, acting as an inline hardware firewall for V2X (Vehicle-to-Everything) cyber attack detection. It is designed for silicon fabrication through the Tiny Tapeout platform.

The system ingests a 64-bit serial data stream, reconstructs it into parallel packets, and runs a mathematical threat-scoring algorithm using a hardcoded neural network (Systolic Array) to detect malicious payloads in real-time. If a threat is detected, an interrupt alarm is triggered.

How It Works
The Pipeline
The architecture is divided into four main stages to process the data stream:

SIPO Ingestion (u_input): Captures 64 bits of serial data and reconstructs the full packet.
Feature Extraction (u_extractor): Slices out targeted data nodes (e.g., spatial coordinates or CAN bus identifiers).
Systolic Array Core (u_core): Performs Two's Complement Multiply-Accumulate (MAC) operations, multiplying the extracted data against hardcoded neural network weights (12 and 88).
Threat Scoring (u_scoring): Evaluates the MAC output against a hardcoded safety threshold (1500).
Threat Evaluation
Below Threshold (< 1500): Payload is deemed safe. The irq pin remains at 0.
Above Threshold (>= 1500): Payload is deemed malicious. The irq alarm pin immediately spikes to 1.
How to Test
The chip evaluates a 64-bit payload injected serially via the input pins.

Test 1: Safe Payload
Inject the serial equivalent of 0xAA00123400001122.
The hardware extracts the middle coordinates (0000).
It calculates a threat score of 0.
The irq alarm pin stays at 0 (Safe).
Test 2: Malicious Cyber Attack
Inject the serial equivalent of 0x00000000FEFE0000.
The hardware extracts FEFE (representing massive positive logic in reverse-wiring).
It calculates a threat score vastly exceeding the 1500 threshold.
The irq alarm pin immediately spikes to 1 (Threat Detected).
External Hardware
No external hardware is strictly required to run this chip. It can be fully driven and monitored using the built-in RP2040 microcontroller on the Tiny Tapeout demo board.
