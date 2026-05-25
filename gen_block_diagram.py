#!/usr/bin/env python3
"""
DDR3 乒乓缓冲 FPGA 设计 — 信号流框图 SVG。
手绘箭头确保方向正确，正交走线，配色统一，适合导入 Visio。
"""
import math

OUTPUT = r'E:\work_space\Claude_Work\DDR_pingpang\ddr_pingpang_block.svg'

# ═══════════════ 配色 ═══════════════
WR   = '#1565C0'  # 写数据 — 蓝
RD   = '#2E7D32'  # 读数据 — 绿
CTL  = '#E65100'  # 控制 — 橙
XCK  = '#C62828'  # 跨时钟域 — 红
GRAY = '#546E7A'
DARK = '#212121'
LITE = '#616161'

# 模块配色
C_FIFO_BG  = '#F3E5F5'; C_FIFO_S  = '#7B1FA2'
C_MIG_BG   = '#FFEBEE'; C_MIG_S   = '#B71C1C'
C_SDRAM_BG = '#ECEFF1'; C_SDRAM_S = '#546E7A'
C_LOG_BG   = '#FFFDE7'; C_LOG_S   = '#F9A825'
C_MUX_BG   = '#FCE4EC'; C_MUX_S   = '#AD1457'

# ═══════════════ SVG 缓冲 ═══════════════
LINES = []
def L(s): LINES.append(s)

# ═══════════════ 绘制原语 ═══════════════
def rect(x, y, w, h, fill, stroke, sw='1.5', rx=5):
    L(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
      f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}" rx="{rx}"/>')

def txt(x, y, s, clr=DARK, sz=11, anc='start', bold=False):
    bw = 'font-weight="bold"' if bold else ''
    L(f'<text x="{x:.1f}" y="{y:.1f}" font-family="Arial,Microsoft YaHei,sans-serif" '
      f'font-size="{sz}" fill="{clr}" text-anchor="{anc}" {bw}>{s}</text>')

def ctxt(x, y, s, clr=DARK, sz=11, bold=False):
    txt(x, y, s, clr=clr, sz=sz, anc='middle', bold=bold)

# 模块框
def module(x, y, w, h, title, lines=None, fill='#FFFDE7', stroke='#F9A825', sw='1.5'):
    rect(x, y, w, h, fill, stroke, sw)
    ctxt(x + w/2, y + h/2 + 4, title, DARK, 12, True)
    if lines:
        for i, ln in enumerate(lines):
            ctxt(x + w/2, y + h/2 + 20 + i*16, ln, LITE, 9)

# ── 手绘箭头（三角形） ──
def arrowhead(tip_x, tip_y, angle_deg, size=8, clr=DARK):
    """在 (tip_x,tip_y) 画一个指向 angle_deg 方向的三角形箭头。
    angle_deg: 0=右, 90=下, 180=左, 270=上"""
    rad = math.radians(angle_deg)
    # 三角形顶点在 tip，底部两点在后方
    base_x = tip_x - size * 1.4 * math.cos(rad)
    base_y = tip_y - size * 1.4 * math.sin(rad)
    # 底部两角（垂直于方向 ± size*0.6）
    perp_x = size * 0.55 * math.sin(rad)
    perp_y = size * 0.55 * math.cos(rad)
    x1 = base_x - perp_x
    y1 = base_y + perp_y
    x2 = base_x + perp_x
    y2 = base_y - perp_y
    L(f'<polygon points="{tip_x:.1f},{tip_y:.1f} {x1:.1f},{y1:.1f} {x2:.1f},{y2:.1f}" fill="{clr}"/>')

# ── 线段 ──
def line(x1, y1, x2, y2, clr=DARK, sw='2', dash=None):
    ds = f' stroke-dasharray="{dash}"' if dash else ''
    L(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{clr}" stroke-width="{sw}"{ds}/>')

# ── 正交走线 + 箭头 ──
def ortho_route(segments, clr=DARK, sw='2', dash=None):
    """
    segments: [(x1,y1), (x2,y2), ...] 直线段序列。
    最后一段末端自动加箭头。
    """
    for i in range(len(segments) - 1):
        x1, y1 = segments[i]
        x2, y2 = segments[i+1]
        is_last = (i == len(segments) - 2)
        if is_last:
            # 最后一段，不加 arrowhead（由调用者用最后一段方向单独画）
            pass
        line(x1, y1, x2, y2, clr, sw, dash)
    # 在最后一段末端画箭头
    x1, y1 = segments[-2]
    x2, y2 = segments[-1]
    dx, dy = x2 - x1, y2 - y1
    angle = math.degrees(math.atan2(dy, dx))
    arrowhead(x2, y2, angle, 7, clr)

def arrow_seg(x1, y1, x2, y2, clr=DARK, sw='2', dash=None):
    """单线段 + 末端箭头"""
    line(x1, y1, x2, y2, clr, sw, dash)
    dx, dy = x2 - x1, y2 - y1
    angle = math.degrees(math.atan2(dy, dx))
    arrowhead(x2, y2, angle, 7, clr)

# ── 快捷路由（常用走线模式） ──
def L_to_R(x1, y1, x2, y2, clr=DARK, sw='2', dash=None, mid_y=None):
    """从左到右: 水平出→垂直→水平入。最后一段水平向右进入目标。"""
    if mid_y is None:
        mid_y = (y1 + y2) / 2
    segs = [(x1, y1), (x1 + 10, y1), (x1 + 10, mid_y), (x2 - 10, mid_y), (x2 - 10, y2), (x2, y2)]
    ortho_route(segs, clr, sw, dash)

def R_to_L(x1, y1, x2, y2, clr=DARK, sw='2', dash=None, mid_y=None):
    """从右到左"""
    if mid_y is None:
        mid_y = (y1 + y2) / 2
    segs = [(x1, y1), (x1 - 10, y1), (x1 - 10, mid_y), (x2 + 10, mid_y), (x2 + 10, y2), (x2, y2)]
    ortho_route(segs, clr, sw, dash)

def down_route(x1, y1, x2, y2, clr=DARK, sw='2', dash=None):
    """从上到下: 垂直为主"""
    mid_x = (x1 + x2) / 2
    segs = [(x1, y1), (x1, y1 + 8), (mid_x, y1 + 8), (mid_x, y2 - 8), (x2, y2 - 8), (x2, y2)]
    ortho_route(segs, clr, sw, dash)

def straight(x1, y1, x2, y2, clr=DARK, sw='2', dash=None):
    """简单直线+箭头"""
    arrow_seg(x1, y1, x2, y2, clr, sw, dash)

# ═══════════════════════════════════════════════════════════
#  布局常量
# ═══════════════════════════════════════════════════════════
# 列坐标（所有模块左边缘 X）
COL0 = 30    # 输入端口 / 写控制
COL1 = 250   # 数据分发 / 输出MUX
COL2 = 500   # FIFO
COL3 = 730   # MIG
COL4 = 1030  # DDR3 颗粒
COL5 = 1260  # 文字说明

# 模块宽度
W_PORT = 160
W_CTRL = 200
W_DIST = 200
W_FIFO = 180
W_MIG  = 270
W_DDR  = 170

# 通道 Y 起始
CH0_Y = 80
CH1_Y = 480
OUT_Y = 880

def build():
    L('<?xml version="1.0" encoding="UTF-8"?>')
    L(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1480 1070" width="1480" height="1070">')

    # ── 标题 ──
    ctxt(740, 26, 'DDR3 乒乓缓冲 FPGA 设计 — 信号流框图', '#0D47A1', 17, True)

    # ── 时钟域背景 ──
    rect(15, 42, 480, 1015, '#E3F2FD', 'none', '0', 0)  # clk 域
    rect(495, 42, 520, 1015, '#FFF8E1', 'none', '0', 0)  # clk_ddr3 域
    line(495, 42, 495, 1055, '#90CAF9', '2', '8,4')
    line(1015, 42, 1015, 1055, '#FFE082', '2', '8,4')

    ctxt(255, 57, 'clk 域（用户逻辑）', '#1565C0', 11, True)
    ctxt(755, 57, 'clk_ddr3_X 域（MIG UI 时钟）', '#E65100', 11, True)
    ctxt(1200, 57, 'DDR3 PHY + 输出路径', GRAY, 11, True)

    # ═══════════════════════════════════════════════════
    #  通道 0
    # ═══════════════════════════════════════════════════
    rect(25, CH0_Y-5, 1460, 395, '#FFF3E0', '#E65100', '2', 6)
    txt(35, CH0_Y+14, '通道 0 — fifo_ddr_0（mig_7series_0, ADDR_INITIAL=0x0000_0000）', '#E65100', 13, 'start', True)

    # clk 域模块
    h0 = CH0_Y + 30  # 模块行起始 Y
    module(COL0, h0, W_PORT, 70, 'din[31:0]', ['din_empty / alempty'], '#E8F5E9', '#2E7D32')
    txt(COL0+W_PORT/2, h0+85, '外部输入', '#666', 9, 'middle')

    h1 = CH0_Y + 125
    module(COL0, h1, W_CTRL, 115, '写控制逻辑',
           ['wr_flag_0, wr_cnt[31:0]',
            'wr_flag_0=1: 写使能→DDR3_0',
            'wr_cnt满addr_size→flag翻转',
            'din_rd_en 受prog_full背压'])

    module(COL1, h1, W_DIST, 115, '输入数据分发',
           ['ddr3_0_din = din  (32-bit)',
            'ddr3_0_din_wr_en',
            '  = din_rd_en & wr_flag_0',
            'din_prog_full → 暂停din_rd_en'],
           '#E8EAF6', '#5C6BC0')

    # clk_ddr3 域模块
    h2 = CH0_Y + 30
    module(COL2, h2, W_FIFO, 75, '写异步 FIFO', ['fifo_async_1024x32',
            'wr_clk=clk | rd_clk=clk_ddr3_0'], C_FIFO_BG, C_FIFO_S)

    h3 = CH0_Y + 135
    module(COL2, h3, W_FIFO, 95, 'rd_flag 状态机',
           ['rd_flag=0: 写阶段',
            'rd_flag=1: 读阶段',
            'addr[31:0] 地址生成',
            'addr满addr_size→翻转'])

    h4 = CH0_Y + 275
    module(COL2, h4, W_FIFO, 85, '读异步 FIFO', ['fifo_async_1024x32',
            'wr_clk=clk_ddr3 | rd_clk=clk',
            'prog_full→app_en_rd暂停'], C_FIFO_BG, C_FIFO_S)

    h5 = CH0_Y + 75
    module(COL3, h5, W_MIG, 305, 'mig_7series_0',
           ['app_wdf_data = {32\'d0,fifo_wr_dout}[63:0]',
            'app_cmd = 000(写) / 001(读)',
            'app_addr = {addr[0+:25],3\'b000}',
            'app_en_wr = ~rd_flag & ~wr_empty & rdy',
            'app_en_rd = rd_flag & ~fifo_rd_prog_full',
            'app_en = app_en_wr | app_en_rd',
            'ddr3_wr_full = rd_flag && fifo_wr_rd_en',
            '  → data_cross → clk 域',
            '',
            '含 reset_cross / data_cross / ILA'],
           C_MIG_BG, C_MIG_S, '2')

    h6 = CH0_Y + 130
    module(COL4, h6, W_DDR, 195, 'DDR3 SDRAM', ['颗粒 #0', '16-bit 数据总线',
            'addr[13:0] / ba[2:0]',
            'CK/CKE/CS/RAS/CAS/WE',
            'DQ/DQS/DM/ODT',
            'sys_clk=200MHz'], C_SDRAM_BG, C_SDRAM_S, '2')

    # ── 通道0 信号连线 ──
    # 1. din端口 → 写控制 (ctl反馈)
    down_route(COL0+W_PORT/2, h0+70, COL0+W_CTRL/4, h1, CTL, '1.5', '5,3')
    txt(COL0+W_PORT/2+8, h0+100, 'din_empty', CTL, 8)

    # 2. din → 数据分发 (数据)
    L_to_R(COL0+W_PORT, h0+35, COL1, h1+30, WR, '2.5')
    txt(COL0+W_PORT+5, h0+55, 'din[31:0]', WR, 9)

    # 3. 写控制 → 数据分发 (ctl)
    L_to_R(COL0+W_CTRL, h1+40, COL1, h1+60, CTL, '1.5', '5,3')
    txt(COL0+W_CTRL+5, h1+55, 'wr_flag_0, din_rd_en', CTL, 8)

    # 4. 数据分发 → 写FIFO (wr data)
    L_to_R(COL1+W_DIST, h1+30, COL2, h2+30, WR, '2.5')
    txt(COL1+W_DIST+5, h1+15, 'ddr3_0_din[31:0]', WR, 9)
    txt(COL1+W_DIST+5, h1+32, 'ddr3_0_din_wr_en', CTL, 8)

    # 5. 写FIFO → MIG (wr data)
    L_to_R(COL2+W_FIFO, h2+35, COL3, h5+60, WR, '2.5')
    txt(COL2+W_FIFO+5, h2+25, 'fifo_wr_dout', WR, 8)
    txt(COL2+W_FIFO+5, h2+40, '→app_wdf_data[63:0]', WR, 8)

    # 6. rd_flag → MIG (ctl)
    L_to_R(COL2+W_FIFO, h3+45, COL3, h5+120, CTL, '1.5', '5,3')
    txt(COL2+W_FIFO+5, h3+55, 'rd_flag, addr[31:0]', CTL, 8)

    # 7. MIG → DDR3 (PHY写)
    L_to_R(COL3+W_MIG, h5+100, COL4, h6+60, XCK, '2', '4,3')
    txt(COL3+W_MIG+5, h5+95, 'PHY总线 (写)', XCK, 8)

    # 8. DDR3 → MIG (PHY读)
    R_to_L(COL4, h6+130, COL3+W_MIG, h5+180, RD, '2')
    txt(COL3+W_MIG-130, h5+195, 'app_rd_data[63:0] (读)', RD, 8)

    # 9. MIG → 读FIFO (rd data)
    R_to_L(COL3+W_MIG/2, h5+305, COL2+W_FIFO, h4+40, RD, '2.5')
    txt(COL2+W_FIFO-160, h4+25, 'app_rd_data[63:0]', RD, 8)
    txt(COL2+W_FIFO-160, h4+42, 'app_rd_data_valid', RD, 8)

    # 10. 读FIFO → 下游 (通向输出MUX)
    down_route(COL2+W_FIFO/2, h4+85, COL2+W_FIFO/4, h4+140, RD, '2.5')

    # 11. din_prog_full 背压 (反向)
    R_to_L(COL2, h2+55, COL1+W_DIST, h1+85, CTL, '1.5', '4,3')
    txt(COL1+W_DIST-140, h1+75, 'din_prog_full（背压）', CTL, 8)

    # 12. wr_flag跨时钟域
    L_to_R(COL0+W_CTRL, h1+80, COL2, h3+15, XCK, '1.8', '4,3')
    txt(COL0+W_CTRL+5, h1+100, 'wr_flag_0 → data_cross → clk_ddr3_0', XCK, 8)

    # 13. ddr3_wr_full 跨时钟域
    R_to_L(COL3, h5+255, COL0+W_CTRL, h1+100, XCK, '1.5', '4,3')

    # ═══════════════════════════════════════════════════
    #  通道 1
    # ═══════════════════════════════════════════════════
    rect(25, CH1_Y-5, 1460, 380, '#E8F5E9', '#2E7D32', '2', 6)
    txt(35, CH1_Y+14, '通道 1 — fifo_ddr_1（mig_7series_1, ADDR_INITIAL=0xFFFF_FFFF，结构与通道0相同）', '#2E7D32', 13, 'start', True)

    ch1_h1 = CH1_Y + 100
    module(COL1, ch1_h1, W_DIST, 110, '输入数据分发',
           ['ddr3_1_din = din',
            'ddr3_1_din_wr_en',
            '  = din_rd_en & wr_flag_1',
            'wr_flag_1 = ~wr_flag_0'],
           '#E8EAF6', '#5C6BC0')

    ch1_h2 = CH1_Y + 30
    module(COL2, ch1_h2, W_FIFO, 75, '写异步 FIFO', ['fifo_async_1024x32',
            'wr_clk=clk | rd_clk=clk_ddr3_1'], C_FIFO_BG, C_FIFO_S)

    ch1_h3 = CH1_Y + 130
    module(COL2, ch1_h3, W_FIFO, 85, 'rd_flag 状态机',
           ['rd_flag=0:写 | 1:读',
            '+ 地址生成',
            'addr满→翻转'])

    ch1_h4 = CH1_Y + 255
    module(COL2, ch1_h4, W_FIFO, 80, '读异步 FIFO', ['fifo_async_1024x32',
            'wr=clk_ddr3_1 | rd=clk',
            'prog_full→暂停'], C_FIFO_BG, C_FIFO_S)

    ch1_h5 = CH1_Y + 65
    module(COL3, ch1_h5, W_MIG, 280, 'mig_7series_1',
           ['app_en_wr = ~rd_flag & ~wr_empty & rdy',
            'app_en_rd = rd_flag & ~rd_prog_full',
            'app_wdf_data = {32\'d0,fifo_wr_dout}',
            'app_addr = {addr[0+:25],3\'b000}',
            'ddr3_wr_full → data_cross → clk域',
            '',
            '含 reset_cross / data_cross / ILA'],
           C_MIG_BG, C_MIG_S, '2')

    ch1_h6 = CH1_Y + 115
    module(COL4, ch1_h6, W_DDR, 175, 'DDR3 SDRAM', ['颗粒 #1', '16-bit 数据总线',
            'CK/CKE/CS/RAS/CAS/WE',
            'DQ/DQS/DM/ODT',
            'sys_clk=200MHz'], C_SDRAM_BG, C_SDRAM_S, '2')

    # ── 通道1 信号连线 ──
    # 数据分发 → 写FIFO
    L_to_R(COL1+W_DIST, ch1_h1+30, COL2, ch1_h2+30, WR, '2.5')
    txt(COL1+W_DIST+5, ch1_h1+15, 'ddr3_1_din[31:0]', WR, 9)
    txt(COL1+W_DIST+5, ch1_h1+32, 'ddr3_1_din_wr_en', CTL, 8)

    # 写FIFO → MIG
    L_to_R(COL2+W_FIFO, ch1_h2+35, COL3, ch1_h5+55, WR, '2.5')
    txt(COL2+W_FIFO+5, ch1_h2+25, 'fifo_wr_dout→MIG', WR, 8)

    # rd_flag → MIG
    L_to_R(COL2+W_FIFO, ch1_h3+40, COL3, ch1_h5+105, CTL, '1.5', '5,3')
    txt(COL2+W_FIFO+5, ch1_h3+50, 'rd_flag, addr', CTL, 8)

    # MIG ↔ DDR3
    L_to_R(COL3+W_MIG, ch1_h5+95, COL4, ch1_h6+55, XCK, '2', '4,3')
    txt(COL3+W_MIG+5, ch1_h5+88, 'PHY总线 (写)', XCK, 8)
    R_to_L(COL4, ch1_h6+115, COL3+W_MIG, ch1_h5+165, RD, '2')
    txt(COL3+W_MIG-130, ch1_h5+180, 'app_rd_data (读)', RD, 8)

    # MIG → 读FIFO
    R_to_L(COL3+W_MIG/2, ch1_h5+280, COL2+W_FIFO, ch1_h4+40, RD, '2.5')
    txt(COL2+W_FIFO-160, ch1_h4+25, 'app_rd_data[63:0]', RD, 8)

    # 读FIFO → 下游
    down_route(COL2+W_FIFO/2, ch1_h4+80, COL2+W_FIFO/4-20, ch1_h4+140, RD, '2.5')

    # 背压
    R_to_L(COL2, ch1_h2+55, COL1+W_DIST, ch1_h1+80, CTL, '1.5', '4,3')
    txt(COL1+W_DIST-140, ch1_h1+70, 'din_prog_full（背压）', CTL, 8)

    # 跨时钟域
    L_to_R(COL0+W_CTRL, h1+95, COL2, ch1_h3+15, XCK, '1.8', '4,3')
    txt(COL0+W_CTRL+5, h1+115, 'wr_flag_1 → data_cross → clk_ddr3_1', XCK, 8)
    R_to_L(COL3, ch1_h5+240, COL0+W_CTRL, h1+110, XCK, '1.5', '4,3')

    # 写控制 → 通道1数据分发
    down_route(COL0+W_CTRL/2, h1+115, COL1+W_DIST/2, ch1_h1, CTL, '1.5', '5,3')
    txt(COL0+W_CTRL/2-110, h1+160, 'wr_flag_1 = ~wr_flag_0', CTL, 8)

    # ═══════════════════════════════════════════════════
    #  输出路径
    # ═══════════════════════════════════════════════════
    rect(25, OUT_Y-5, 1460, 175, '#E8F0FE', '#1565C0', '2', 6)
    txt(35, OUT_Y+14, '输出路径 — 乒乓读侧数据汇聚 + 校验', '#1565C0', 13, 'start', True)

    out_h = OUT_Y + 30
    module(COL0, out_h, W_CTRL, 125, '输出 MUX',
           ['dd3_dout = rd_flag_0 ?',
            '  ddr3_0_dout : ddr3_1_dout',
            'dout_rd_en仅给被选中通道',
            'rd_flag_0读完addr_size→翻转'],
           C_MUX_BG, C_MUX_S)

    module(COL1, out_h, 180, 125, '输出 FIFO',
           ['fifo_async_16x32',
            '缓冲数据, 平滑输出',
            'prog_full→dd3_dout_rd_en停',
            '同频: wr_clk=rd_clk=clk'],
           C_FIFO_BG, C_FIFO_S)

    module(COL1+220, out_h, 190, 125, '读控制逻辑',
           ['rd_flag_0 / rd_cnt[31:0]',
            'rd_cnt满→rd_flag_0翻转',
            'dd3_dout_rd_en流控:',
            'alempty≠0→读, prog_full→停'])

    module(COL2+160, out_h, 130, 125, 'dout[31:0]',
           ['dout_empty',
            'dout_alempty',
            '← 外部dout_rd_en'],
           '#E8F5E9', '#2E7D32')

    module(COL3-30, out_h, 210, 125, 'TB 数据校验',
           ['ddr3_model × 2 (仿真模型)',
            '数据自增序列比对:',
            '  dout == ddr_dout + 1 ?',
            '不匹配 → error=1'],
           '#E1F5FE', '#0277BD')

    # ── 输出路径连线 ──
    # 通道0读FIFO → 输出MUX
    down_route(COL2+W_FIFO/4, h4+140, COL0+W_CTRL/3, out_h, RD, '2.5')
    txt(COL2+W_FIFO/4-90, h4+180, 'ddr3_0_dout[31:0]', RD, 9)
    txt(COL2+W_FIFO/4-90, h4+197, 'dout_empty / alempty', RD, 8)

    # 通道1读FIFO → 输出MUX
    down_route(COL2+W_FIFO/4-20, ch1_h4+140, COL0+W_CTRL*2/3, out_h+90, RD, '2.5')
    txt(COL2+W_FIFO/4-120, ch1_h4+185, 'ddr3_1_dout[31:0]', RD, 9)
    txt(COL2+W_FIFO/4-120, ch1_h4+202, 'dout_empty / alempty', RD, 8)

    # MUX → 输出FIFO
    straight(COL0+W_CTRL, out_h+60, COL1, out_h+60, RD, '2.5')
    txt(COL0+W_CTRL+5, out_h+52, 'dd3_dout[31:0]', RD, 9)

    # 输出FIFO → dout
    straight(COL1+180, out_h+60, COL2+160, out_h+60, RD, '2.5')
    txt(COL1+185, out_h+52, 'fifo_dout', RD, 9)
    txt(COL1+185, out_h+78, 'fifo_rd_en=dout_rd_en', CTL, 8)

    # 读控制 → MUX (rd_flag_0)
    R_to_L(COL1+220+190, out_h+30, COL0+W_CTRL, out_h+40, CTL, '1.5', '5,3')
    txt(COL1+190, out_h+18, 'rd_flag_0（MUX选通）', CTL, 8)

    # 读控制 → 通道 (dout_rd_en分发)
    down_route(COL1+220+90, out_h, COL0+W_CTRL/2, out_h-10, CTL, '1.5', '5,3')
    txt(COL1+220+95, out_h-12, 'ddr3_X_dout_rd_en（仅给选中通道）', CTL, 8)

    # 输出FIFO背压 → 读控制
    R_to_L(COL1, out_h+105, COL1+220, out_h+105, CTL, '1.5', '5,3')
    txt(COL1+20, out_h+120, 'fifo_prog_full（背压）', CTL, 8)

    # ═══════════════════════════════════════════════════
    #  右侧文字说明
    # ═══════════════════════════════════════════════════
    TX = COL5 - 20
    ctxt(TX+80, CH0_Y+40, '乒乓切换时序', '#E65100', 12, True)
    ph = CH0_Y+62
    for s in ['Phase 1: wr_flag_0 = 1',
              '  写 → DDR3_0      读 ← DDR3_1',
              'Phase 2: wr_flag_0 = 0',
              '  写 → DDR3_1      读 ← DDR3_0',
              '翻转: wr_cnt>=addr_size-1 && din_rd_en',
              'rd_flag_0同: rd_cnt>=addr_size-1']:
        txt(TX, ph, s, GRAY if '翻转' not in s else '#E65100', 9)
        ph += 17

    ctxt(TX+80, CH1_Y+30, '跨时钟域处理', XCK, 12, True)
    ph = CH1_Y+52
    for s in ['数据路径: 异步FIFO (clk↔clk_ddr3)',
              '复位: reset_cross',
              '  rst_n(clk) → rst_n_ddr',
              '单bit标志: data_cross',
              '  wr_flag_X → clk_ddr3_X',
              '  ddr3_wr_full → clk',
              '输出FIFO: 同频 clk↔clk']:
        txt(TX, ph, s, GRAY, 9)
        ph += 17

    # 图例
    leg_x = TX; leg_y = OUT_Y + 40
    ctxt(leg_x+80, leg_y, '图例', DARK, 11, True)
    items = [(C_FIFO_BG, C_FIFO_S, '异步FIFO'), (C_MIG_BG, C_MIG_S, 'MIG IP'),
             (C_SDRAM_BG, C_SDRAM_S, 'DDR3 SDRAM'), (C_LOG_BG, C_LOG_S, '控制逻辑'),
             (C_MUX_BG, C_MUX_S, 'MUX/端口'), ('#E3F2FD', '#90CAF9', 'clk域'),
             ('#FFF8E1', '#FFE082', 'clk_ddr3域'),
             (WR, WR, '写数据'), (RD, RD, '读数据'), (CTL, CTL, '控制'), (XCK, XCK, '跨时钟')]
    for i, (bg, st, lb) in enumerate(items):
        col = i % 3; row = i // 3
        rx = leg_x + col*100; ry = leg_y+20+row*22
        rect(rx, ry, 13, 13, bg, st, '1', 3)
        txt(rx+18, ry+11, lb, DARK, 9)

    L('</svg>')

# ═══════════════════════════════════════════════════════════
build()
with open(OUTPUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(LINES))
print(f'OK: {OUTPUT} ({len(LINES)} lines)')
