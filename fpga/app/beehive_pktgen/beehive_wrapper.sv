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
    
(* mark_debug = "true" *)   logic   [AXIS_SYNC_DATA_WIDTH-1:0]     app_axis_sync_rx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     app_axis_sync_rx_tkeep;
(* mark_debug = "true" *)    logic                                  app_axis_sync_rx_tvalid;
    logic                                  app_axis_sync_rx_tready;
    logic                                  app_axis_sync_rx_tlast;
    logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]  app_axis_sync_rx_tuser;

    logic   [AXIS_SYNC_DATA_WIDTH-1:0]     app_axis_sync_tx_tdata;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]     app_axis_sync_tx_tkeep;
    logic                                  app_axis_sync_tx_tvalid;
    logic                                  app_axis_sync_tx_tready;
    logic                                  app_axis_sync_tx_tlast;
    logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]  app_axis_sync_tx_tuser;
    
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

    beehive_in_convert #(
         .AXIS_SYNC_DATA_WIDTH      (AXIS_SYNC_DATA_WIDTH       )
        ,.AXIS_SYNC_RX_USER_WIDTH   (AXIS_SYNC_RX_USER_WIDTH    )
        ,.AXIS_SYNC_TX_USER_WIDTH   (AXIS_SYNC_TX_USER_WIDTH    )
    ) in_convert (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.app_axis_sync_rx_tvalid   (app_axis_sync_rx_tvalid        )
        ,.app_axis_sync_rx_tdata    (app_axis_sync_rx_tdata         )
        ,.app_axis_sync_rx_tkeep    (app_axis_sync_rx_tkeep         )
        ,.app_axis_sync_rx_tlast    (app_axis_sync_rx_tlast         )
        ,.app_axis_sync_rx_tuser    (app_axis_sync_rx_tuser         )
        ,.app_axis_sync_rx_tready   (app_axis_sync_rx_tready        )
        
        ,.convert_dst_rx_val        (convert_beehive_rx_val         )
        ,.convert_dst_rx_data       (convert_beehive_rx_data        )
        ,.convert_dst_rx_startframe (convert_beehive_rx_startframe  )
        ,.convert_dst_rx_frame_size (convert_beehive_rx_frame_size  )
        ,.convert_dst_rx_endframe   (convert_beehive_rx_endframe    )
        ,.convert_dst_rx_padbytes   (convert_beehive_rx_padbytes    )
        ,.dst_convert_rx_rdy        (beehive_convert_rx_rdy         )
    );

    tb_udp_pkt_gen_top beehive (
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
    );

    beehive_out_convert #(
         .AXIS_SYNC_DATA_WIDTH      (AXIS_SYNC_DATA_WIDTH       )
        ,.AXIS_SYNC_RX_USER_WIDTH   (AXIS_SYNC_RX_USER_WIDTH    )
        ,.AXIS_SYNC_TX_USER_WIDTH   (AXIS_SYNC_TX_USER_WIDTH    )
    ) out_convert (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.app_axis_sync_tx_tvalid   (app_axis_sync_tx_tvalid        )
        ,.app_axis_sync_tx_tdata    (app_axis_sync_tx_tdata         )
        ,.app_axis_sync_tx_tkeep    (app_axis_sync_tx_tkeep         )
        ,.app_axis_sync_tx_tlast    (app_axis_sync_tx_tlast         )
        ,.app_axis_sync_tx_tuser    (app_axis_sync_tx_tuser         )
        ,.app_axis_sync_tx_tready   (app_axis_sync_tx_tready        )
        
        ,.src_convert_tx_val        (beehive_convert_tx_val         )
        ,.src_convert_tx_startframe (beehive_convert_tx_startframe  )
        ,.src_convert_tx_frame_size (beehive_convert_tx_frame_size  )
        ,.src_convert_tx_endframe   (beehive_convert_tx_endframe    )
        ,.src_convert_tx_data       (beehive_convert_tx_data        )
        ,.src_convert_tx_padbytes   (beehive_convert_tx_padbytes    )
        ,.convert_src_tx_rdy        (convert_beehive_tx_rdy         )
    );

endmodule
