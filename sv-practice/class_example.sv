`timescale 1ns/1ps

// 教学例子：class 三件套（属性 / 构造函数 new() / 方法）+ 对象使用四步
class car;
    string name;        // 属性 1：车名
    int    speed;       // 属性 2：速度
    int    distance;    // 属性 3：总里程

    function new(string n, int s);  // 构造函数：new 创建对象时自动调用，负责初始化
        name     = n;               // 把传进来的车名存进本对象的属性
        speed    = s;               // 把传进来的速度存进本对象的属性
        distance = 0;               // 新车里程清零
    endfunction

    function void run(int km);      // 方法：跑 km 公里
        distance = distance + km;   // 方法里可以直接读写自己的属性
    endfunction

    function void display();        // 方法：打印仪表盘
        $display("car %s: speed=%0d km/h, total=%0d km", name, speed, distance);
    endfunction
endclass

module tb_car;
    car c;                          // 1. 声明句柄（遥控器，先不指向任何车）
    initial begin
        c = new("bmw", 120);        // 2. new：造车 + 自动调构造函数填初值
        c.display();                // 3. 点号调用方法（按遥控器上的按钮）
        c.run(50);                  // 4. 跑 50 公里，方法内部改的是这辆车的属性
        c.display();
    end
endmodule
