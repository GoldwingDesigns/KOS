// This file is distributed under the terms of the MIT license, (c) the KSLib team
@lazyglobal off.

local menu_choice to "".
//local restartloop to FALSE.



until false {
	setcompmode().
	set menu_choice to gui_menu_run().
	gui_msg_add(menu_choice + " program selected.").
	if menu_choice = "launch" {
		local lalt is gui_menu_prompt_pos_int("Desired Alt (m):").
		local linc is gui_menu_prompt_float("Desired Inclination:").
		local lcirc is gui_menu_prompt_yn("Circularize?").
		launch(lalt, linc, lcirc).
	}
	else if menu_choice = "circularize" {
		circularize().
	}
	else if menu_choice = "inclination" {
		local linc is gui_menu_prompt_float("Desired Inclination:").
		local llan is gui_menu_prompt_float("Desired LAN (-1 default):").
		set_inc_lan(linc,llan).
	}
	else if menu_choice = "Change Ap" {
		local newalt is gui_menu_prompt_pos_int("Desired Alt (m):").
		change_apo(newalt).
	}
	else if menu_choice = "Change Pe" {
		local newalt is gui_menu_prompt_pos_int("Desired Alt (m):").
		change_per(newalt).
	}
	else if menu_choice = "Capture" {
		local newalt is gui_menu_prompt_pos_int("Desired Alt Opposite Pe:").
		capture_orbit(newalt).
	}
	else if menu_choice = "Hohmann Transfer" {
		local newalt is gui_menu_prompt_pos_int("Desired Alt (m):").
		hohmann_trans(newalt).
	}
	else if menu_choice = "Exec Nxt Node" {
		IF HASNODE {
		IF gui_menu_prompt_yn("Exec Node. Are you sure?") { exec_node(). }
		}
	}
	else if menu_choice = "Target Transfer" {
		local targettypes to list().
		local parentlist to list().
		local moonlist to list().
		local shiplist to list().
		
		if ship:body:HASBODY { targettypes:ADD("Parent"). }
		if ship:body:ORBITINGCHILDREN:LENGTH > 0 {
			targettypes:ADD("Moon").
			for mn in BODY:ORBITINGCHILDREN {
				moonlist:add(mn:NAME).
			}
		}	
		local tmenu is gui_menu_list("Target Type:",targettypes).
		if tmenu = "Parent" {
			local palt is gui_menu_prompt_pos_int("Desired Alt (m):").
			moon_return(palt).
		} else if tmenu = "Moon" {
			local mmenu is gui_menu_list("Available Moons:",moonlist).
			local malt is gui_menu_prompt_pos_int("Desired Alt (m):").
			moon_trans(mmenu,malt).
		}
	}
	else if menu_choice = "Reentry" {
		local r_target is gui_menu_prompt_yn("Land at Island Airfield?").	
		reentry(r_target).
	}
	else if menu_choice = "Utilities" {
		local util_choice is gui_menu_list("Select",list("Update Libraries","Update Boot File","Reboot","Back")).
		if util_choice = "Update Libraries" { 
			utils_updateLibFiles(). 
			IF gui_menu_prompt_yn("Reboot CPU?") { utils_reboot(). }
		} ELSE IF util_choice = "Update Boot File" { 
			utils_updateBootFile(). 
			IF gui_menu_prompt_yn("Reboot CPU?") { utils_reboot(). }
		}
		ELSE IF util_choice = "Reboot" {  
			IF gui_menu_prompt_yn("Reboot. Are you sure?") { utils_reboot(). }
		}
	}
	
}
//IF restartloop { run koos_loop. }

