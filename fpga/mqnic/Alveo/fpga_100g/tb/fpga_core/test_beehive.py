import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, Event
from cocotb.log import SimLog
from cocotb.utils import get_sim_time
from cocotb.queue import Queue

import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw
from scapy.utils import PcapWriter
from scapy.data import DLT_EN10MB

import sys, os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from tcp_driver import TCPFourTuple
from udp_app_log_read import UDPAppLogRead, UDPAppLogEntry
from eth_latency_log_read import EthLatencyLogRead, EthLatencyLogEntry
from beehive_corundum_io import BeehiveCorundumInput, BeehiveCorundumOutput

from tcp_automaton_driver import TCPAutomatonDriver
from open_loop_generator import ClientDir

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/sample_designs/tcp_open_loop")
import tb_tcp_open_loop_top

class BeehiveTB():
    def __init__(self, dut, qsfp, conn_list=None):
        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4
        self.IP_TO_MAC = {
            "198.0.0.5": "b8:59:9f:b7:ba:44",
            "198.0.0.7": "00:0a:35:0d:4d:c6"
        }

        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.dut = dut

        self.logfile = PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB)

        self.timer_queue = Queue()

        self.done_event = Event()

        self.qsfp = qsfp
        self.input_op = BeehiveCorundumInput(self.qsfp)
        self.output_op = BeehiveCorundumOutput(self.qsfp)
        self.clk = dut.clk_250mhz
        self.conn_list = conn_list
        
        self.recv_pkts = {}

class BeehiveTCPTB(BeehiveTB):
    def __init__(self, dut, qsfp, conn_list=None):
        super().__init__(dut, qsfp, conn_list=conn_list)
        
        self.buf_size = 8192
        self.conn_list = tb_tcp_open_loop_top.setup_conn_list(self.CLOCK_CYCLE_TIME,
                self.done_event, 1, 10,
                ClientDir.SEND,
                self.buf_size, True)
        self.TCP_driver = TCPAutomatonDriver(dut.clk_250mhz, self.conn_list)


