Very Important INFO:
********************
1) This tool just work in Linux platforms with "AMD Radeon™ Software for Linux® Driver" installed
2) Only tested on Debian & Ubuntu Distributions

-------------------------------------------------------------------------------------------------------
|                                       AMDGPU-TOOLS V.1.0 - HELP                                     |
-------------------------------------------------------------------------------------------------------
USAGE:  amdgputools.sh [option] args

EXAMPLE:
        By GPU ID:      amdgputools.sh -g 0 -f 50
        For All GPUs:   amdgputools.sh -f 50

OPTIONS:
        -g|--gpu        set for select the GPU by specific ID [should be combined with the option "-f"]
        -f|--fan-speed  set to specify the speed of the GPU(s) fan(s)
        -i|--info       set for monitoring the GPU(s)
        -h|--help       set for help

INFO:
        1. if you need to combine options "-g" and "-f" you must do it in this respective order.
        2. any other options combination cannot be made.
-------------------------------------------------------------------------------------------------------
