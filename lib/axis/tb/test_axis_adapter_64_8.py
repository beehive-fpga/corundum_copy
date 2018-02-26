#!/usr/bin/env python
"""

Copyright (c) 2014-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

"""

from myhdl import *
import os

import axis_ep

module = 'axis_adapter'
testbench = 'test_%s_64_8' % module

srcs = []

srcs.append("../rtl/%s.v" % module)
srcs.append("%s.v" % testbench)

src = ' '.join(srcs)

build_cmd = "iverilog -o %s.vvp %s" % (testbench, src)

def bench():

    # Parameters
    INPUT_DATA_WIDTH = 64
    INPUT_KEEP_ENABLE = (INPUT_DATA_WIDTH>8)
    INPUT_KEEP_WIDTH = (INPUT_DATA_WIDTH/8)
    OUTPUT_DATA_WIDTH = 8
    OUTPUT_KEEP_ENABLE = (OUTPUT_DATA_WIDTH>8)
    OUTPUT_KEEP_WIDTH = (OUTPUT_DATA_WIDTH/8)
    ID_ENABLE = 1
    ID_WIDTH = 8
    DEST_ENABLE = 1
    DEST_WIDTH = 8
    USER_ENABLE = 1
    USER_WIDTH = 1

    # Inputs
    clk = Signal(bool(0))
    rst = Signal(bool(0))
    current_test = Signal(intbv(0)[8:])

    input_axis_tdata = Signal(intbv(0)[INPUT_DATA_WIDTH:])
    input_axis_tkeep = Signal(intbv(1)[INPUT_KEEP_WIDTH:])
    input_axis_tvalid = Signal(bool(0))
    input_axis_tlast = Signal(bool(0))
    input_axis_tid = Signal(intbv(0)[ID_WIDTH:])
    input_axis_tdest = Signal(intbv(0)[DEST_WIDTH:])
    input_axis_tuser = Signal(intbv(0)[USER_WIDTH:])
    output_axis_tready = Signal(bool(0))

    # Outputs
    input_axis_tready = Signal(bool(0))
    output_axis_tdata = Signal(intbv(0)[OUTPUT_DATA_WIDTH:])
    output_axis_tkeep = Signal(intbv(1)[OUTPUT_KEEP_WIDTH:])
    output_axis_tvalid = Signal(bool(0))
    output_axis_tlast = Signal(bool(0))
    output_axis_tid = Signal(intbv(0)[ID_WIDTH:])
    output_axis_tdest = Signal(intbv(0)[DEST_WIDTH:])
    output_axis_tuser = Signal(intbv(0)[USER_WIDTH:])

    # sources and sinks
    source_pause = Signal(bool(0))
    sink_pause = Signal(bool(0))

    source = axis_ep.AXIStreamSource()

    source_logic = source.create_logic(
        clk,
        rst,
        tdata=input_axis_tdata,
        tkeep=input_axis_tkeep,
        tvalid=input_axis_tvalid,
        tready=input_axis_tready,
        tlast=input_axis_tlast,
        tid=input_axis_tid,
        tdest=input_axis_tdest,
        tuser=input_axis_tuser,
        pause=source_pause,
        name='source'
    )

    sink = axis_ep.AXIStreamSink()

    sink_logic = sink.create_logic(
        clk,
        rst,
        tdata=output_axis_tdata,
        tkeep=output_axis_tkeep,
        tvalid=output_axis_tvalid,
        tready=output_axis_tready,
        tlast=output_axis_tlast,
        tid=output_axis_tid,
        tdest=output_axis_tdest,
        tuser=output_axis_tuser,
        pause=sink_pause,
        name='sink'
    )

    # DUT
    if os.system(build_cmd):
        raise Exception("Error running build command")

    dut = Cosimulation(
        "vvp -m myhdl %s.vvp -lxt2" % testbench,
        clk=clk,
        rst=rst,
        current_test=current_test,

        input_axis_tdata=input_axis_tdata,
        input_axis_tkeep=input_axis_tkeep,
        input_axis_tvalid=input_axis_tvalid,
        input_axis_tready=input_axis_tready,
        input_axis_tlast=input_axis_tlast,
        input_axis_tid=input_axis_tid,
        input_axis_tdest=input_axis_tdest,
        input_axis_tuser=input_axis_tuser,

        output_axis_tdata=output_axis_tdata,
        output_axis_tkeep=output_axis_tkeep,
        output_axis_tvalid=output_axis_tvalid,
        output_axis_tready=output_axis_tready,
        output_axis_tlast=output_axis_tlast,
        output_axis_tid=output_axis_tid,
        output_axis_tdest=output_axis_tdest,
        output_axis_tuser=output_axis_tuser
    )

    @always(delay(4))
    def clkgen():
        clk.next = not clk

    def wait_normal():
        while input_axis_tvalid or output_axis_tvalid:
            yield clk.posedge

    def wait_pause_source():
        while input_axis_tvalid or output_axis_tvalid:
            source_pause.next = True
            yield clk.posedge
            yield clk.posedge
            yield clk.posedge
            source_pause.next = False
            yield clk.posedge

    def wait_pause_sink():
        while input_axis_tvalid or output_axis_tvalid:
            sink_pause.next = True
            yield clk.posedge
            yield clk.posedge
            yield clk.posedge
            sink_pause.next = False
            yield clk.posedge

    @instance
    def check():
        yield delay(100)
        yield clk.posedge
        rst.next = 1
        yield clk.posedge
        rst.next = 0
        yield clk.posedge
        yield delay(100)
        yield clk.posedge

        for payload_len in range(1,18):
            yield clk.posedge
            print("test 1: test packet, length %d" % payload_len)
            current_test.next = 1

            test_frame = axis_ep.AXIStreamFrame(
                b'\xDA\xD1\xD2\xD3\xD4\xD5' +
                b'\x5A\x51\x52\x53\x54\x55' +
                b'\x80\x00' +
                bytearray(range(payload_len)),
                id=1,
                dest=1,
            )

            for wait in wait_normal, wait_pause_source, wait_pause_sink:
                source.send(test_frame)
                yield clk.posedge
                yield clk.posedge

                yield wait()

                yield clk.posedge
                yield clk.posedge
                yield clk.posedge

                rx_frame = sink.recv()

                assert rx_frame == test_frame

                assert sink.empty()

                yield delay(100)

            yield clk.posedge
            print("test 2: back-to-back packets, length %d" % payload_len)
            current_test.next = 2

            test_frame1 = axis_ep.AXIStreamFrame(
                b'\xDA\xD1\xD2\xD3\xD4\xD5' +
                b'\x5A\x51\x52\x53\x54\x55' +
                b'\x80\x00' +
                bytearray(range(payload_len)),
                id=2,
                dest=1,
            )
            test_frame2 = axis_ep.AXIStreamFrame(
                b'\xDA\xD1\xD2\xD3\xD4\xD5' +
                b'\x5A\x51\x52\x53\x54\x55' +
                b'\x80\x00' +
                bytearray(range(payload_len)),
                id=2,
                dest=2,
            )

            for wait in wait_normal, wait_pause_source, wait_pause_sink:
                source.send(test_frame1)
                source.send(test_frame2)
                yield clk.posedge
                yield clk.posedge

                yield wait()

                yield clk.posedge
                yield clk.posedge
                yield clk.posedge

                rx_frame = sink.recv()

                assert rx_frame == test_frame1

                rx_frame = sink.recv()

                assert rx_frame == test_frame2

                assert sink.empty()

                yield delay(100)

            yield clk.posedge
            print("test 3: tuser assert, length %d" % payload_len)
            current_test.next = 3

            test_frame1 = axis_ep.AXIStreamFrame(
                b'\xDA\xD1\xD2\xD3\xD4\xD5' +
                b'\x5A\x51\x52\x53\x54\x55' +
                b'\x80\x00' +
                bytearray(range(payload_len)),
                id=3,
                dest=1,
                last_cycle_user=1
            )
            test_frame2 = axis_ep.AXIStreamFrame(
                b'\xDA\xD1\xD2\xD3\xD4\xD5' +
                b'\x5A\x51\x52\x53\x54\x55' +
                b'\x80\x00' +
                bytearray(range(payload_len)),
                id=3,
                dest=2,
            )

            for wait in wait_normal, wait_pause_source, wait_pause_sink:
                source.send(test_frame1)
                source.send(test_frame2)
                yield clk.posedge
                yield clk.posedge

                yield wait()

                yield clk.posedge
                yield clk.posedge
                yield clk.posedge

                rx_frame = sink.recv()

                assert rx_frame == test_frame1
                assert rx_frame.last_cycle_user

                rx_frame = sink.recv()

                assert rx_frame == test_frame2

                assert sink.empty()

                yield delay(100)

        raise StopSimulation

    return dut, source_logic, sink_logic, clkgen, check

def test_bench():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    sim = Simulation(bench())
    sim.run()

if __name__ == '__main__':
    print("Running test...")
    test_bench()

