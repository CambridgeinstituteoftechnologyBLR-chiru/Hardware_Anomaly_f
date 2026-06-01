`timescale 1ns/1ps
`default_nettype none

module tt_um_hardware_anomaly_detection (
    input  wire [7:0] ui_in,
    output reg  [7:0] uo_out,
    input  wire [7:0] uio_in,
    output reg  [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Inputs
    wire serial_bit = ui_in[0];
    wire bit_valid  = ui_in[1];
    wire mode_sel   = ui_in[2];
    wire start      = ui_in[3];

    // Packet Receiver
    reg [63:0] packet;
    reg [5:0] bit_count;
    reg packet_ready;

    // Features
    reg signed [7:0] x0;
    reg signed [7:0] x1;

    // MAC Engine
    reg signed [15:0] mac_result;
    reg [7:0] score;

    // Status
    reg irq;
    reg done;
    reg uart_tx;

    assign uio_oe = 8'b0000_0111;

    always @(posedge clk or negedge rst_n) begin

        if(!rst_n) begin

            packet       <= 64'd0;
            bit_count    <= 6'd0;
            packet_ready <= 1'b0;

            x0 <= 0;
            x1 <= 0;

            mac_result <= 0;
            score <= 0;

            irq  <= 0;
            done <= 0;
            uart_tx <= 0;

            uo_out  <= 8'h00;
            uio_out <= 8'h00;

        end
        else begin

            packet_ready <= 1'b0;
            done <= 1'b0;

            // 64-bit Serial Packet Reception
            if(bit_valid) begin

                packet <= {serial_bit, packet[63:1]};

                if(bit_count == 6'd63) begin
                    bit_count <= 0;
                    packet_ready <= 1'b1;
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end

            // Feature Extraction
            if(packet_ready) begin

                x0 <= packet[31:24];
                x1 <= packet[23:16];

                // Neural MAC
                mac_result <=
                    ($signed(packet[31:24]) * 12) +
                    ($signed(packet[23:16]) * 88);

                // ReLU + Threshold
                if(mac_result > 16'd1500)
                    score <= 8'hFF;
                else
                    score <= 8'h00;

                // Alert Manager
                irq  <= (mac_result > 16'd1500);
                done <= 1'b1;

                // UART Telemetry
                uart_tx <= score[0];

                // Outputs
                uo_out <= score;

                uio_out[0] <= done;
                uio_out[1] <= irq;
                uio_out[2] <= uart_tx;
                uio_out[7:3] <= 5'b0;

            end
        end
    end

    wire _unused = &{ena, mode_sel, start, uio_in, 1'b0};

endmodule

`default_nettype wire
