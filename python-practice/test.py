import numpy as np
import matplotlib.pyplot as plt
x = np.linspace(0, 0.8, 100)
y = 1e-9 * (np.exp(x / 0.05) - 1)   # 模拟二极管 I-V
plt.plot(x, y)
plt.show()          # 图表窗口会弹出来
print("Python 就绪！")