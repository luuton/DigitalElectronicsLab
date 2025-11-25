`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/18 19:06:08
// Design Name: 
// Module Name: eclock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 电子时钟模块，包含时分秒计时和数码管显示功能
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module eclock(
    output [2:0] LED,
    input CLK,              // 100MHz主时钟输入
    input add_min,          // 分钟调整信号（上升沿有效）
    input add_hour,         // 小时调整信号（上升沿有效）
    input mod_adjust,
    input rst_n,            // 异步复位信号（低电平有效）
    output [7:0] an,        // 数码管位选信号（低电平有效）
    output [7:0] seg        // 数码管段选信号（低电平有效，共阴极）
);
    // 内部信号定义
    wire CLK_1Hz;           // 1Hz时钟信号
    wire [5:0] sec;         // 秒计数器输出（0-59）
    wire [5:0] min;         // 分计数器输出（0-59）
    wire [4:0] hour;        // 时计数器输出（0-23）
    wire sec_carry;         // 秒计数器进位信号
    wire min_carry;         // 分计数器进位信号

    // 分频器实例：将50MHz时钟分频为1Hz
    Divider100MHz_1Hz divider(
        .CR(rst_n),                 // 复位信号
        .CLK_100MHz(CLK),           // 100MHz输入时钟
        .CLK_1Hz_Out(CLK_1Hz)       // 1Hz输出时钟
    );

    // 测试led
    assign LED[0] = CLK_1Hz;
    assign LED[1] = sec[0];
    assign LED[2] = sec_carry;
    

    // 秒计数器实例：60进制计数器a
    sec_counter u_sec (
        .clk(CLK_1Hz),
        .rst_n(rst_n),
        .sec(sec),
        .sec_overflow(sec_carry)
    );

    // 分计数器实例：60进制计数器，支持手动调整
    min_counter u_min (
        .clk(CLK_1Hz),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .sec_overflow(sec_carry),
        .add_min(add_min),
        .min(min),
        .min_overflow(min_carry)
    );

    // 时计数器实例：24进制计数器，支持手动调整
    hour_counter u_hour (
        .clk(CLK_1Hz),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .min_overflow(min_carry),
        .add_hour(add_hour),
        .hour(hour)
    );

    // 数码管显示驱动实例
    seg8_driver u_seg8 (
        .clk(CLK),                  // 100MHz扫描时钟
        .sec(sec),                  // 秒计数值输入
        .min(min),                  // 分计数值输入
        .hour(hour),                // 时计数值输入
        .an(an),                    // 位选信号输出
        .seg(seg)                   // 段选信号输出
    );
endmodule

// 八段数码管显示驱动模块
module seg8_driver (
    input clk,          // 100MHz时钟输入
    input [5:0] sec,    // 秒计数值输入（0-59）
    input [5:0] min,    // 分计数值输入（0-59）
    input [4:0] hour,   // 时计数值输入（0-23）
    output reg [7:0] an,// 位选信号输出（低电平有效）
    output reg [7:0] seg // 段选信号输出（低电平有效，共阴极）
);
    // 内部寄存器定义
    reg [19:0] scan_cnt = 0;       // 扫描计数器（100MHz分频至约1kHz）
    reg [2:0] digit_sel = 0;       // 当前扫描位选择（0-7）
    reg [3:0] current_digit;       // 当前显示的数字值
    reg dp_en;                     // 小数点使能信号

    // 动态扫描控制：生成约1kHz的扫描频率
    always @(posedge clk) begin
        scan_cnt <= scan_cnt + 1;
        if (scan_cnt == 20'd100_000) begin  // 100MHz/100000 = 1kHz
//        if (scan_cnt == 20'd10) begin
            scan_cnt <= 0;
            digit_sel <= (digit_sel == 3'd7) ? 0 : digit_sel + 1; // 循环扫描0-7位
        end
    end


    // nexys4板子为了节约成本？每次只能控制一个八位数码管，需要通过选位信号选择
    // 位选信号生成：根据当前扫描位选择对应的数码管
    always @(*) begin
        an = 8'b11111111;  // 默认所有数码管关闭
        case (digit_sel)
            0: an[0] = 1'b0; // 第0位：小时十位数码管
            1: an[1] = 1'b0; // 第1位：小时个位数码管
            2: an[2] = 1'b0; // 第2位：分隔符号码管
            3: an[3] = 1'b0; // 第3位：分钟十位数码管
            4: an[4] = 1'b0; // 第4位：分钟个位数码管
            5: an[5] = 1'b0; // 第5位：分隔符
            6: an[6] = 1'b0; // 第6位：秒十位
            7: an[7] = 1'b0; // 第7位：秒个位
            default: an = 8'b11111111; // 默认关闭所有
        endcase
    end

    // 数据选择与段码生成
    always @(*) begin
        case (digit_sel)
            // 根据扫描位选择对应的数字数据
            0: begin current_digit = hour / 10;  dp_en = 0; end  // 小时十位
            1: begin current_digit = hour % 10;  dp_en = 0; end  // 小时个位
            2: begin current_digit = 4'hA;       dp_en = 0; end  // 分隔符
            3: begin current_digit = min / 10;   dp_en = 0; end  // 分钟十位
            4: begin current_digit = min % 10;   dp_en = 0; end  // 分钟个位
            5: begin current_digit = 4'hA;       dp_en = 0; end  // 分隔符
            6: begin current_digit = sec / 10;   dp_en = 0; end  // 秒十位
            7: begin current_digit = sec % 10;   dp_en = 0; end  // 秒个位
            default: begin current_digit = 4'h0; dp_en = 0; end  // 默认显示0
        endcase

        // 七段数码管译码：共阴极配置
        case (current_digit)
            4'h0: seg[6:0] = 7'b1000000; // 数字0
            4'h1: seg[6:0] = 7'b1111001; // 数字1
            4'h2: seg[6:0] = 7'b0100100; // 数字2
            4'h3: seg[6:0] = 7'b0110000; // 数字3
            4'h4: seg[6:0] = 7'b0011001; // 数字4
            4'h5: seg[6:0] = 7'b0010010; // 数字5
            4'h6: seg[6:0] = 7'b0000010; // 数字6
            4'h7: seg[6:0] = 7'b1111000; // 数字7
            4'h8: seg[6:0] = 7'b0000000; // 数字8
            4'h9: seg[6:0] = 7'b0010000; // 数字9
            4'hA: seg[6:0] = 7'b0111111; // 分隔符"-"（仅中间段亮）
            default: seg[6:0] = 7'b1111111; // 默认全灭
        endcase
        seg[7] = ~dp_en; // 小数点控制（低电平点亮）
    end
endmodule

module sec_counter(
    input  clk,              // 1Hz时钟
    input  rst_n,
    output reg [5:0] sec,
    output sec_overflow      // 秒溢出，分计数器使用
);

    wire sec_ovf = (sec == 6'd59);
    wire [5:0] sec_next = sec_ovf ? 6'd0 : sec + 1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            sec <= 0;
        else
            sec <= sec_next;
    end

    assign sec_overflow = sec_ovf;

endmodule

module min_counter(
    input  clk,
    input  rst_n,
    input  mod_adjust,        // 调节模式使能
    input  add_min,           // 手动分+1（上升沿触发）
    input  sec_overflow,      // 秒溢出自动加1
    output reg [5:0] min,
    output min_overflow       // 分溢出，小时计数器使用
);

    wire inc = (!mod_adjust && sec_overflow) || (mod_adjust && add_min);

    wire min_ovf = (min == 6'd59) && inc;
    wire [5:0] min_next = min_ovf ? 6'd0 : (min + inc);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            min <= 0;
        else
            min <= min_next;
    end

    assign min_overflow = min_ovf;

endmodule

module hour_counter(
    input  clk,
    input  rst_n,
    input  mod_adjust,
    input  add_hour,          // 手动时+1（上升沿触发）
    input  min_overflow,      // 分溢出自动加1
    output reg [4:0] hour
);

    wire inc = (!mod_adjust && min_overflow) || (mod_adjust && add_hour);

    wire [4:0] hour_next = (hour == 5'd23) && inc ? 5'd0 : (hour + inc);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            hour <= 0;
        else
            hour <= hour_next;
    end

endmodule

module Divider100MHz_1Hz(
    input  CR,
    input  CLK_100MHz,
    output reg CLK_1Hz_Out
);
    reg [26:0] count_div;  // 27位计数器
    parameter DIVIDER = 50_000_000;  // 100MHz到1Hz
//    parameter DIVIDER = 5;
    
    always @(posedge CLK_100MHz or negedge CR) begin
        if (!CR) begin
            CLK_1Hz_Out <= 0;
            count_div <= 0;
        end
        else begin
            if (count_div == DIVIDER - 1) begin
                count_div <= 0;
                CLK_1Hz_Out <= ~CLK_1Hz_Out;
            end
            else begin
                count_div <= count_div + 1;
            end
        end
    end
endmodule
