###################################################################

# Created by write_sdc on Tue Jun 28 15:58:57 2022

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_max_area 0
create_clock [get_ports clk]  -period 0.5  -waveform {0 0.25}
set_input_delay -clock clk  0  [get_ports clk]
set_input_delay -clock clk  0  [get_ports rst_n]
set_input_delay -clock clk  0  [get_ports {a[3]}]
set_input_delay -clock clk  0  [get_ports {a[2]}]
set_input_delay -clock clk  0  [get_ports {a[1]}]
set_input_delay -clock clk  0  [get_ports {a[0]}]
set_input_delay -clock clk  0  [get_ports {b[3]}]
set_input_delay -clock clk  0  [get_ports {b[2]}]
set_input_delay -clock clk  0  [get_ports {b[1]}]
set_input_delay -clock clk  0  [get_ports {b[0]}]
set_output_delay -clock clk  0  [get_ports {c[4]}]
set_output_delay -clock clk  0  [get_ports {c[3]}]
set_output_delay -clock clk  0  [get_ports {c[2]}]
set_output_delay -clock clk  0  [get_ports {c[1]}]
set_output_delay -clock clk  0  [get_ports {c[0]}]
set_input_transition -max 0.1  [get_ports clk]
set_input_transition -min 0.1  [get_ports clk]
set_input_transition -max 0.1  [get_ports rst_n]
set_input_transition -min 0.1  [get_ports rst_n]
set_input_transition -max 0.1  [get_ports {a[3]}]
set_input_transition -min 0.1  [get_ports {a[3]}]
set_input_transition -max 0.1  [get_ports {a[2]}]
set_input_transition -min 0.1  [get_ports {a[2]}]
set_input_transition -max 0.1  [get_ports {a[1]}]
set_input_transition -min 0.1  [get_ports {a[1]}]
set_input_transition -max 0.1  [get_ports {a[0]}]
set_input_transition -min 0.1  [get_ports {a[0]}]
set_input_transition -max 0.1  [get_ports {b[3]}]
set_input_transition -min 0.1  [get_ports {b[3]}]
set_input_transition -max 0.1  [get_ports {b[2]}]
set_input_transition -min 0.1  [get_ports {b[2]}]
set_input_transition -max 0.1  [get_ports {b[1]}]
set_input_transition -min 0.1  [get_ports {b[1]}]
set_input_transition -max 0.1  [get_ports {b[0]}]
set_input_transition -min 0.1  [get_ports {b[0]}]
