`timescale 1ns / 1ps

module tb_sec_counter;

    reg clk;
    reg rst_n;
    wire [5:0] sec;
    wire sec_overflow;
    
    sec_counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .sec(sec),
        .sec_overflow(sec_overflow)
    );
    
    // 快速时钟：1MHz (1us周期)
    always #0.5 clk = ~clk;
    
    initial begin
        $display("=== 秒计数器测试 ===");
        
        clk = 0;
        rst_n = 1;
        
        #2 rst_n = 0;
        #4 rst_n = 1;
        
        $display("时间(us) | sec | overflow | 说明");
        $display("---------|-----|----------|------");
        
        // 初始状态
        @(posedge clk);
        #0.1;
        $display(" %4t | %2d | %b | 初始状态", 
                $time, sec, sec_overflow);
        
        $display("\n--- 测试1: 正常计数0-59 ---");
        // 观察前10秒计数
        repeat(10) begin
            @(posedge clk);
            #0.1;
            $display(" %4t | %2d | %b | 正常计数", 
                    $time, sec, sec_overflow);
        end
        
        $display("\n--- 测试2: 进位边界测试 ---");
        // 快速跳到58秒
        while (sec < 58) @(posedge clk);
        $display(" %4t | %2d | %b | 到达58秒", 
                $time, sec, sec_overflow);
        
        // 59秒
        @(posedge clk);
        #0.1;
        $display(" %4t | %2d | %b | 到达59秒", 
                $time, sec, sec_overflow);
        
        // 进位到00
        @(posedge clk);
        #0.1;
        $display(" %4t | %2d | %b | 进位到00", 
                $time, sec, sec_overflow);
        
        $display("\n--- 测试3: 复位测试 ---");
        // 计数几秒后复位
        repeat(5) @(posedge clk);
        $display(" %4t | %2d | %b | 计数中", 
                $time, sec, sec_overflow);
        
        rst_n = 0;
        @(posedge clk);
        #0.1;
        $display(" %4t | %2d | %b | 复位后", 
                $time, sec, sec_overflow);
        
        rst_n = 1;
        @(posedge clk);
        #0.1;
        $display(" %4t | %2d | %b | 复位释放", 
                $time, sec, sec_overflow);
        
        $display("\n? 秒计数器测试完成!");
        $finish;
    end
    
    // 监控进位信号
    always @(posedge clk) begin
        if (sec_overflow) begin
            $display(" [进位检测] 秒计数器从59进位到00");
        end
    end

endmodule

module tb_min_counter;

    reg clk;
    reg rst_n;
    reg mod_adjust;
    reg sec_overflow;
    reg add_min;
    wire [5:0] min;
    wire min_overflow;
    
    min_counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .sec_overflow(sec_overflow),
        .add_min(add_min),
        .min(min),
        .min_overflow(min_overflow)
    );
    
    // 快速时钟：1MHz
    always #0.5 clk = ~clk;
    
    initial begin
        $display("=== 分钟计数器测试 ===");
        
        clk = 0;
        rst_n = 1;
        mod_adjust = 0;
        sec_overflow = 0;
        add_min = 0;
        
        #2 rst_n = 0;
        #4 rst_n = 1;
        
        $display("时间(us) | mod | add | min | overflow | 说明");
        $display("---------|-----|-----|-----|----------|------");
        
        // 初始状态
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | %b | 初始状态", 
                $time, mod_adjust, add_min, min, min_overflow);
        
        $display("\n--- 测试1: 正常模式响应秒进位 ---");
        mod_adjust = 0;
        
        // 模拟60次秒进位
        repeat(60) begin
            @(posedge clk);
            sec_overflow = 1;
            #0.1;
            $display(" %4t | %b | %b | %2d | %b | 秒进位响应", 
                    $time, mod_adjust, add_min, min, min_overflow);
            @(posedge clk);
            sec_overflow = 0;
        end
        
        $display("\n--- 测试2: 调时模式 ---");
        mod_adjust = 1;
        add_min = 1;
        
        repeat(5) begin
            @(posedge clk);
            #0.1;
            $display(" %4t | %b | %b | %2d | %b | 调时增加", 
                    $time, mod_adjust, add_min, min, min_overflow);
        end
        
        add_min = 0;
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | %b | 停止调时", 
                $time, mod_adjust, add_min, min, min_overflow);
        
        $display("\n--- 测试3: 进位边界测试 ---");
        mod_adjust = 1;
        add_min = 1;
        
        // 快速调到58分
        while (min < 58) @(posedge clk);
        $display(" %4t | %b | %b | %2d | %b | 到达58分", 
                $time, mod_adjust, add_min, min, min_overflow);
        
        // 继续到59分
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | %b | 到达59分", 
                $time, mod_adjust, add_min, min, min_overflow);
        
        // 进位到00
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | %b | 进位到00", 
                $time, mod_adjust, add_min, min, min_overflow);
        
        $display("\n? 分钟计数器测试完成!");
        $finish;
    end

endmodule

module tb_hour_counter;

    reg clk;
    reg rst_n;
    reg mod_adjust;
    reg min_overflow;
    reg add_hour;
    reg base_conversion;
    wire [4:0] hour;
    
    hour_counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .min_overflow(min_overflow),
        .base_conversion(base_conversion),
        .add_hour(add_hour),
        .hour(hour)
    );
    
    // 快速时钟：1MHz
    always #0.5 clk = ~clk;
    
    initial begin
        $display("=== 小时计数器测试 ===");
        
        clk = 0;
        rst_n = 1;
        mod_adjust = 0;
        min_overflow = 0;
        add_hour = 0;
        base_conversion = 0;
        
        #2 rst_n = 0;
        #4 rst_n = 1;
        
        $display("时间(us) | mod | add | hour | 说明");
        $display("---------|-----|-----|------|------");
        
        // 初始状态
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | 初始状态", 
                $time, mod_adjust, add_hour, hour);
        
        $display("\n--- 测试1: 正常模式响应分进位 ---");
        mod_adjust = 0;
        
        // 模拟24次分进位
        repeat(24) begin
            @(posedge clk);
            min_overflow = 1;
            #0.1;
            $display(" %4t | %b | %b | %2d | 分进位响应", 
                    $time, mod_adjust, add_hour, hour);
            @(posedge clk);
            min_overflow = 0;
        end
        
        $display("\n--- 测试2: 调时模式 ---");
        mod_adjust = 1;
        add_hour = 1;
        
        repeat(5) begin
            @(posedge clk);
            #0.1;
            $display(" %4t | %b | %b | %2d | 调时增加", 
                    $time, mod_adjust, add_hour, hour);
        end
        
        add_hour = 0;
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | 停止调时", 
                $time, mod_adjust, add_hour, hour);
        
        $display("\n--- 测试3: 24小时循环测试 ---");
        mod_adjust = 1;
        add_hour = 1;
        
        // 快速调到23时
        while (hour < 23) @(posedge clk);
        $display(" %4t | %b | %b | %2d | 到达23时", 
                $time, mod_adjust, add_hour, hour);
        
        // 进位到00
        @(posedge clk);
        #0.1;
        $display(" %4t | %b | %b | %2d | 进位到00", 
                $time, mod_adjust, add_hour, hour);
        
        $display("\n? 小时计数器测试完成!");
        $finish;
    end

endmodule

module tb_alarmLED;

    reg CLK_1Hz;
    reg rst_n;
    reg alarm_en;
    wire alarm;
    
    alarmLED uut (
        .CLK_1Hz(CLK_1Hz),
        .rst_n(rst_n),
        .alarm_en(alarm_en),
        .alarm(alarm)
    );
    
    // 快速时钟：1MHz
    always #0.5 CLK_1Hz = ~CLK_1Hz;
    
    initial begin
        $display("=== 闹钟LED闪烁测试 ===");
        
        CLK_1Hz = 0;
        rst_n = 1;
        alarm_en = 0;
        
        #2 rst_n = 0;
        #4 rst_n = 1;
        
        $display("时间(us) | alarm_en | alarm | 闪烁次数 | 状态");
        $display("---------|----------|-------|----------|------");
        
        // 初始状态
        repeat(2) @(posedge CLK_1Hz);
        $display(" %4t | %b | %b | - | 初始状态", 
                $time, alarm_en, alarm);
        
        $display("\n--- 测试1: 触发闹钟闪烁3次 ---");
        alarm_en = 1;
        
        // 观察完整闪烁过程
        repeat(12) begin
            @(posedge CLK_1Hz);
            #0.1;
            $display(" %4t | %b | %b | 闪烁中 | LED状态", 
                    $time, alarm_en, alarm);
        end
        
        $display("\n--- 测试2: 关闭闹钟 ---");
        alarm_en = 0;
        repeat(2) @(posedge CLK_1Hz);
        $display(" %4t | %b | %b | - | 闹钟关闭", 
                $time, alarm_en, alarm);
        
        $display("\n--- 测试3: 再次触发测试 ---");
        alarm_en = 1;
        repeat(6) @(posedge CLK_1Hz);
        $display(" %4t | %b | %b | 再次闪烁 | 重新触发", 
                $time, alarm_en, alarm);
        
        $display("\n? 闹钟LED测试完成!");
        $finish;
    end

endmodule

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
    
    ealarm uut (
        .CLK_1Hz(CLK_1Hz),
        .rst_n(rst_n),
        .mod_adjust(mod_adjust),
        .add_min(add_min),
        .add_hour(add_hour),
        .min(min),
        .hour(hour),
        .alarm(alarm),
        .min_set_out(min_set),
        .hour_set_out(hour_set)
    );
    
    // 快速时钟：1MHz
    always #0.5 CLK_1Hz = ~CLK_1Hz;
    
    initial begin
        $display("=== 闹钟模块测试 ===");
        
        CLK_1Hz = 0;
        rst_n = 1;
        mod_adjust = 0;
        add_min = 0;
        add_hour = 0;
        min = 6'd0;
        hour = 5'd0;
        
        #2 rst_n = 0;
        #4 rst_n = 1;
        
        $display("时间(us) | 当前时间 | 闹钟设置 | alarm_en | alarm | 状态");
        $display("---------|----------|----------|----------|-------|------");
        
        // 初始状态
        @(posedge CLK_1Hz);
        #0.1;
        $display(" %4t | %02d:%02d | %02d:%02d | - | %b | 初始", 
                $time, hour, min, hour_set, min_set, alarm);
        
        $display("\n--- 测试1: 设置闹钟时间 ---");
        mod_adjust = 1;
        add_min = 1;
        
        // 设置分钟为05
        repeat(5) @(posedge CLK_1Hz);
        add_min = 0;
        
        add_hour = 1;
        // 设置小时为01
        @(posedge CLK_1Hz);
        add_hour = 0;
        
        mod_adjust = 0;
        
        $display(" %4t | %02d:%02d | %02d:%02d | - | %b | 闹钟设置完成", 
                $time, hour, min, hour_set, min_set, alarm);
        
        $display("\n--- 测试2: 触发闹钟 ---");
        // 设置当前时间等于闹钟时间
        min = min_set;
        hour = hour_set;
        
        repeat(8) begin
            @(posedge CLK_1Hz);
            #0.1;
            $display(" %4t | %02d:%02d | %02d:%02d | 1 | %b | 闹钟触发", 
                    $time, hour, min, hour_set, min_set, alarm);
        end
        
        $display("\n--- 测试3: 时间不匹配测试 ---");
        min = 6'd10;  // 改变当前时间
        hour = 5'd2;
        
        repeat(3) @(posedge CLK_1Hz);
        $display(" %4t | %02d:%02d | %02d:%02d | 0 | %b | 时间不匹配", 
                $time, hour, min, hour_set, min_set, alarm);
        
        $display("\n? 闹钟模块测试完成!");
        $finish;
    end

endmodule


`timescale 1ns / 1ps

module tb_seg8_quick;

    reg clk;
    reg [5:0] sec;
    reg [5:0] min;
    reg [4:0] hour;
    wire [7:0] an;
    wire [7:0] seg;
    
    seg8_driver uut(
        .clk(clk),
        .sec(sec),
        .min(min),
        .hour(hour),
        .an(an),
        .seg(seg)
    );
    
    // 快速时钟：1MHz
    always #0.5 clk = ~clk;
    
    initial begin
        $display("=== 快速数码管验证 ===");
        
        clk = 0;
        sec = 6'd32;
        min = 6'd28;
        hour = 5'd13;
        
        $display("测试时间: %02d:%02d:%02d", hour, min, sec);
        
        // 观察扫描
        $display("观察数码管扫描...");
        repeat(20) begin
            @(posedge clk);
            #0.1;
            if (an != 8'b11111111) begin
                $display("  位选: %b, 段选: %b", an, seg);
            end
        end
        
        // 改变时间
        $display("\n改变时间到 20:30:30");
        sec = 6'd30;
        min = 6'd30;
        hour = 5'd20;
        
        repeat(20) begin
            @(posedge clk);
            #0.1;
            if (an != 8'b11111111) begin
                $display("  位选: %b, 段选: %b", an, seg);
            end
        end
        
        $display("\n? 快速验证完成!");
        $finish;
    end

endmodule

