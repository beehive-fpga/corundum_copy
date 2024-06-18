import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveInputInterface, BeehiveOutputInterface


class BeehiveCorundumInput(BeehiveInputInterface):
    def __init__(self, corundum_qsfp):
        self.corundum_qsfp = corundum_qsfp

    async def xmit_frame(self, test_packet_bytes, rand_delay=False):
        await self.corundum_qsfp.rx.send(test_packet_bytes)

class BeehiveCorundumOutput(BeehiveOutputInterface):
    def __init__(self, corundum_qsfp):
        self.corundum_qsfp = corundum_qsfp

    async def recv_frame(self):
        pkt_recv = await self.corundum_qsfp.tx.recv()
        return pkt_recv.data



