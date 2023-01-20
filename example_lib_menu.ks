// This file is distributed under the terms of the MIT license, (c) the KSLib team

GLOBAL MSGQ to QUEUE(). 
GLOBAL STARTTIME to 0.
GLOBAL COMPMODE to 0.
local init_choice.
run lib_gui_func.
run launch.
run circularize.

gui_scr_init().

until false
{
set init_choice to gui_menu_run().
gui_msg_add(init_choice + " program selected.").
if init_choice = "launch" launch().
else if init_choice = "circularize" circularize().
}
