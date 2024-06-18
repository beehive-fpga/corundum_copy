`include "soc_defs.vh"
`include "packet_defs.vh"
module beehive_pkt_queue (
     input clk
    ,input rst
    
    ,input                                  wr_req
    ,input          [`MAC_INTERFACE_W-1:0]  wr_data
    ,output                                 full
    ,input                                  wr_start_frame
    ,input                                  wr_end_frame
    ,input          [`MAC_PADBYTES_W-1:0]   wr_end_padbytes
    
    ,input                                  rd_req
    ,output logic   [`MAC_INTERFACE_W-1:0]  rd_data
    ,output logic                           rd_start_frame
    ,output logic                           rd_end_frame
    ,output logic   [`MAC_PADBYTES_W-1:0]   rd_end_padbytes
    ,output logic   [`MTU_SIZE_W-1:0]       rd_size
    ,output logic                           empty
);
    localparam DROP_QUEUE_STRUCT_W = `MAC_INTERFACE_W + 1 + 1 + `MAC_PADBYTES_W;
    localparam DROP_QUEUE_LOG_ELS = 10;
    
    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic                           startframe;
        logic                           endframe;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
    } drop_queue_struct;

    drop_queue_struct   pkt_queue_wr_data;
    drop_queue_struct   pkt_queue_rd_data;

    logic               pkq_queue_rx_val;
    
    logic                       pkt_size_queue_rd_req;
    logic                       pkt_size_queue_empty;
    logic   [`MTU_SIZE_W-1:0]   pkt_size_queue_rd_data;

    assign pkt_queue_wr_data.data = wr_data;
    assign pkt_queue_wr_data.endframe = wr_end_frame;
    assign pkt_queue_wr_data.startframe = wr_start_frame;
    assign pkt_queue_wr_data.padbytes = wr_end_padbytes;
    
    packet_queue_controller #(
         .width_p           (DROP_QUEUE_STRUCT_W    )
        ,.data_width_p      (`MAC_INTERFACE_W       )
        ,.log2_els_p        (DROP_QUEUE_LOG_ELS     )
    ) rx_pkt_queue (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.wr_req                    (wr_req                 )
        ,.wr_data                   (pkt_queue_wr_data      )
        ,.full                      (full                   )
        ,.start_frame               (wr_start_frame         )
        ,.end_frame                 (wr_end_frame           )
        ,.end_padbytes              (wr_end_padbytes        )

        ,.rd_req                    (rd_req                 )
        ,.empty                     (empty                  )
        ,.rd_data                   (pkt_queue_rd_data      )

        ,.pkt_size_queue_rd_req     (pkt_size_queue_rd_req  )
        ,.pkt_size_queue_empty      ()
        ,.pkt_size_queue_rd_data    (pkt_size_queue_rd_data )
    );

    assign pkt_queue_rx_val = ~empty;

    assign rd_data = pkt_queue_rd_data.data;
    assign rd_start_frame = pkt_queue_rd_data.startframe;
    assign rd_end_frame = pkt_queue_rd_data.endframe;
    assign rd_end_padbytes = pkt_queue_rd_data.padbytes;
    
    packet_size_queue_reader packet_size_queue_reader (
        // is the main interface reading from the data queue
         .data_queue_engine_rx_val          (pkt_queue_rx_val               )
        ,.data_queue_engine_rx_startframe   (pkt_queue_rd_data.startframe   )
        ,.engine_data_queue_rx_rdy          (rd_req                         )
   
        // how we request from the size queue
        ,.reader_size_queue_rd_req          (pkt_size_queue_rd_req          )
        ,.size_queue_reader_rd_data         (pkt_size_queue_rd_data         )
        ,.mac_engine_rx_frame_size          (rd_size                        )
    );
endmodule
