# ============================================================
# Vivado Project — 乒乓缓冲 FIFO (Ping-Pong FIFO)
# Target: xc7a50tfgg484-2
# Vivado: 2019.1
# ============================================================

set project_name ping_pong_fifo
set project_dir  [file dirname [file normalize [info script]]]
set vivado_dir   $project_dir/vivado_project

# ── Create project ──
create_project -force $project_name $vivado_dir -part xc7a50tfgg484-2
set_property target_language Verilog [current_project]

# ── Add design (RTL) sources ──
set rtl_dir $project_dir/rtl
add_files -norecurse [list \
    $rtl_dir/sync_fifo.v \
    $rtl_dir/xpm_fifo_wrapper.v \
    $rtl_dir/ping_pong_fifo.v \
]
set_property used_in_synthesis 1 [get_files $rtl_dir/sync_fifo.v]
set_property used_in_synthesis 1 [get_files $rtl_dir/xpm_fifo_wrapper.v]
set_property used_in_synthesis 1 [get_files $rtl_dir/ping_pong_fifo.v]

set_property top ping_pong_fifo [current_fileset]
update_compile_order -fileset sources_1

# ── SYNTHESIS define for XPM FIFO instantiation ──
# When SYNTHESIS is defined, xpm_fifo_wrapper uses xpm_fifo_sync hard IP
# When not defined, behavioral model is used (simulation)
set_property verilog_define {SYNTHESIS} [get_filesets sources_1]

# ── Add simulation sources ──
set tb_dir $project_dir/tb
add_files -fileset sim_1 -norecurse $tb_dir/tb_ping_pong_fifo.v
set_property top tb_ping_pong_fifo [get_filesets sim_1]
update_compile_order -fileset sim_1

# ── Not defining SYNTHESIS for simulation → use behavioral model ──
# (default — no extra define needed for sim)

# ── Save & report ──
puts "\n============================================"
puts " Project:  $project_name"
puts " Device:   xc7a50tfgg484-2"
puts " Location: $vivado_dir"
puts "============================================"
puts " Design sources:"
foreach f [get_files -of_objects [get_filesets sources_1]] {
    puts "   [file tail $f]"
}
puts ""
puts " Simulation sources:"
foreach f [get_files -of_objects [get_filesets sim_1]] {
    puts "   [file tail $f]"
}
puts ""
puts " Top (synthesis)  : ping_pong_fifo"
puts " Top (simulation)  : tb_ping_pong_fifo"
puts "============================================\n"
