`timescale 1ns / 1ps

module tb_sec_counter;
    reg clk;
    reg rst_n;
    wire [5:0] sec;
    wire sec_overflow;
    
    // 实例化秒计数器
    sec_counter u_sec (
        .clk(clk),
        .rst_n(rst_n),
        .sec(sec),
        .sec_overflow(sec_overflow)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        
        // 测试复位
        #10;
        rst_n = 1;
        
        
        // 运行65个时钟周期，观察进位
        #650;
        
        $finish;
    end
endmodule

`timescale 1ns / 1ps

module tb_min_counter;
    reg clk;
    reg rst_n;
    reg mod_adjust;
    reg add_min;
    reg sec_overflow;
    wire [5:0] min;
    wire min_overflow;
    
    // 实例化分计数器
    min_counter u_min (
        .clk(clk),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .add_min(add_min),
        .sec_overflow(sec_overflow),
        .min(min),
        .min_overflow(min_overflow)
    );
    
    // 快速时钟：1MHz
    always #500 clk = ~clk;
    
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        mod_adjust = 0;
        add_min = 0;
        sec_overflow = 0;
        
        // 复位
        #100;
        rst_n = 1;
        
        $display("开始测试分计数器...");
        $display("模式\t手动\t秒进位\t分值\t分进位");
        
        // 测试1：自动计数模式（60次秒进位）
        $display("\n测试1：自动计数模式");
        repeat(65) begin
            #1000;  // 等待1us
            sec_overflow = 1;
            #10;
            sec_overflow = 0;
            $display("自动\t0\t1\t%d\t%b", min, min_overflow);
        end
        
        // 测试2：手动调整模式
        $display("\n测试2：手动调整模式");
        mod_adjust = 1;
        repeat(5) begin
            #1000;
            add_min = 1;
            #10;
            add_min = 0;
            $display("手动\t1\t0\t%d\t%b", min, min_overflow);
        end
        
        // 测试3：边界条件（59->00）
        $display("\n测试3：边界条件测试");
        // 快速调整到58
        repeat(58) begin
            #100;
            add_min = 1;
            #10;
            add_min = 0;
        end
        $display("调整到58: %d", min);
        
        // 测试进位
        #100;
        add_min = 1;
        #10;
        add_min = 0;
        $display("加1到59: %d, 进位: %b", min, min_overflow);
        
        #100;
        add_min = 1;
        #10;
        add_min = 0;
        $display("加1到00: %d, 进位: %b", min, min_overflow);
        
        $display("分计数器测试完成");
        $finish;
    end
endmodule

`timescale 1ns / 1ps

module tb_seg8_driver;
    reg clk;
    reg [5:0] sec;
    reg [5:0] min;
    reg [4:0] hour;
    wire [7:0] an;
    wire [7:0] seg;
    
    // 实例化数码管驱动
    seg8_driver u_seg8 (
        .clk(clk),
        .sec(sec),
        .min(min),
        .hour(hour),
        .an(an),
        .seg(seg)
    );
    
    // 10MHz时钟（比100MHz慢但足够观察）
    always #50 clk = ~clk;
    
    initial begin
        // 初始化
        clk = 0;
        sec = 6'd30;
        min = 6'd45;
        hour = 5'd12;
        
        $display("开始测试数码管驱动...");
        $display("时间\t位选\t段选");
        
        // 测试不同时间显示
        #100000;  // 观察扫描（100us）
        
        // 改变时间值
        sec = 6'd59;
        min = 6'd59;
        hour = 5'd23;
        #100000;
        
        // 测试边界值
        sec = 6'd0;
        min = 6'd0;
        hour = 5'd0;
        #100000;
        
        $display("数码管驱动测试完成");
        $finish;
    end
endmodule

`timescale 1ns / 1ps

module tb_alarmLED;
    reg CLK_1Hz;
    reg rst_n;
    reg alarm_en;
    wire alarm;
    
    // 实例化闹钟LED
    alarmLED u_alarm (
        .CLK_1Hz(CLK_1Hz),
        .rst_n(rst_n),
        .alarm_en(alarm_en),
        .alarm(alarm)
    );
    
    // 快速时钟：1kHz (1ms周期)
    always #500000 CLK_1Hz = ~CLK_1Hz;  // 1kHz时钟
    
    initial begin
        // 初始化
        CLK_1Hz = 0;
        rst_n = 0;
        alarm_en = 0;
        
        // 复位
        #100;
        rst_n = 1;
        
        $display("开始测试闹钟LED...");
        $display("时间\t使能\tLED状态");
        
        // 测试1：正常情况，无闹钟
        #2000000;
        
        // 测试2：触发闹钟
        alarm_en = 1;
        #15000000;  // 观察完整闪烁周期（15ms）
        
        // 测试3：关闭闹钟
        alarm_en = 0;
        #2000000;
        
        // 测试4：再次触发
        alarm_en = 1;
        #8000000;
        
        $display("闹钟LED测试完成");
        $finish;
    end
endmodule

`timescale 1ns / 1ps

module tb_ealarm;
    reg CLK_1Hz;
    reg rst_n;
    reg mod_adjust;
    reg add_min;
    reg add_hour;
    reg [5:0] min;
    reg [4:0] hour;
    wire alarm;
    wire [5:0] min_set;
    wire [4:0] hour_set;
    
    // 实例化闹钟模块
    ealarm u_ealarm (
        .CLK_1Hz(CLK_1Hz),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .add_min(add_min),
        .add_hour(add_hour),
        .min(min),
        .hour(hour),
        .alarm(alarm),
        .min_set(min_set),
        .hour_set(hour_set)
    );
    
    // 快速时钟：1kHz
    always #500000 CLK_1Hz = ~CLK_1Hz;
    
    initial begin
        // 初始化
        CLK_1Hz = 0;
        rst_n = 0;
        mod_adjust = 0;
        add_min = 0;
        add_hour = 0;
        min = 6'd0;
        hour = 5'd0;
        
        // 复位
        #100;
        rst_n = 1;
        
        $display("开始测试闹钟模块...");
        $display("时间\t模式\t当前时间\t闹钟设置\t闹钟状态");
        
        // 测试1：设置闹钟
        $display("\n测试1：设置闹钟时间");
        mod_adjust = 1;
        
        // 设置闹钟为08:30
        repeat(8) begin
            #1000000;  // 1ms间隔
            add_hour = 1;
            #10;
            add_hour = 0;
        end
        $display("闹钟小时设置: %d", hour_set);
        
        repeat(30) begin
            #1000000;
            add_min = 1;
            #10;
            add_min = 0;
        end
        $display("闹钟分钟设置: %d", min_set);
        
        // 测试2：闹钟触发
        $display("\n测试2：闹钟触发测试");
        mod_adjust = 0;
        min = 6'd30;
        hour = 5'd8;
        #1000000;
        $display("%0t\t正常\t%02d:%02d\t%02d:%02d\t%b", 
                 $time, hour, min, hour_set, min_set, alarm);
        
        $display("闹钟模块测试完成");
        $finish;
    end
endmodule

`timescale 1ns / 1ps

module tb_Hourly_Alarm;
    reg CLK_1Hz;
    reg rst_n;
    reg mod_adjust;
    reg [5:0] min;
    wire alarm;
    
    // 实例化整点报时模块
    Hourly_Alarm u_hourly (
        .CLK_1Hz(CLK_1Hz),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .min(min),
        .alarm(alarm)
    );
    
    // 快速时钟：1kHz
    always #500000 CLK_1Hz = ~CLK_1Hz;
    
    initial begin
        // 初始化
        CLK_1Hz = 0;
        rst_n = 0;
        mod_adjust = 0;
        min = 6'd0;
        
        // 复位
        #100;
        rst_n = 1;
        
        $display("开始测试整点报时模块...");
        $display("时间\t模式\t分钟\t报时状态");
        
        // 测试不同分钟值
        min = 6'd0;
        #1000000;
        $display("%0t\t正常\t%d\t%b", $time, min, alarm);
        
        min = 6'd1;
        #1000000;
        $display("%0t\t正常\t%d\t%b", $time, min, alarm);
        
        min = 6'd59;
        #1000000;
        $display("%0t\t正常\t%d\t%b", $time, min, alarm);
        
        min = 6'd0;
        #1000000;
        $display("%0t\t正常\t%d\t%b", $time, min, alarm);
        
        // 测试调整模式下不报时
        $display("\n测试调整模式");
        mod_adjust = 1;
        min = 6'd0;
        #1000000;
        $display("%0t\t调整\t%d\t%b", $time, min, alarm);
        
        $display("整点报时模块测试完成");
        $finish;
    end
endmodule

