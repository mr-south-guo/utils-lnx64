#!/usr/bin/env python3

# Ref: https://askubuntu.com/a/598038
# > The script needs wmctrl to be installed:
# > `sudo apt-get install wmctrl`

# TODO: Every swap will cause windows to move down a little.

import subprocess
import sys

def get(cmd):
    return subprocess.check_output(["/bin/bash", "-c",  cmd]).decode("utf-8")

def get_shiftright(xr_output):
    lines = [l for l in xr_output.splitlines() if "+0+0" in l][0].split()
    return int([it for it in lines if "x" in it][0].split("x")[0])

def get_shiftleft(xr_output):
    lines = [l for l in xr_output.splitlines() if  "+0" in l and not "+0+0" in l][0].split()
    return -int([it for it in lines if "x" in it][0].split("x")[0])

def swap_windows():
    xr_output = get("xrandr")
    shift_r = get_shiftright(xr_output)
    shift_l = get_shiftleft(xr_output)
    w_data = [l.split() for l in get("wmctrl -lG").splitlines()]
    for w in w_data:
        props = get("xprop -id "+w[0])
        if any(["_TYPE_NORMAL" in props, "TYPE_DIALOG" in props]):    
            if 0 < int(w[2]) < shift_r:
                shift = shift_r
            elif shift_r-shift_l > int(w[2]) >= shift_r:
                shift = -shift_r
            else:
                shift = 0
#            command = "wmctrl -ir "+w[0]+" -e 0,"+(",").join([str(int(w[2])+shift), str(int(w[3])-28), w[4], w[5]])
            command = "wmctrl -ir "+w[0]+" -e 0,"+(",").join([str(int(w[2])+shift-2), str(int(w[3])-56), w[4], w[5]])
            subprocess.Popen(["/bin/bash", "-c", command])     

swap_windows()
