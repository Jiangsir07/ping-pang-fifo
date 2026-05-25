# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DDR3 乒乓缓冲（Ping-Pong Buffer）FPGA 设计，基于 Xilinx 7-series + Vivado + Verilog。使用两片 DDR3 内存交替读写，实现无间断的数据流处理。

## Architecture

```
din → [Top: ddr_pingpang.v]
       ├─ wr_flag=0: write → DDR3_0, read ← DDR3_1
       └─ wr_flag=1: write → DDR3_1, read ← DDR3_0
                                    ↓
                              output FIFO → dout
```

- **`ddr_pingpang.v`** — 顶层模块，乒乓调度 + 输入输出流控。`wr_flag_0` 控制写/读方向切换，每次写完 `addr_size`（512K words）后翻转。
- **`fifo_ddr_0.v`** — 单通道 DDR3 封装（`mig_7series_0`，起始地址 `0x0000_0000`）。读写路径各有一个异步 FIFO（写 FIFO 16-deep，读 FIFO 1024-deep），`rd_flag` 状态机在写/读阶段之间切换。
- **`fifo_ddr_1.v`** — 与 `fifo_ddr_0.v` 结构相同，使用 `mig_7series_1`，默认起始地址 `0xFFFF_FFFF`。

### 时钟域

| 时钟 | 用途 |
|------|------|
| `clk` | 用户逻辑主时钟 |
| `clk_ddr3_0` / `clk_ddr3_1` | MIG UI 时钟（由 MIG 输出） |

跨时钟域处理：
- 数据路径：异步 FIFO（`fifo_async_16x32` / `fifo_async_1024x32`）
- 单 bit 标志：`data_cross` 模块
- 复位同步：`reset_cross` 模块

### 数据位宽

- 用户数据：32-bit
- MIG app 接口：64-bit（写数据低 32-bit 填 0）

## External Dependencies (不在本仓库中)

这些是 Vivado IP 或外部模块，编译时需确保已在工程中添加：

| 模块 | 类型 | 说明 |
|------|------|------|
| `mig_7series_0` / `mig_7series_1` | Xilinx MIG IP | DDR3 控制器 + PHY |
| `fifo_async_16x32` | FIFO IP/模块 | 16-deep 异步 FIFO |
| `fifo_async_1024x32` | FIFO IP/模块 | 1024-deep 异步 FIFO |
| `data_cross` | 自定义模块 | 单 bit 跨时钟域 |
| `reset_cross` | 自定义模块 | 复位跨时钟域 |
| `ila_ddr3_pingpang` / `ila_fifo_ddr` | Vivado ILA IP | 片上逻辑分析仪 |

## Naming Convention

文件命名与实际 module 名不一致（历史原因）：
- `fifo_ddr_0.v` 中的 module 名是 `fifo_ddr_0`
- `fifo_ddr_1.v` 中的 module 名是 `fifo_ddr_1`
- `ddr_pingpang.v` 中的 module 名是 `ddr3_pingpang_1`
