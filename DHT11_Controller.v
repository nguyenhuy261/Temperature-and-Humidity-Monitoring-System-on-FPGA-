module DHT11_Controller (
    input               clk,       // Clock 50MHz
    input               rst_n,     // Reset active-low
    inout               dht11,     // DHT11 data pin
    output reg  [31:0]  data_valid, // Output temperature & humidity (valid data)
    output wire [5:0]   data_count_out // Xuất số bit nhận được
);

/************** Parameter ********************/
parameter  POWER_ON_NUM  = 1000_000;  
parameter  S_POWER_ON    = 3'd0;     
parameter  S_LOW_20MS    = 3'd1;     
parameter  S_HIGH_13US   = 3'd2;    
parameter  S_LOW_83US    = 3'd3;      
parameter  S_HIGH_87US   = 3'd4;      
parameter  S_SEND_DATA   = 3'd5;      
parameter  S_DELAY       = 3'd6; 

/************** Register Define ********************/              
reg [2:0]  cur_state, next_state;        
reg [20:0] count_1us;       
reg [5:0]  data_count;                                       
reg [39:0] data_temp;        
reg [4:0]  clk_cnt;
reg        clk_1M;       
reg        us_clear;        
reg        state;        
reg        dht_buffer;        
reg        dht_d0, dht_d1;        

/************** Wire Define ********************/
wire dht_podge, dht_nedge;  

assign dht11 = dht_buffer;
assign dht_podge = ~dht_d1 & dht_d0; // Posedge detect
assign dht_nedge = dht_d1 & ~dht_d0; // Negedge detect
assign data_count_out = data_count;

/************** 1MHz Clock Generator ********************/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 5'd0;
        clk_1M  <= 1'b0;
    end 
    else if (clk_cnt < 5'd24) 
        clk_cnt <= clk_cnt + 1'b1;       
    else begin
        clk_cnt <= 5'd0;
        clk_1M  <= ~clk_1M;
    end 
end

/************** 1us Counter ********************/
always @(posedge clk_1M or negedge rst_n) begin
    if (!rst_n)
        count_1us <= 21'd0;
    else if (us_clear)
        count_1us <= 21'd0;
    else 
        count_1us <= count_1us + 1'b1;
end 

/************** State Machine ********************/
always @(posedge clk_1M or negedge rst_n) begin
    if (!rst_n)
        cur_state <= S_POWER_ON;
    else 
        cur_state <= next_state;
end 

always @(posedge clk_1M or negedge rst_n) begin
    if(!rst_n) begin
        next_state <= S_POWER_ON;
        dht_buffer <= 1'bz;   
        state      <= 1'b0; 
        us_clear   <= 1'b0;
        data_temp  <= 40'd0;
        data_count <= 6'd0;
    end 
    else begin
        case (cur_state)     
            S_POWER_ON: begin 
                if(count_1us < POWER_ON_NUM) begin
                    dht_buffer <= 1'bz; 
                    us_clear   <= 1'b0;
                end else begin            
                    next_state <= S_LOW_20MS;
                    us_clear   <= 1'b1;
                end
            end
                
            S_LOW_20MS: begin 
                if(count_1us < 20000) begin
                    dht_buffer <= 1'b0; 
                    us_clear   <= 1'b0;
                end else begin
                    next_state   <= S_HIGH_13US;
                    dht_buffer <= 1'bz; 
                    us_clear   <= 1'b1;
                end    
            end 
               
            S_HIGH_13US: begin 
                if (count_1us < 20) begin
                    us_clear <= 1'b0;
                    if (dht_nedge) begin   
                        next_state <= S_LOW_83US;
                        us_clear   <= 1'b1; 
                    end
                end else begin                     
                    next_state <= S_DELAY;
                end
            end 
                
            S_LOW_83US: begin 
                if (dht_podge)                    
                    next_state <= S_HIGH_87US;  
            end 
                
            S_HIGH_87US: begin 
                if (dht_nedge) begin          
                    next_state <= S_SEND_DATA; 
                    us_clear   <= 1'b1;
                end else begin                
                    data_count <= 6'd0;
                    data_temp  <= 40'd0;
                    state      <= 1'b0;
                end
            end 
                  
            S_SEND_DATA: begin 
                case (state)
                    0: begin               
                        if (dht_podge) begin 
                            state    <= 1'b1;
                            us_clear <= 1'b1;
                        end else begin               
                            us_clear <= 1'b0;
                        end
                    end
                    1: begin               
                        if (dht_nedge) begin 
                            data_count <= data_count + 1'b1;
                            state      <= 1'b0;
                            us_clear   <= 1'b1;              
                            if (count_1us < 60)
                                data_temp <= {data_temp[38:0],1'b0}; // 0
                            else                
                                data_temp <= {data_temp[38:0],1'b1}; // 1
                        end else begin                                         
                            us_clear <= 1'b0;
                        end
                    end
                endcase
                
                if(data_count == 40) begin  
                    next_state <= S_DELAY;
                end
            end 
                
            S_DELAY: begin 
                if (count_1us < 2000_000)
                    us_clear <= 1'b0;
                else begin                 
                    next_state <= S_LOW_20MS; 
                    us_clear   <= 1'b1;
                end
            end

            default: next_state <= S_POWER_ON;
        endcase
    end 
end

/************** Checksum Verification ********************/
always @(posedge clk_1M or negedge rst_n) begin
    if (!rst_n) begin
        data_valid <= 32'd0;
    end 
    else if (data_count == 40) begin
        reg [7:0] humidity_int, humidity_dec;
        reg [7:0] temperature_int, temperature_dec;
        reg [7:0] checksum, checksum_calc;

        humidity_int    = data_temp[39:32];  
        humidity_dec    = data_temp[31:24];  
        temperature_int = data_temp[23:16];  
        temperature_dec = data_temp[15:8];   
        checksum        = data_temp[7:0];    

        checksum_calc = humidity_int + humidity_dec + temperature_int + temperature_dec;

        if (checksum == checksum_calc) begin
            data_valid <= data_temp[39:8]; 
        end
        else begin
            data_valid <= 32'd0;
        end
    end
end


/************** Edge Detection ********************/
always @(posedge clk_1M or negedge rst_n) begin
    if (!rst_n) begin
        dht_d0 <= 1'b1;
        dht_d1 <= 1'b1;
    end 
    else begin
        dht_d0 <= dht11;
        dht_d1 <= dht_d0;
    end 
end 

endmodule  
