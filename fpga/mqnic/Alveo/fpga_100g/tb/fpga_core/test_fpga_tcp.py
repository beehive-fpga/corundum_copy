import logging
import os
import sys

from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP
from scapy.packet import Raw

import scapy.utils
from scapy.utils import PcapWriter
from scapy.data import DLT_EN10MB
from scapy.compat import bytes_encode

import cocotb
import cocotb.utils

from cocotb.log import SimLog
from cocotb.triggers import RisingEdge, FallingEdge, Timer, Combine, First
from cocotb.triggers import Join, with_timeout
from cocotb.result import SimTimeoutError

from beehive_corundum_io import BeehiveCorundumInput, BeehiveCorundumOutput

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from tcp_automaton_driver import TCPAutomatonDriver, EchoGenerator
from tcp_driver import TCPFourTuple
from tcp_logger_read import TCPLoggerReader

async def timer_loop(dut, tcp_tb):
    cocotb.log.info("Starting timer loop")
    while True:
        try:
            queue_get = cocotb.start_soon(tcp_tb.timer_queue.get())
            timer_data = await with_timeout(queue_get,
                    tcp_tb.CLOCK_CYCLE_TIME*500, timeout_unit="ns")
        except SimTimeoutError:
            if tcp_tb.done_event.is_set():
                cocotb.log.info("Timer loop exiting")
                return
            else:
                continue
        timer = timer_data[0]
        time_set = timer_data[1]

#        tb.log.info(f"dequeued timer set at {time_set}")
        await timer

async def run_send_loop(dut, tcp_tb):
    pkts_sent = 0

    while True:
        pkt_to_send, timer = await tcp_tb.TCP_driver.get_packet_to_send()
        if pkt_to_send is not None:
            if timer is not None:
                tcp_tb.timer_queue.put_nowait((timer,
                    cocotb.utils.get_sim_time(units="ns")))
            eth = Ether()

            eth.src = tcp_tb.IP_TO_MAC[pkt_to_send[IP].src]
            eth.dst = tcp_tb.IP_TO_MAC[pkt_to_send[IP].dst]

            pkt_to_send = eth/pkt_to_send
            pkt_bytes = bytearray(pkt_to_send.build())

            if len(pkt_to_send) < 64:
                padding = 64 - len(pkt_to_send)
                pad_bytes = bytearray([0] * padding)
                pkt_bytes.extend(pad_bytes)

            cocotb.log.info("sending packet")
            await tcp_tb.input_op.xmit_frame(pkt_bytes)
            tcp_tb.logfile.write(bytes_encode(pkt_bytes))
            tcp_tb.logfile.flush()
            pkts_sent += 1
            cocotb.log.info(f"Pkts sent {pkts_sent}")

        else:
            # check if we're all done
            if tcp_tb.done_event.is_set():
                return
            else:
                await RisingEdge(dut.clk_250mhz)

async def run_recv_loop(dut, tcp_tb):
    while True:
        pkt_recv = await tcp_tb.output_op.recv_frame()
        tcp_tb.logfile.write(bytes_encode(pkt_recv))
        tcp_tb.logfile.flush()

        tcp_tb.TCP_driver.recv_packet(pkt_recv)
        if (tcp_tb.TCP_driver.all_flows_closed()):
            tcp_tb.done_event.set()
            return
