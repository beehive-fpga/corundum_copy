module beehive_wrapper #(
     parameter AXIS_SYNC_DATA_WIDTH = 512
    ,parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8
    ,parameter AXIS_SYNC_RX_USER_WIDTH = -1
    ,parameter AXIS_SYNC_TX_USER_WIDTH = -1
)(
     input clk
    ,input rst
    
    ,input  logic   [AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_rx_tdata
    ,input  logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_rx_tkeep
    ,input  logic                                  s_axis_sync_rx_tvalid
    ,output logic                                  s_axis_sync_rx_tready
    ,input  logic                                  s_axis_sync_rx_tlast
    ,input  logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  s_axis_sync_rx_tuser

    ,output logic   [AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_rx_tdata
    ,output logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_rx_tkeep
    ,output logic                                  m_axis_sync_rx_tvalid
    ,input  logic                                  m_axis_sync_rx_tready
    ,output logic                                  m_axis_sync_rx_tlast
    ,output logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_sync_rx_tuser

    ,input  logic   [AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_tx_tdata
    ,input  logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_tx_tkeep
    ,input  logic                                  s_axis_sync_tx_tvalid
    ,output logic                                  s_axis_sync_tx_tready
    ,input  logic                                  s_axis_sync_tx_tlast
    ,input  logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_sync_tx_tuser

    ,output logic   [AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_tx_tdata
    ,output logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_tx_tkeep
    ,output logic                                  m_axis_sync_tx_tvalid
    ,input  logic                                  m_axis_sync_tx_tready
    ,output logic                                  m_axis_sync_tx_tlast
    ,output logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  m_axis_sync_tx_tuser
);

    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     app_axis_sync_rx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     app_axis_sync_rx_tkeep;
    logic                                  app_axis_sync_rx_tvalid;
    logic                                  app_axis_sync_rx_tready;
    logic                                  app_axis_sync_rx_tlast;
    logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  app_axis_sync_rx_tuser;
    
    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     fifo_app_rx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     fifo_app_rx_tkeep;
    logic                                  fifo_app_rx_tvalid;
    logic                                  fifo_app_rx_tready;
    logic                                  fifo_app_rx_tlast;
    logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  fifo_app_rx_tuser;

    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     app_axis_sync_tx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     app_axis_sync_tx_tkeep;
    logic                                  app_axis_sync_tx_tvalid;
    logic                                  app_axis_sync_tx_tready;
    logic                                  app_axis_sync_tx_tlast;
    logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  app_axis_sync_tx_tuser;
    
    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     fifo_app_tx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     fifo_app_tx_tkeep;
    logic                                  fifo_app_tx_tvalid;
    logic                                  fifo_app_tx_tready;
    logic                                  fifo_app_tx_tlast;
    logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  fifo_app_tx_tuser;
    
    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     bypass_axis_sync_rx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     bypass_axis_sync_rx_tkeep;
    logic                                  bypass_axis_sync_rx_tvalid;
    logic                                  bypass_axis_sync_rx_tready;
    logic                                  bypass_axis_sync_rx_tlast;
    logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  bypass_axis_sync_rx_tuser;

    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     bypass_axis_sync_tx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     bypass_axis_sync_tx_tkeep;
    logic                                  bypass_axis_sync_tx_tvalid;
    logic                                  bypass_axis_sync_tx_tready;
    logic                                  bypass_axis_sync_tx_tlast;
    logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  bypass_axis_sync_tx_tuser;
    
    logic                                  convert_beehive_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]         convert_beehive_rx_data;
    logic                                  convert_beehive_rx_startframe;
    logic   [`MTU_SIZE_W-1:0]              convert_beehive_rx_frame_size;
    logic                                  convert_beehive_rx_endframe;
    logic   [`MAC_PADBYTES_W-1:0]          convert_beehive_rx_padbytes;
    logic                                  beehive_convert_rx_rdy;
    
    logic                                  beehive_convert_tx_val;
    logic                                  beehive_convert_tx_startframe;
    logic   [`MTU_SIZE_W-1:0]              beehive_convert_tx_frame_size;
    logic                                  beehive_convert_tx_endframe;
    logic   [`MAC_INTERFACE_W-1:0]         beehive_convert_tx_data;
    logic   [`MAC_PADBYTES_W-1:0]          beehive_convert_tx_padbytes;
    logic                                  convert_beehive_tx_rdy;

    logic                           memA_ready;
    logic                           memA_read;
    logic                           memA_write;
    logic   [`MEM_ADDR_W-1:0]       memA_address;
    logic   [`MEM_DATA_W-1:0]       memA_readdata;
    logic   [`MEM_DATA_W-1:0]       memA_writedata;
    logic   [`MEM_BURST_CNT_W-1:0]  memA_burstcount;
    logic   [`MEM_WR_MASK_W-1:0]    memA_byteenable;
    logic                           memA_readdatavalid;
    logic                           memA_readdatavalid_reg;

    logic                           memB_ready;
    logic                           memB_read;
    logic                           memB_write;
    logic   [`MEM_ADDR_W-1:0]       memB_address;
    logic   [`MEM_DATA_W-1:0]       memB_readdata;
    logic   [`MEM_DATA_W-1:0]       memB_writedata;
    logic   [`MEM_BURST_CNT_W-1:0]  memB_burstcount;
    logic   [`MEM_WR_MASK_W-1:0]    memB_byteenable;
    logic                           memB_readdatavalid;
    logic                           memB_readdatavalid_reg;


    assign bypass_axis_sync_rx_tdata = s_axis_sync_rx_tdata;
    assign bypass_axis_sync_rx_tkeep = s_axis_sync_rx_tkeep;
    assign bypass_axis_sync_rx_tlast = s_axis_sync_rx_tlast;
    assign bypass_axis_sync_rx_tuser = s_axis_sync_rx_tuser;

    assign app_axis_sync_rx_tdata = s_axis_sync_rx_tdata;
    assign app_axis_sync_rx_tkeep = s_axis_sync_rx_tkeep;
    assign app_axis_sync_rx_tlast = s_axis_sync_rx_tlast;
    assign app_axis_sync_rx_tuser = s_axis_sync_rx_tuser;

    assign s_axis_sync_rx_tready = m_axis_sync_rx_tready & app_axis_sync_rx_tready;
    assign m_axis_sync_rx_tdata = bypass_axis_sync_rx_tdata;
    assign m_axis_sync_rx_tkeep = bypass_axis_sync_rx_tkeep;
    assign m_axis_sync_rx_tlast = bypass_axis_sync_rx_tlast;
    assign m_axis_sync_rx_tuser = bypass_axis_sync_rx_tuser;
    assign app_axis_sync_rx_tvalid = s_axis_sync_rx_tvalid & s_axis_sync_rx_tready;
    assign bypass_axis_sync_rx_tvalid = s_axis_sync_rx_tvalid & s_axis_sync_rx_tready;
    assign m_axis_sync_rx_tvalid = bypass_axis_sync_rx_tvalid;

    assign bypass_axis_sync_tx_tdata = s_axis_sync_tx_tdata;
    assign bypass_axis_sync_tx_tkeep = s_axis_sync_tx_tkeep;
    assign bypass_axis_sync_tx_tlast = s_axis_sync_tx_tlast;
    assign bypass_axis_sync_tx_tuser = s_axis_sync_tx_tuser;
    assign bypass_axis_sync_tx_tvalid = s_axis_sync_tx_tvalid;
    assign s_axis_sync_tx_tready = bypass_axis_sync_tx_tready;
    axis_arb_mux # (
        // Number of AXI stream inputs
        .S_COUNT    (2)
        // Width of AXI stream interfaces in bits
       ,.DATA_WIDTH (AXIS_SYNC_DATA_WIDTH   )
        // Propagate tkeep signal
       ,.KEEP_ENABLE(1)
        // tkeep signal width (words,per cycle)
       ,.KEEP_WIDTH (AXIS_SYNC_KEEP_WIDTH   )
        // Propagate tuser signal
       ,.USER_ENABLE(1)
        // tuser signal width
       ,.USER_WIDTH (AXIS_SYNC_TX_USER_WIDTH)
        // Propagate tlast signal
       ,.LAST_ENABLE(1)
    ) tx_mux (
         .clk   (clk    )
        ,.rst   (rst    )
    
        /*
         * AXI Stream inputs
         */
        ,.s_axis_tvalid ({app_axis_sync_tx_tvalid, bypass_axis_sync_tx_tvalid}  )
        ,.s_axis_tready ({app_axis_sync_tx_tready, bypass_axis_sync_tx_tready}  )
        ,.s_axis_tdata  ({app_axis_sync_tx_tdata, bypass_axis_sync_tx_tdata}    )
        ,.s_axis_tkeep  ({app_axis_sync_tx_tkeep, bypass_axis_sync_tx_tkeep}    )
        ,.s_axis_tlast  ({app_axis_sync_tx_tlast, bypass_axis_sync_tx_tlast}    )
        ,.s_axis_tuser  ({app_axis_sync_tx_tuser, bypass_axis_sync_tx_tuser}    )
    
        /*
         * AXI Stream output
         */
        ,.m_axis_tvalid (m_axis_sync_tx_tvalid  )
        ,.m_axis_tready (m_axis_sync_tx_tready  )
        ,.m_axis_tdata  (m_axis_sync_tx_tdata   )
        ,.m_axis_tkeep  (m_axis_sync_tx_tkeep   )
        ,.m_axis_tlast  (m_axis_sync_tx_tlast   )
        ,.m_axis_tuser  (m_axis_sync_tx_tuser   )
    );

    typedef struct packed {
        logic   [AXIS_SYNC_DATA_WIDTH-1:0]      data;
        logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]   user;
        logic   [AXIS_SYNC_KEEP_WIDTH-1:0]      keep;
        logic                                   last;
    } axis_data_struct;
   
    // SLR2 buf FIFO
    logic slr_2buf_rx_full;
    logic slr_2buf_rx_wr_req;
    axis_data_struct slr_2buf_rx_wr_data;
    logic slr_2buf_rx_rd_req;
    logic slr_2buf_rx_empty;
    axis_data_struct slr_2buf_rx_rd_data;
    
    assign slr_2buf_rx_wr_data.data = app_axis_sync_rx_tdata;
    assign slr_2buf_rx_wr_data.keep = app_axis_sync_rx_tkeep;
    assign slr_2buf_rx_wr_data.last = app_axis_sync_rx_tlast;
    assign slr_2buf_rx_wr_data.user = app_axis_sync_rx_tuser;
    
    assign slr_2buf_rx_wr_req = app_axis_sync_rx_tvalid & ~slr_2buf_rx_full;
    assign app_axis_sync_rx_tready = ~slr_2buf_rx_full;
    
    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_2buf_rx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_2buf_rx_wr_req    )
        ,.data      (slr_2buf_rx_wr_data   )
        ,.full      (slr_2buf_rx_full      )
        ,.q         (slr_2buf_rx_rd_data   )
        ,.empty     (slr_2buf_rx_empty     )
        ,.rdreq     (slr_2buf_rx_rd_req    )
    );


    // SLR2 -> SLR1
    logic slr_2to1_rx_full;
    logic slr_2to1_rx_wr_req;
    axis_data_struct slr_2to1_rx_wr_data;
    logic slr_2to1_rx_rd_req;
    logic slr_2to1_rx_empty;
    axis_data_struct slr_2to1_rx_rd_data;

    assign slr_2to1_rx_wr_req = ~slr_2buf_rx_empty & ~slr_2to1_rx_full;
    assign slr_2to1_rx_wr_data = slr_2buf_rx_rd_data;
    assign slr_2buf_rx_rd_req = ~slr_2buf_rx_empty & ~slr_2buf_rx_full;

//    assign slr_2to1_rx_wr_data.data = app_axis_sync_rx_tdata;
//    assign slr_2to1_rx_wr_data.keep = app_axis_sync_rx_tkeep;
//    assign slr_2to1_rx_wr_data.last = app_axis_sync_rx_tlast;
//    assign slr_2to1_rx_wr_data.user = app_axis_sync_rx_tuser;

//    assign slr_2to1_rx_wr_req = app_axis_sync_rx_tvalid & ~slr_2to1_rx_full;
//    assign app_axis_sync_rx_tready = ~slr_2to1_rx_full;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_2to1_rx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_2to1_rx_wr_req    )
        ,.data      (slr_2to1_rx_wr_data   )
        ,.full      (slr_2to1_rx_full      )
        ,.q         (slr_2to1_rx_rd_data   )
        ,.empty     (slr_2to1_rx_empty     )
        ,.rdreq     (slr_2to1_rx_rd_req    )
    );

    logic slr_1buf_rx_full;
    logic slr_1buf_rx_wr_req;
    axis_data_struct slr_1buf_rx_wr_data;
    logic slr_1buf_rx_rd_req;
    logic slr_1buf_rx_empty;
    axis_data_struct slr_1buf_rx_rd_data;

    assign slr_1buf_rx_wr_data = slr_2to1_rx_rd_data;
    assign slr_1buf_rx_wr_req = ~slr_2to1_rx_empty & ~slr_1buf_rx_full;
    assign slr_2to1_rx_rd_req = ~slr_2to1_rx_empty & ~slr_1buf_rx_full;
    
    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_1buf_rx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_1buf_rx_wr_req    )
        ,.data      (slr_1buf_rx_wr_data   )
        ,.full      (slr_1buf_rx_full      )
        ,.q         (slr_1buf_rx_rd_data   )
        ,.empty     (slr_1buf_rx_empty     )
        ,.rdreq     (slr_1buf_rx_rd_req    )
    );

    // SLR1 -> SLR0
    logic slr_1to0_rx_full;
    logic slr_1to0_rx_wr_req;
    axis_data_struct slr_1to0_rx_wr_data;
    logic slr_1to0_rx_rd_req;
    logic slr_1to0_rx_empty;
    axis_data_struct slr_1to0_rx_rd_data;

    assign slr_1to0_rx_wr_req = ~slr_1buf_rx_empty & ~slr_1to0_rx_full;
    assign slr_1buf_rx_rd_req = ~slr_1buf_rx_empty & ~slr_1to0_rx_full;
    assign slr_1to0_rx_wr_data = slr_1buf_rx_rd_data;
    
//    assign slr_1to0_rx_wr_req = ~slr_2to1_rx_empty & ~slr_1to0_rx_full;
//    assign slr_1to0_rx_wr_data = slr_2to1_rx_rd_data;
//    assign slr_2to1_rx_rd_req = ~slr_2to1_rx_empty & ~slr_1to0_rx_full;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_1to0_rx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_1to0_rx_wr_req    )
        ,.data      (slr_1to0_rx_wr_data   )
        ,.full      (slr_1to0_rx_full      )
        ,.q         (slr_1to0_rx_rd_data   )
        ,.empty     (slr_1to0_rx_empty     )
        ,.rdreq     (slr_1to0_rx_rd_req    )
    );

    assign fifo_app_rx_tvalid = ~slr_1to0_rx_empty;
    assign slr_1to0_rx_rd_req = ~slr_1to0_rx_empty & fifo_app_rx_tready;

    assign fifo_app_rx_tdata = slr_1to0_rx_rd_data.data;
    assign fifo_app_rx_tkeep = slr_1to0_rx_rd_data.keep;
    assign fifo_app_rx_tlast = slr_1to0_rx_rd_data.last;
    assign fifo_app_rx_tuser = slr_1to0_rx_rd_data.user;

    beehive_in_convert #(
         .AXIS_SYNC_DATA_WIDTH      (AXIS_SYNC_DATA_WIDTH       )
        ,.AXIS_SYNC_RX_USER_WIDTH   (AXIS_SYNC_RX_USER_WIDTH    )
        ,.AXIS_SYNC_TX_USER_WIDTH   (AXIS_SYNC_TX_USER_WIDTH    )
    ) in_convert (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.app_axis_sync_rx_tvalid   (fifo_app_rx_tvalid             )
        ,.app_axis_sync_rx_tdata    (fifo_app_rx_tdata              )
        ,.app_axis_sync_rx_tkeep    (fifo_app_rx_tkeep              )
        ,.app_axis_sync_rx_tlast    (fifo_app_rx_tlast              )
        ,.app_axis_sync_rx_tuser    (fifo_app_rx_tuser              )
        ,.app_axis_sync_rx_tready   (fifo_app_rx_tready             )
        
        ,.convert_dst_rx_val        (convert_beehive_rx_val         )
        ,.convert_dst_rx_data       (convert_beehive_rx_data        )
        ,.convert_dst_rx_startframe (convert_beehive_rx_startframe  )
        ,.convert_dst_rx_frame_size (convert_beehive_rx_frame_size  )
        ,.convert_dst_rx_endframe   (convert_beehive_rx_endframe    )
        ,.convert_dst_rx_padbytes   (convert_beehive_rx_padbytes    )
        ,.dst_convert_rx_rdy        (beehive_convert_rx_rdy         )
    );
    
    tcp_open_loop_top #(
         .MEM_ADDR_W        (`MEM_ADDR_W        )
        ,.MEM_DATA_W        (`MEM_DATA_W        )
        ,.MEM_BURST_CNT_W   (`MEM_BURST_CNT_W   )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mac_engine_rx_val         (convert_beehive_rx_val         )
        ,.mac_engine_rx_data        (convert_beehive_rx_data        )
        ,.mac_engine_rx_startframe  (convert_beehive_rx_startframe  )
        ,.mac_engine_rx_frame_size  (convert_beehive_rx_frame_size  )
        ,.mac_engine_rx_endframe    (convert_beehive_rx_endframe    )
        ,.mac_engine_rx_padbytes    (convert_beehive_rx_padbytes    )
        ,.engine_mac_rx_rdy         (beehive_convert_rx_rdy         )
	
        ,.engine_mac_tx_val         (beehive_convert_tx_val         )
	    ,.engine_mac_tx_startframe  (beehive_convert_tx_startframe  )
	    ,.engine_mac_tx_frame_size  (beehive_convert_tx_frame_size  )
	    ,.engine_mac_tx_endframe    (beehive_convert_tx_endframe    )
	    ,.engine_mac_tx_data        (beehive_convert_tx_data        )
	    ,.engine_mac_tx_padbytes    (beehive_convert_tx_padbytes    )
	    ,.mac_engine_tx_rdy         (convert_beehive_tx_rdy         )
        
        ,.memA_ready_in             (memA_ready                     )
        ,.memA_read_out             (memA_read                      )
        ,.memA_write_out            (memA_write                     )
        ,.memA_address_out          (memA_address                   )
        ,.memA_readdata_in          (memA_readdata                  )
        ,.memA_writedata_out        (memA_writedata                 )
        ,.memA_burstcount_out       (memA_burstcount                )
        ,.memA_byteenable_out       (memA_byteenable                )
        ,.memA_readdatavalid_in     (memA_readdatavalid             )
        
        ,.memB_ready_in             (memB_ready                     )
        ,.memB_read_out             (memB_read                      )
        ,.memB_write_out            (memB_write                     )
        ,.memB_address_out          (memB_address                   )
        ,.memB_readdata_in          (memB_readdata                  )
        ,.memB_writedata_out        (memB_writedata                 )
        ,.memB_burstcount_out       (memB_burstcount                )
        ,.memB_byteenable_out       (memB_byteenable                )
        ,.memB_readdatavalid_in     (memB_readdatavalid             )
    );
    
    typedef struct packed {
        logic                           read;
        logic                           write;
        logic   [`MEM_ADDR_W-1:0]       addr;
        logic   [`MEM_DATA_W-1:0]       writedata;
        logic   [`MEM_WR_MASK_W-1:0]    bytemask;
    } mem_req_struct;
    localparam MEM_REQ_STRUCT_W = 1 + 1 + `MEM_ADDR_W + `MEM_DATA_W + `MEM_WR_MASK_W;
    mem_req_struct memA_req_enq;
    mem_req_struct memA_req_deq;

    assign memA_req_enq.read = memA_read;
    assign memA_req_enq.write = memA_write;
    assign memA_req_enq.addr = memA_address;
    assign memA_req_enq.writedata = memA_writedata;
    assign memA_req_enq.bytemask = memA_byteenable;

    logic   memA_req_q_deq_val;

    axis_fifo #(
         .DEPTH         (8)
        ,.DATA_WIDTH    (MEM_REQ_STRUCT_W)
        ,.KEEP_ENABLE   (0)
        ,.LAST_ENABLE   (0)
        ,.ID_ENABLE     (0)
        ,.DEST_ENABLE   (0)
        ,.USER_ENABLE   (0)
    ) memA_req_q (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.s_axis_tdata      (memA_req_enq           )
        ,.s_axis_tkeep      ('0)
        ,.s_axis_tvalid     (memA_read | memA_write )
        ,.s_axis_tready     (memA_ready             )
        ,.s_axis_tlast      ('0)
        ,.s_axis_tid        ('0)
        ,.s_axis_tdest      ('0)
        ,.s_axis_tuser      ('0)

        ,.m_axis_tdata      (memA_req_deq           )
        ,.m_axis_tkeep      ()
        ,.m_axis_tvalid     (memA_req_q_deq_val     )
        ,.m_axis_tready     (1'b1   )
        ,.m_axis_tlast      ()
        ,.m_axis_tid        ()
        ,.m_axis_tdest      ()
        ,.m_axis_tuser      ()

        ,.status_overflow   ()
        ,.status_bad_frame  ()
        ,.status_good_frame ()
    );

    ram_1rw_byte_mask_out_reg_wrap #(
         .DATA_W(`MEM_DATA_W)
        ,.DEPTH (2 ** `MEM_ADDR_W)
    ) memA (
         .clk           (clk                    )
        ,.rst           (rst                    )
        ,.en_a          (memA_req_q_deq_val     )
        ,.wr_en_a       (memA_req_deq.write     )
        ,.addr_a        (memA_req_deq.addr      )
        ,.din_a         (memA_req_deq.writedata )
        ,.wr_mask_a     (memA_req_deq.bytemask  )

        ,.dout_val_a    (memA_readdatavalid     )
        ,.dout_a        (memA_readdata          )
    );

    mem_req_struct memB_req_enq;
    mem_req_struct memB_req_deq;

    assign memB_req_enq.read = memB_read;
    assign memB_req_enq.write = memB_write;
    assign memB_req_enq.addr = memB_address;
    assign memB_req_enq.writedata = memB_writedata;
    assign memB_req_enq.bytemask = memB_byteenable;

    logic   memB_req_q_deq_val;

    axis_fifo #(
         .DEPTH         (8)
        ,.DATA_WIDTH    (MEM_REQ_STRUCT_W)
        ,.KEEP_ENABLE   (0)
        ,.LAST_ENABLE   (0)
        ,.ID_ENABLE     (0)
        ,.DEST_ENABLE   (0)
        ,.USER_ENABLE   (0)
    ) memB_req_q (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.s_axis_tdata      (memB_req_enq           )
        ,.s_axis_tkeep      ('0)
        ,.s_axis_tvalid     (memB_read | memB_write )
        ,.s_axis_tready     (memB_ready             )
        ,.s_axis_tlast      ('0)
        ,.s_axis_tid        ('0)
        ,.s_axis_tdest      ('0)
        ,.s_axis_tuser      ('0)

        ,.m_axis_tdata      (memB_req_deq           )
        ,.m_axis_tkeep      ()
        ,.m_axis_tvalid     (memB_req_q_deq_val     )
        ,.m_axis_tready     (1'b1   )
        ,.m_axis_tlast      ()
        ,.m_axis_tid        ()
        ,.m_axis_tdest      ()
        ,.m_axis_tuser      ()

        ,.status_overflow   ()
        ,.status_bad_frame  ()
        ,.status_good_frame ()
    );
     
    ram_1rw_byte_mask_out_reg_wrap #(
         .DATA_W(`MEM_DATA_W        )
        ,.DEPTH (2 ** `MEM_ADDR_W   )
    ) memB (
         .clk           (clk                    )
        ,.rst           (rst                    )
        ,.en_a          (memB_req_q_deq_val     )
        ,.wr_en_a       (memB_req_deq.write     )
        ,.addr_a        (memB_req_deq.addr      )
        ,.din_a         (memB_req_deq.writedata )
        ,.wr_mask_a     (memB_req_deq.bytemask  )

        ,.dout_val_a    (memB_readdatavalid     )
        ,.dout_a        (memB_readdata          )
    );

    beehive_out_convert #(
         .AXIS_SYNC_DATA_WIDTH      (AXIS_SYNC_DATA_WIDTH       )
        ,.AXIS_SYNC_RX_USER_WIDTH   (AXIS_SYNC_RX_USER_WIDTH    )
        ,.AXIS_SYNC_TX_USER_WIDTH   (AXIS_SYNC_TX_USER_WIDTH    )
    ) out_convert (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.app_axis_sync_tx_tvalid   (fifo_app_tx_tvalid             )
        ,.app_axis_sync_tx_tdata    (fifo_app_tx_tdata              )
        ,.app_axis_sync_tx_tkeep    (fifo_app_tx_tkeep              )
        ,.app_axis_sync_tx_tlast    (fifo_app_tx_tlast              )
        ,.app_axis_sync_tx_tuser    (fifo_app_tx_tuser              )
        ,.app_axis_sync_tx_tready   (fifo_app_tx_tready             )
        
        ,.src_convert_tx_val        (beehive_convert_tx_val         )
        ,.src_convert_tx_startframe (beehive_convert_tx_startframe  )
        ,.src_convert_tx_frame_size (beehive_convert_tx_frame_size  )
        ,.src_convert_tx_endframe   (beehive_convert_tx_endframe    )
        ,.src_convert_tx_data       (beehive_convert_tx_data        )
        ,.src_convert_tx_padbytes   (beehive_convert_tx_padbytes    )
        ,.convert_src_tx_rdy        (convert_beehive_tx_rdy         )
    );
    
    logic slr_0buf_tx_full;
    logic slr_0buf_tx_wr_req;
    axis_data_struct slr_0buf_tx_wr_data;
    logic slr_0buf_tx_rd_req;
    logic slr_0buf_tx_empty;
    axis_data_struct slr_0buf_tx_rd_data;
    
    assign slr_0buf_tx_wr_data.data = fifo_app_tx_tdata;
    assign slr_0buf_tx_wr_data.keep = fifo_app_tx_tkeep;
    assign slr_0buf_tx_wr_data.user = fifo_app_tx_tuser;
    assign slr_0buf_tx_wr_data.last = fifo_app_tx_tlast;

    assign slr_0buf_tx_wr_req = fifo_app_tx_tvalid & ~slr_0buf_tx_full;
    assign fifo_app_tx_tready = ~slr_0buf_tx_full;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_0buf_tx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_0buf_tx_wr_req    )
        ,.data      (slr_0buf_tx_wr_data   )
        ,.full      (slr_0buf_tx_full      )
        ,.q         (slr_0buf_tx_rd_data   )
        ,.empty     (slr_0buf_tx_empty     )
        ,.rdreq     (slr_0buf_tx_rd_req    )
    );

    // SLR0 -> SLR1
    logic slr_0to1_tx_full;
    logic slr_0to1_tx_wr_req;
    axis_data_struct slr_0to1_tx_wr_data;
    logic slr_0to1_tx_rd_req;
    logic slr_0to1_tx_empty;
    axis_data_struct slr_0to1_tx_rd_data;

//    assign slr_0to1_tx_wr_data.data = fifo_app_tx_tdata;
//    assign slr_0to1_tx_wr_data.keep = fifo_app_rx_tkeep;
//    assign slr_0to1_tx_wr_data.user = fifo_app_rx_tuser;
//    assign slr_0to1_tx_wr_data.last = fifo_app_rx_tlast;
//
//    assign slr_0to1_tx_wr_req = fifo_app_tx_tvalid & ~slr_0to1_tx_full;
//    assign fifo_app_tx_tready = ~slr_0to1_tx_full;

    assign slr_0to1_tx_wr_req = ~slr_0buf_tx_empty & ~slr_0to1_tx_full;
    assign slr_0to1_tx_wr_data = slr_0buf_tx_rd_data;
    assign slr_0buf_tx_rd_req = ~slr_0buf_tx_empty & ~slr_0to1_tx_full;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_0to1_tx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_0to1_tx_wr_req    )
        ,.data      (slr_0to1_tx_wr_data   )
        ,.full      (slr_0to1_tx_full      )
        ,.q         (slr_0to1_tx_rd_data   )
        ,.empty     (slr_0to1_tx_empty     )
        ,.rdreq     (slr_0to1_tx_rd_req    )
    );
    
    logic slr_1buf_tx_full;
    logic slr_1buf_tx_wr_req;
    axis_data_struct slr_1buf_tx_wr_data;
    logic slr_1buf_tx_rd_req;
    logic slr_1buf_tx_empty;
    axis_data_struct slr_1buf_tx_rd_data;

    assign slr_1buf_tx_wr_data = slr_0to1_tx_rd_data;
    assign slr_1buf_tx_wr_req = ~slr_1buf_tx_full & ~slr_0to1_tx_empty;
    assign slr_0to1_tx_rd_req = ~slr_1buf_tx_full & ~slr_0to1_tx_empty;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_1buf_tx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_1buf_tx_wr_req    )
        ,.data      (slr_1buf_tx_wr_data   )
        ,.full      (slr_1buf_tx_full      )
        ,.q         (slr_1buf_tx_rd_data   )
        ,.empty     (slr_1buf_tx_empty     )
        ,.rdreq     (slr_1buf_tx_rd_req    )
    );
   
    // SLR1 -> SLR2
    logic slr_1to2_tx_full;
    logic slr_1to2_tx_wr_req;
    axis_data_struct slr_1to2_tx_wr_data;
    logic slr_1to2_tx_rd_req;
    logic slr_1to2_tx_empty;
    axis_data_struct slr_1to2_tx_rd_data;

    assign slr_1to2_tx_wr_data = slr_1buf_tx_rd_data;
    assign slr_1to2_tx_wr_req = ~slr_1to2_tx_full & ~slr_1buf_tx_empty;
    assign slr_1buf_tx_rd_req = ~slr_1to2_tx_full & ~slr_1buf_tx_empty;
//    assign slr_1to2_tx_wr_data = slr_0to1_tx_rd_data;
//    assign slr_1to2_tx_wr_req = ~slr_1to2_tx_full & ~slr_0to1_tx_empty;
//    assign slr_0to1_tx_rd_req = ~slr_1to2_tx_full & ~slr_0to1_tx_empty;

    HullFIFO #(
        .WIDTH  (AXIS_SYNC_DATA_WIDTH + AXIS_SYNC_RX_USER_WIDTH + 1 + AXIS_SYNC_KEEP_WIDTH)
        ,.LOG_DEPTH(1)
    ) slr_1to2_tx_fifo (
         .clock     (clk    )
        ,.reset_n   (~rst   )
        
        ,.wrreq     (slr_1to2_tx_wr_req    )
        ,.data      (slr_1to2_tx_wr_data   )
        ,.full      (slr_1to2_tx_full      )
        ,.q         (slr_1to2_tx_rd_data   )
        ,.empty     (slr_1to2_tx_empty     )
        ,.rdreq     (slr_1to2_tx_rd_req    )
    );

    assign app_axis_sync_tx_tdata = slr_1to2_tx_rd_data.data;
    assign app_axis_sync_tx_tuser = slr_1to2_tx_rd_data.user;
    assign app_axis_sync_tx_tlast = slr_1to2_tx_rd_data.last;
    assign app_axis_sync_tx_tkeep = slr_1to2_tx_rd_data.keep;

    assign app_axis_sync_tx_tvalid = ~slr_1to2_tx_empty;
    assign slr_1to2_tx_rd_req = ~slr_1to2_tx_empty & app_axis_sync_tx_tready;

endmodule
