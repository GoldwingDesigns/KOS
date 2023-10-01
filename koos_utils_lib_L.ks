@lazyglobal off.

{
	global UTL is lexicon(
		"slave init", 		    slaveInit@,
		"slave reboot", 		slaveReboot@,
		"has file",		    	hasFile@,
    "has file contains",	hasFileContains@,
    "list file contains",   listFileContains@,
		"delete file",		    deleteFile@,
		"retrieve file",    	retrieveFile@,
    "retrieve file list",   retrieveFileList@,
    "refresh mission files",refreshMissionFiles@,
		"update libfiles",	    updateLibFiles@,
		"update bootfiles",     updateBootFile@,
		"write log",			writeToLog@,
		"write commands", writeCommandsFile@,
		"reboot",			    rebootcpu@,
		"kill program",		killprogram@
	).

	function slaveInit {
		parameter cpu,
				rebootfile,
				slavevol.
		SET VOLUME(slavevol):NAME TO cpu:TAG+"_Disk".
		copypath("Master_Disk:/",cpu:TAG+"_Disk:/").
		slaveReboot(cpu,rebootfile,slavevol).
		return true.
	}

	function slaveReboot {
		parameter cpu,
				rebootfile,
				rebootfilevol.
		cpu:DEACTIVATE().
		if rebootfile:length > 0 {
			if hasfile(rebootfile,rebootfilevol) {
				copypath(rebootfilevol + ":/" + rebootfile,"").
				set cpu:bootfilename to rebootfile. }
		}
		wait 2.
		cpu:ACTIVATE().
		return true.
	}
		
	function hasFile {
		//taken from u/DeOriginale69
		Parameter file_name,
				volume_number,
                folder to "".
        local p is path(volume(volume_number)).
        if folder <> "" set p to p:combine(folder).
        local allfiles to list().
		local filematch to FALSE.
		local tempvol to path().
		if exists(p) {chdir(p).} else {return false.}
		List FILES In allFiles.
		For file In allFiles {
		If file:Name = file_name {
				Set filematch to True.
                chdir(tempvol).
                return filematch.
				} 
			}
		chdir(tempvol).
		Return filematch.
	} 

    function hasFileContains {
		//taken from u/DeOriginale69
		Parameter file_name,
				volume_number,
                folder to "".
        local p is path(volume(volume_number)).
        if folder <> "" set p to p:combine(folder).
        local allfiles to list().
		local filematch to FALSE.
		local tempvol to path().
		if exists(p) {chdir(p).} else {return false.}
		List FILES In allFiles.
		For file In allFiles {
		If file:Name:contains(file_name) {
				Set filematch to True.
                chdir(tempvol).
                return filematch.
				} 
			}
		chdir(tempvol).
		Return filematch.
	} 
    function listFileContains {
		//taken from u/DeOriginale69
		Parameter file_name,
				volume_number,
                folder to "".
        local p is path(volume(volume_number)).
        if folder <> "" set p to p:combine(folder).
        local filelist to list().
        local allfiles to list().
        local tempvol to path().
		if exists(p) {chdir(p).} else {return filelist.}
		List FILES In allFiles.
		For file In allFiles {
		If file:Name:contains(file_name) {
				filelist:add(file:Name).
				} 
			}
		chdir(tempvol).
		Return filelist.
	} 

	function deleteFile {
		Parameter file_name,
				volume_number,
                folder to "".
        local p is path(volume(volume_number)).
        if folder <> "" set p to p:combine(folder).
		if hasFile(file_name,volume_number,folder) deletepath(p:combine(file_name)). 
		return true.
	}

	function retrieveFile {
		Parameter file_name,
				from_volume_number to 0,
                from_folder to "",
                to_volume_number to 1,
                to_folder to "".
        local pfrom is path(volume(from_volume_number)).
        if from_folder <> "" set pfrom to pfrom:combine(from_folder).
        local pto is path(volume(to_volume_number)).
        if to_folder <> "" set pto to pto:combine(to_folder).
		if hasFile(file_name,from_volume_number,from_folder) { copypath(pfrom:combine(file_name),pto:combine(file_name)). } else {print(file_name+" not found.").}
		return true.
	}

    function retrieveFileList {
        Parameter file_list,
				from_volume_number to 0,
                from_folder to "",
                to_volume_number to 1,
                to_folder to "".
        local pfrom is path(volume(from_volume_number)).
        if from_folder <> "" set pfrom to pfrom:combine(from_folder).
        local pto is path(volume(to_volume_number)).
        if to_folder <> "" set pto to pto:combine(to_folder).
        for file_name in file_list {
		    if hasFile(file_name,from_volume_number,from_folder) {
          //copypath(pfrom:combine(file_name),pto:combine(file_name)).
          compile pfrom:combine(file_name) to pto:combine(file_name).
        } else {
          print(file_name+" not found.").
        }
        }
		return true.
    }

    function refreshMissionFiles {
        parameter from_volume_number to 0,
                from_folder to "missions/"+ship:name,
                to_volume_number to BOOTVOLUME,
                to_folder to "missions".
        local pfrom is path(volume(from_volume_number)):combine(from_folder).
        local pto is path(volume(to_volume_number)):combine(to_folder).
        if exists(pto) deletepath(pto).
        if exists(pfrom) {
            retrieveFileList(listFileContains("mission",from_volume_number,from_folder),from_volume_number,from_folder,to_volume_number,to_folder).
        }
        return true.
    }

    

	function updateLibFiles {
		IF HOMECONNECTION:ISCONNECTED{
			FOR f in LIBFILES {
				copypath("0:/"+f,+DATAVOLUME+"1:").
			}
				UI["msg add"]("Library Files Updated.").
		} ELSE {
			UI["msg add"]("Ship not connected to Kerbin.").
		}
		return true.
	}

	// function reloadLibFiles {
	// 	UI["msg add"]("Lib Files Reloaded.").
	// 	return true.
	// }

	function updateBootFile {
		IF HOMECONNECTION:ISCONNECTED{
			FOR f in LIBFILES {
				copypath("0:/"+f,BOOTVOLUME+":").
			}
			UI["msg add"]("Boot Files Updated.").
		} ELSE {
		UI["msg add"]("Ship not connected to Kerbin.").
		}
		return true.
	}

	function writeToLog {
		parameter txt.
		local fname to ship:name+"_log.txt".
		local foldername to "0:/missions/"+ship:name+"/".
		log txt to fname. //stores locally
		if homeConnection:isconnected {
			if not exists(foldername) createdir(foldername).
			if exists(foldername+fname) deletePath(foldername+fname).
			copyPath(fname,foldername).
		}
	}

	function writeCommandsFile {
		parameter verbLex is lexicon(), nounLex is lexicon(), missionIndex is -1, maneuverIndex is -1, vesselActionIndex is -1, vesselVarIndex is -1.
		local fname to ship:name+"_commands.txt".
		local foldername to "0:/missions/"+ship:name+"/".
		if exists(fname) deletePath(fname).
		local verbKeys to verbLex:keys.
		log("VERBS"+CHAR(10)+"--------") to fname.
		for k in verbKeys {
			log(CHAR(9) + key_to_str(toOctal(k)) + CHAR(9)  + verbLex[k]) to fname.
		}
		local nounKeys to nounLex:keys.
		log("NOUNS"+CHAR(10)+"--------") to fname.
		for k in nounKeys {
			if k=missionIndex {log(CHAR(9) + "Missions"+CHAR(10)+CHAR(9) +"-------") to fname.}
			if k=maneuverIndex {log(CHAR(9) + "Maneuvers"+CHAR(10)+CHAR(9) +"-------") to fname.}
			if k=vesselActionIndex {log(CHAR(9) + "Actions"+CHAR(10)+CHAR(9) +"-------") to fname.}
			if k=vesselVarIndex {log(CHAR(9) + "Status"+CHAR(10)+CHAR(9) +"-------") to fname.}
			log(CHAR(9) + key_to_str(toOctal(k)) + CHAR(9)  + nounLex[k]) to fname.
		}
		if homeConnection:isconnected {
			if not exists(foldername) createdir(foldername).
			if exists(foldername+fname) deletePath(foldername+fname).
			copyPath(fname,foldername).
		}
	}
	function key_to_str{
        parameter str.
        local s to "00"+str:tostring.
        return s:substring(s:length-2,2).
  }
	function toOctal {
	parameter decimal.	
  local octal is "".
  until (decimal = 0) {
    set octal to MOD(decimal,8):tostring + octal.
    set decimal to FLOOR(decimal/8).

  }
  return octal.
}

	function rebootcpu {
		reboot.
	}
	function killprogram {
		UI["msg add"]("Program Killed at User Request.").
		print 1/0.
	}
}
