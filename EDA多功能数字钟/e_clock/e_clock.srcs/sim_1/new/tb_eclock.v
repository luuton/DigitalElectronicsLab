`timescale 1ns/1ps

module tb_eclock;

    // -----------------------------
    // DUT 端口信号
    // -----------------------------
    reg CLK;
    reg rst_n;
    reg add_min;
    reg add_hour;
    reg mod_adjust;
    reg mod_alarm;
    reg base_conversion;

    wire [2:0] LED;
    wire [7:0] an;
    wire [7:0] seg;
    wire hourly_LED;
    wire alarm_LED;

    // -----------------------------
    // 生成 100MHz 时钟（10ns 周期）
    // -----------------------------
    initial CLK = 0;
    always #0.5 CLK = ~CLK;


    // -----------------------------
    // DUT 实例化
    // -----------------------------
    eclock dut(
        .LED(LED),
        .CLK(CLK),
        .add_min(add_min),
        .add_hour(add_hour),
        .mod_adjust(mod_adjust),
        .mod_alarm(mod_alarm),
        .base_conversion(base_conversion),
        .rst_n(rst_n),
        .an(an),
        .seg(seg),
        .hourly_LED(hourly_LED),
        .alarm_LED(alarm_LED)
    );


    // -----------------------------
    // 覆盖 Divider 的参数以快速仿真
    // -----------------------------
    defparam dut.divider.DIVIDER = 5; 
    // ? 让 1Hz 时钟变成分频 10 个周期，非常快


    // -----------------------------
    // 激励过程
    // -----------------------------
    initial begin
        // 初值
        rst_n = 0;
        add_min = 0;
        add_hour = 0;
        mod_adjust = 0;
        mod_alarm = 0;
        base_conversion = 0;

        // 复位
        #100;
        rst_n = 1;

        // 等待几个"快速 1Hz"周期
        repeat(10) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 1）正常跑时间
        // --------------------------
        $display("=== 测试：正常计时 ===");
        repeat(20) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 2）进入校时模式：调分钟
        // --------------------------
        $display("=== 测试：校时模式 调分钟 ===");
        mod_adjust = 1;
        add_min = 1; @(posedge CLK); add_min = 0;
        repeat(5) @(posedge dut.CLK_1Hz);  // 看是否只加 1
        add_min = 1; @(posedge CLK); add_min = 0;
        repeat(5) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 3）校时模式：调小时
        // --------------------------
        $display("=== 测试：校时模式 调小时 ===");
        add_hour = 1; @(posedge CLK); add_hour = 0;
        repeat(5) @(posedge dut.CLK_1Hz);
        add_hour = 1; @(posedge CLK); add_hour = 0;
        repeat(5) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 4）退出校时模式，继续正常走
        // --------------------------
        mod_adjust = 0;
        $display("=== 退出校时模式 ===");
        repeat(20) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 5）测试闹钟模式
        // --------------------------
        $display("=== 测试：闹钟设置 ===");
        mod_alarm = 1;
        mod_adjust = 1;

        // 设置闹钟 01:01（示例）
        add_hour = 1; @(posedge CLK); add_hour = 0;
        add_min = 1; @(posedge CLK); add_min = 0;

        mod_alarm = 0;
        mod_adjust = 0;

        // 让时间走，让 alarm_LED 触发
        repeat(50) @(posedge dut.CLK_1Hz);

        // --------------------------
        // 6）测试 12/24 小时制
        // --------------------------
        $display("=== 测试：12/24 小时制切换 ===");
        base_conversion = 1;
        repeat(20) @(posedge dut.CLK_1Hz);
        base_conversion = 0;
        repeat(20) @(posedge dut.CLK_1Hz);

        $display("=== 测试结束 ===");
        $stop;
    end

endmodule
