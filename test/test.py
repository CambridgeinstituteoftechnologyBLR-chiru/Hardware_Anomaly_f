import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

async def stream_v2x_packet(dut, payload, mode_sel=0):
    for bit_idx in range(64):
        bit_in = (payload >> bit_idx) & 1
        bit_valid = 1

        dut.ui_in.value = (
            bit_in |
            (bit_valid << 1) |
            (mode_sel << 2)
        )

        await ClockCycles(dut.clk, 1)

    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 1)

async def wait_for_done_pulse(dut):

    for _ in range(200):

        await FallingEdge(dut.clk)

        if dut.uio_out.value.is_resolvable:

            done = int(dut.uio_out.value) & 1

            if done:
                return

    raise TimeoutError("Timeout waiting for done pulse")

@cocotb.test()
async def test_project(dut):

    cocotb.start_soon(
        Clock(dut.clk, 20, units="ns").start()
    )

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("SAFE PAYLOAD")

    await stream_v2x_packet(
        dut,
        0xAA00123400001122
    )

    await wait_for_done_pulse(dut)

    irq = (int(dut.uio_out.value) >> 1) & 1

    assert irq == 0, "Safe packet triggered alarm"

    dut._log.info("MALICIOUS PAYLOAD")

    await stream_v2x_packet(
        dut,
        0x00000000FEFE0000
    )

    await wait_for_done_pulse(dut)

    irq = (int(dut.uio_out.value) >> 1) & 1

    assert irq == 1, "Malicious packet not detected"
