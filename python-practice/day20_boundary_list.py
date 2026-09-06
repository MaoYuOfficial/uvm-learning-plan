#用来一步写完今天的赋值
values = [0x00, 0xFF, 0x55, 0xAA]   
for i in range(8):                   
    values.append(1 << i)            
for v in values:                     
    print(f"t = new(8'h{v:02x}, 1, 0, 434);")   
    print("queue.push_back(t);")                