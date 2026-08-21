# -*- coding: utf-8 -*-
"""Day13: 0x33 UART 帧电平图（LSB 在前，115200 bps，位宽 8680ns）"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

T = 8680  # 1 bit 时长 (ns)
data = [1, 1, 0, 0, 1, 1, 0, 0]   # 0x33, bit0~bit7, LSB 在前
levels = [0] + data + [1]        # 起始低 + 数据 + 停止高
labels = ["START"] + [f"D{i}({d})" for i, d in enumerate(data)] + ["STOP"]

fig, ax = plt.subplots(figsize=(12, 3.2))
# step 波形
x = [0.0]; y = [levels[0]]
for i, lvl in enumerate(levels):
    x += [i * T, (i + 1) * T]
    y += [lvl, lvl]
x.append((len(levels)) * T); y.append(y[-1])
ax.step(x, y, where="post", color="#1f77b4", lw=2)

# 每个 bit 段底色 + 标签
for i, lvl in enumerate(levels):
    ax.add_patch(Rectangle((i * T, -0.1), T, 1.2, color="#ffd54f" if lvl == 0 else "#c8e6c9", alpha=0.35, zorder=0))
    ax.text(i * T + T / 2, 0.5, f"{labels[i]}\n{'L' if lvl==0 else 'H'}\n{T}ns",
            ha="center", va="center", fontsize=9)
ax.text(len(levels) * T + 200, 0.9, "IDLE(H)", fontsize=9, color="gray")

# 位边界刻度
ticks = [i * T for i in range(len(levels) + 1)]
ax.set_xticks(ticks)
ax.set_xticklabels([f"{t//1000}us" if t % 1000 == 0 else f"{t}ns" for t in ticks], fontsize=8)
ax.set_yticks([0, 1])
ax.set_yticklabels(["0 (L)", "1 (H)"], fontsize=9)
ax.set_ylim(-0.2, 1.4); ax.set_xlim(-400, len(levels) * T + 2000)
ax.set_xlabel("time (ns, 1 bit = 8680ns @ 115200 bps)")
ax.set_title("UART frame: send 0x33 (0b0011_0011, LSB first)  total = 10 bit = 86800ns")
ax.grid(axis="x", ls=":", alpha=0.5)
plt.tight_layout()
plt.savefig(r"D:\ZcodeData\.zcode\workspace\default\day13_uart_frame_0x33.png", dpi=130)
print("saved OK")
