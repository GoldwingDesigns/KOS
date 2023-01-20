//@lazyglobal off.

function utils_slaveInit {
	parameter cpu,
			  rebootfile,
			  slavevol.
	SET VOLUME(slavevol):NAME TO cpu:TAG+"_Disk".
	copypath("Master_Disk:/",cpu:TAG+"_Disk:/").
	utils_slaveReboot(cpu,rebootfile,slavevol).
}
function utils_slaveReboot {
	parameter cpu,
			  rebootfile,
			  rebootfilevol.
	cpu:DEACTIVATE().
	if rebootfile:length > 0 {
		if utils_hasfile(rebootfile,rebootfilevol) {
			copypath(rebootfilevol + ":/" + rebootfile,"").
			set cpu:bootfilename to rebootfile. }
	}
	wait 2.
	cpu:ACTIVATE().
	print("all done").
	return.
}
	
function utils_hasFile {
	//taken from u/DeOriginale69
    Parameter file_name,
			  volume_number.
    local filematch to FALSE.
	local tempvol to VOLUME:NAME.
    Switch to volume_number.
    List FILES In allFiles.
    For file In allFiles {
	If file:Name = file_name {
            Set filematch to True.
            } 
        }
	Switch to tempvol.
    Return filematch.
} 

function utils_deleteFile {
	parameter file_name,
			  volume_number.
}
function utils_updateLibFiles {
	IF HOMECONNECTION:ISCONNECTED{
		FOR f in LIBFILES {
		copypath("0:/"+f,"1:").
	}
	} ELSE {
	gui_msg_add("Ship not connected to Kerbin.").
	}
	gui_msg_update().
}

function utils_reloadLibFiles {
	run koos_utils.
	run lib_gui_func.
	run lib_lazcalc.
	run koos_maneuvers.
	gui_msg_add("Lib Files Reloaded.").
	gui_msg_update().
}

function utils_updateBootFile {
	IF HOMECONNECTION:ISCONNECTED{
		copypath("0:/boot/koos_boot.ks","1:/boot/").
		gui_msg_add("Boot Files Updated.").
	} ELSE {
	gui_msg_add("Ship not connected to Kerbin.").
	}
	gui_msg_update().
}

function utils_reboot {
	CORE:ACTIVATE().
}
