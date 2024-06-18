`include "soc_defs.vh"
`include "packet_defs.vh"
module beehive_out_convert #(
     parameter AXIS_SYNC_DATA_WIDTH = 512
    ,parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8
    ,parameter AXIS_SYNC_RX_USER_WIDTH = -1
    ,parameter AXIS_SYNC_TX_USER_WIDTH = -1
)(
     input  clk
    ,input  rst
    
    ,output logic                                   app_axis_sync_tx_tvalid
    ,output logic   [AXIS_SYNC_DATA_WIDTH-1:0]      app_axis_sync_tx_tdata
    ,output logic   [AXIS_SYNC_KEEP_WIDTH-1:0]      app_axis_sync_tx_tkeep
    ,output logic                                   app_axis_sync_tx_tlast
    ,output logic   [AXIS_SYNC_TX_USER_WIDTH-1:0]   app_axis_sync_tx_tuser
    ,input  logic                                   app_axis_sync_tx_tready
    
    ,input  logic                                   src_convert_tx_val
    ,input  logic                                   src_convert_tx_startframe
    ,input  logic   [`MTU_SIZE_W-1:0]               src_convert_tx_frame_size 
    ,input  logic                                   src_convert_tx_endframe
    ,input  logic   [`MAC_INTERFACE_W-1:0]          src_convert_tx_data
    ,input  logic   [`MAC_PADBYTES_W-1:0]           src_convert_tx_padbytes
    ,output logic                                   convert_src_tx_rdy
);
    
    localparam MAC_KEEP_W = `MAC_INTERFACE_W/8;
    // we convert to a keep interface, widen the interface, and then flip
    // back to the right bus endianness
    
    logic   [MAC_KEEP_W-1:0]    src_convert_tx_keep;
    logic   [AXIS_SYNC_DATA_WIDTH-1:0]  app_axis_sync_tx_tdata_int;
    logic   [AXIS_SYNC_KEEP_WIDTH-1:0]  app_axis_sync_tx_tkeep_int;

    assign src_convert_tx_keep = {(MAC_KEEP_W){1'b1}} << src_convert_tx_padbytes;
    assign app_axis_sync_tx_tuser = '0;

    // do width conversion as necessary
    // check that the interface widths are going to make sense
    generate
        if ((AXIS_SYNC_DATA_WIDTH % `MAC_INTERFACE_W) != 0) begin : check_tx_data_width
            $error("AXIS data width must be a multiple of the Beehive data width");
        end
    endgenerate

generate
    // just pass the signals through if they are the same width
    if (AXIS_SYNC_DATA_WIDTH == `MAC_INTERFACE_W) begin
        assign app_axis_sync_tx_tvalid = src_convert_tx_val;
        assign app_axis_sync_tx_tdata_int = src_convert_tx_data;
        assign app_axis_sync_tx_tkeep_int = src_convert_tx_keep;
        assign app_axis_sync_tx_tlast = src_convert_tx_endframe;
        assign convert_src_tx_rdy = app_axis_sync_tx_tready;
    end
    // otherwise, instantiate the width converter
    else begin
        narrow_to_wide #(
             .IN_DATA_W     (`MAC_INTERFACE_W   )
            ,.OUT_DATA_ELS  (AXIS_SYNC_DATA_WIDTH/`MAC_INTERFACE_W  )
        ) shift_up (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_n_to_w_val    (src_convert_tx_val         )
            ,.src_n_to_w_data   (src_convert_tx_data        )
            ,.src_n_to_w_keep   (src_convert_tx_keep        )
            ,.src_n_to_w_last   (src_convert_tx_endframe    )
            ,.n_to_w_src_rdy    (convert_src_tx_rdy         )
        
            ,.n_to_w_dst_val    (app_axis_sync_tx_tvalid    )
            ,.n_to_w_dst_data   (app_axis_sync_tx_tdata_int )
            ,.n_to_w_dst_keep   (app_axis_sync_tx_tkeep_int )
            ,.n_to_w_dst_last   (app_axis_sync_tx_tlast     )
            ,.dst_n_to_w_rdy    (app_axis_sync_tx_tready    )
        );
    end
endgenerate

    byte_flipper #(
         .DATA_W    (AXIS_SYNC_DATA_WIDTH   )
    ) tx_data_flip (
         .input_data    (app_axis_sync_tx_tdata_int )
        ,.flipped_data  (app_axis_sync_tx_tdata     )
    );

    bit_flipper #(
         .DATA_W    (AXIS_SYNC_KEEP_WIDTH   )
    ) tx_keep_flip (
         .input_data    (app_axis_sync_tx_tkeep_int )
        ,.flipped_data  (app_axis_sync_tx_tkeep     )
    );

endmodule
