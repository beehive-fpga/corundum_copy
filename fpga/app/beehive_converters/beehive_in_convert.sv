`include "soc_defs.vh"
`include "packet_defs.vh"
module beehive_in_convert #(
     parameter AXIS_SYNC_DATA_WIDTH = 512
    ,parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8
    ,parameter AXIS_SYNC_RX_USER_WIDTH = -1
    ,parameter AXIS_SYNC_TX_USER_WIDTH = -1
)(
     input  clk
    ,input  rst

    ,input  logic                                   app_axis_sync_rx_tvalid
    ,input  logic   [AXIS_SYNC_DATA_WIDTH-1:0]      app_axis_sync_rx_tdata
    ,input  logic   [AXIS_SYNC_KEEP_WIDTH-1:0]      app_axis_sync_rx_tkeep
    ,input  logic                                   app_axis_sync_rx_tlast
    ,input  logic   [AXIS_SYNC_RX_USER_WIDTH-1:0]   app_axis_sync_rx_tuser
    ,output logic                                   app_axis_sync_rx_tready
    
    ,output logic                                   convert_dst_rx_val
    ,output logic   [`MAC_INTERFACE_W-1:0]          convert_dst_rx_data
    ,output logic                                   convert_dst_rx_startframe
    ,output logic   [`MTU_SIZE_W-1:0]               convert_dst_rx_frame_size
    ,output logic                                   convert_dst_rx_endframe
    ,output logic   [`MAC_PADBYTES_W-1:0]           convert_dst_rx_padbytes
    ,input  logic                                   dst_convert_rx_rdy
);

    localparam MAC_KEEP_W = `MAC_INTERFACE_W/8;

    logic   [AXIS_SYNC_DATA_WIDTH-1:0]  app_rx_data_int;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]  app_rx_keep_int;
    
    logic                               w_to_n_if_convert_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]      w_to_n_if_convert_rx_data;
    logic                               w_to_n_if_convert_rx_last;
    logic   [MAC_KEEP_W-1:0]            w_to_n_if_convert_rx_keep;
    logic   [MAC_KEEP_W-1:0]            w_to_n_if_convert_rx_keep_inv;
    logic   [`MAC_PADBYTES_W-1:0]       w_to_n_if_convert_rx_padbytes;
    logic                               if_convert_w_to_n_rx_rdy;
    
    logic                               if_convert_pkt_queue_wr_val;
    logic                               if_convert_pkt_queue_wr_req;
    logic   [`MAC_INTERFACE_W-1:0]      if_convert_pkt_queue_wr_data;
    logic                               pkt_queue_if_convert_wr_rdy;
    logic                               pkt_queue_if_convert_full;
    logic                               if_convert_pkt_queue_wr_start_frame;
    logic                               if_convert_pkt_queue_wr_end_frame;
    logic   [`MAC_PADBYTES_W-1:0]       if_convert_pkt_queue_wr_end_padbytes;

    logic                               dst_convert_rx_rd_req;
    logic                               convert_dst_empty;

    // first we flip, then we transition to the right size, finally we figure out
    // what signals we actually need

    // flip the bus endianness
    byte_flipper #(
        .DATA_W (AXIS_SYNC_DATA_WIDTH)
    ) rx_data_flip (
         .input_data    (app_axis_sync_rx_tdata )
        ,.flipped_data  (app_rx_data_int        )
    );

    bit_flipper #(
        .DATA_W (AXIS_SYNC_KEEP_WIDTH)
    ) rx_keep_flip (
         .input_data    (app_axis_sync_rx_tkeep )
        ,.flipped_data  (app_rx_keep_int        )
    );

    // convert to the correct data width as necessary
    // check the interface widths will make sense
generate
    if ((AXIS_SYNC_DATA_WIDTH % `MAC_INTERFACE_W) != 0) begin : check_rx_data_width
        $error("AXIS data width must be a multiple of the Beehive data width");
    end
endgenerate

generate
    // if both are equal, then just pass thru the signals.
    if (`MAC_INTERFACE_W == AXIS_SYNC_DATA_WIDTH) begin
        assign w_to_n_if_convert_rx_val = app_axis_sync_rx_tvalid;
        assign w_to_n_if_convert_rx_data = app_rx_data_int;
        assign w_to_n_if_convert_rx_keep = app_rx_keep_int;
        assign w_to_n_if_convert_rx_last = app_axis_sync_rx_tlast;
        assign app_axis_sync_rx_tready = if_convert_w_to_n_rx_rdy;
    end
    else begin
        wide_to_narrow #(
             .OUT_DATA_W    (`MAC_INTERFACE_W   )
            ,.IN_DATA_ELS   (AXIS_SYNC_DATA_WIDTH/`MAC_INTERFACE_W)
        ) shift_down (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_w_to_n_val    (app_axis_sync_rx_tvalid    )
            ,.src_w_to_n_data   (app_rx_data_int            )
            ,.src_w_to_n_keep   (app_rx_keep_int            )
            ,.src_w_to_n_last   (app_axis_sync_rx_tlast     )
            ,.w_to_n_src_rdy    (app_axis_sync_rx_tready    )
        
            ,.w_to_n_dst_val    (w_to_n_if_convert_rx_val   )
            ,.w_to_n_dst_data   (w_to_n_if_convert_rx_data  )
            ,.w_to_n_dst_keep   (w_to_n_if_convert_rx_keep  )
            ,.w_to_n_dst_last   (w_to_n_if_convert_rx_last  )
            ,.dst_w_to_n_rdy    (if_convert_w_to_n_rx_rdy   )
        );
    end
endgenerate
    // invert, so 1 indicates a byte that isn't used
    assign w_to_n_if_convert_rx_keep_inv = ~w_to_n_if_convert_rx_keep;

    // this needs to be one larger, since popcount thinks it may output
    // the number of bytes in the data line. In practice it won't, because
    // to have all the bits set to 1 (in the inverted mask), all the bits would
    // be zero in the actual mask, which would mean no valid bytes in the line,
    // which isn't going to be a transaction that occurs
    logic [`MAC_PADBYTES_W:0] to_padbytes_int;
    bsg_popcount #(
        .width_p    (MAC_KEEP_W)
    ) to_padbytes (
         .i (w_to_n_if_convert_rx_keep_inv  )
        ,.o (to_padbytes_int                )
    );
    assign w_to_n_if_convert_rx_padbytes = to_padbytes_int[`MAC_PADBYTES_W-1:0];

    if_w_startframe_convert #(
         .DATA_W        (`MAC_INTERFACE_W   )
    ) rx_if_to_beehive (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_startframe_convert_data_val       (w_to_n_if_convert_rx_val               )
        ,.src_startframe_convert_data           (w_to_n_if_convert_rx_data              )
        ,.src_startframe_convert_data_last      (w_to_n_if_convert_rx_last              )
        ,.src_startframe_convert_data_padbytes  (w_to_n_if_convert_rx_padbytes          )
        ,.startframe_convert_src_data_rdy       (if_convert_w_to_n_rx_rdy               )

        ,.startframe_convert_dst_val            (if_convert_pkt_queue_wr_val            )
        ,.startframe_convert_dst_startframe     (if_convert_pkt_queue_wr_start_frame    )
        ,.startframe_convert_dst_endframe       (if_convert_pkt_queue_wr_end_frame      )
        ,.startframe_convert_dst_data           (if_convert_pkt_queue_wr_data           )
        ,.startframe_convert_dst_padbytes       (if_convert_pkt_queue_wr_end_padbytes   )
        ,.dst_startframe_convert_rdy            (pkt_queue_if_convert_wr_rdy            )
    );

    //don't back pressure for timing
//    assign if_convert_pkt_queue_wr_req = ~pkt_queue_if_convert_full 
//                                    & if_convert_pkt_queue_wr_val;
//    assign pkt_queue_if_convert_wr_rdy = ~pkt_queue_if_convert_full;
    //
    assign if_convert_pkt_queue_wr_req = if_convert_pkt_queue_wr_val;
    assign pkt_queue_if_convert_wr_rdy = 1'b1;

    beehive_pkt_queue pkt_queue (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.wr_req            (if_convert_pkt_queue_wr_req            )
        ,.wr_data           (if_convert_pkt_queue_wr_data           )
        ,.full              (pkt_queue_if_convert_full              )
        ,.wr_start_frame    (if_convert_pkt_queue_wr_start_frame    )
        ,.wr_end_frame      (if_convert_pkt_queue_wr_end_frame      )
        ,.wr_end_padbytes   (if_convert_pkt_queue_wr_end_padbytes   )
        
        ,.rd_req            (dst_convert_rx_rd_req                  )
        ,.rd_data           (convert_dst_rx_data                    )
        ,.rd_start_frame    (convert_dst_rx_startframe              )
        ,.rd_end_frame      (convert_dst_rx_endframe                )
        ,.rd_end_padbytes   (convert_dst_rx_padbytes                )
        ,.rd_size           (convert_dst_rx_frame_size              )
        ,.empty             (convert_dst_empty                      )
    );
    assign dst_convert_rx_rd_req = ~convert_dst_empty & dst_convert_rx_rdy;
    assign convert_dst_rx_val = ~convert_dst_empty;
endmodule
