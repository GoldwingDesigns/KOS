//@lazyglobal off.
{
	local opsLex to lex(
		"aobt", list("koos_mnv_aobt_lex"),
		"core", list("koos_mnv_core_lex"),
		"dock", list("koos_mnv_dock_lex"),
		"land", list("koos_mnv_land_lex"),
		"lnch", list("koos_mnv_lnch_lex"),
		"mret", list("koos_mnv_mret_lex"),
		"mxfr", list("koos_mnv_mxfr_lex"),
		"rdvz", list("koos_mnv_rdvz_lex"),
		"rtry", list("koos_mnv_rtry_lex")
	).
	
	local opsLib to lex(
		"aobt", list("koos_obtcalc_lib"),
		"core", list("koos_obtcalc_lib","koos_mnv_lib"),
		"dock", list("koos_pathfinding_lib", "lib_enum"),
		"land", list("koos_obtcalc_lib","koos_mnv_lib"),
		"lnch", list("lib_LAZcalc","koos_mnv_lib"),
		"mret", list("koos_mnv_lib","koos_hillclimb_lib","lib_LAZcalc"),
		"mxfr", list("koos_hillclimb_lib"),
		"rdvz", list("koos_hillclimb_lib","koos_mnv_lib", "koos_obtcalc_lib"),
		"rtry", list()
	).
	
	global UTL is lexicon(
		"has file",		    	hasFile@,
    "has file contains",	hasFileContains@,
    "list file contains",   listFileContains@,
		"delete file",		    deleteFile@,
		"delete files",		    deleteFiles@,
		"retrieve file",    	retrieveFile@,
    "retrieve file list",   retrieveFileList@,
    "refresh mission files",refreshMissionFiles@,
    "refresh config files",refreshConfigFiles@,
		"build MNV lex", buildMNVLex@,
		"update lexfiles",	updateLexFiles@,
		"update libfiles",	updateLibFiles@,
		"update bootfiles", updateBootFile@,
		"write log",			writeToLog@,
		"write commands", writeCommandsFile@,
		"read config", readCfgFile@,
		"reboot",			    rebootcpu@,
		"kill program",		killprogram@
	).

	function hasFile {
		//taken from u/DeOriginale69 
		Parameter file_name,volume_number,folder to " ".
		local p is path(volume(volume_number)).
		if folder <> " " set p to p:combine(folder).
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
		Parameter file_name,volume_number,folder to " ".
		local p is path(volume(volume_number)).
		if folder <> " " set p to p:combine(folder).
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
		Parameter file_name,volume_number,folder to " ".
		local p is path(volume(volume_number)).
		if folder <> " " set p to p:combine(folder).
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
		Parameter file_name,volume_number,folder to " ".
    local p is path(volume(volume_number)).
    if folder <> " " set p to p:combine(folder).
		if hasFile(file_name,volume_number,folder) deletepath(p:combine(file_name)). 
		return true.
	}

	function deleteFiles {
		parameter volume_number,folder to " ",fNameMatches to "".
		local p is path(volume(volume_number)).
		if folder <> " " set p to p:combine(folder).
		local tempvol to path().
		if exists(p) {chdir(p).} else {return false.}
		local fList is list().
		list files in fList.
		for f in fList {
			if f:name:contains(fNameMatches) deletepath(p:combine(f:name)).
		}
		chdir(tempvol).
		return true.
	}

	function retrieveFile {
		Parameter file_name,from_volume_number to 0,from_folder to " ",to_volume_number to 1,to_folder to " ".
		local pfrom is path(volume(from_volume_number)).
		if from_folder <> " " set pfrom to pfrom:combine(from_folder).
		local pto is path(volume(to_volume_number)).
		if to_folder <> " " set pto to pto:combine(to_folder).
		if hasFile(file_name,from_volume_number,from_folder) { copypath(pfrom:combine(file_name),pto:combine(file_name)). } else {print(file_name+" not found.").}
		return true.
	}

  function retrieveFileList {
        Parameter file_list,from_volume_number,from_folder,to_volume_number,to_folder,compileFile to true.
        local pfrom is path(volume(from_volume_number)).
        if from_folder <> "" set pfrom to pfrom:combine(from_folder).
        local pto is path(volume(to_volume_number)).
        if to_folder <> "" set pto to pto:combine(to_folder).
        for file_name in file_list {
		    if hasFile(file_name,from_volume_number,from_folder) {
          //copypath(pfrom:combine(file_name),pto:combine(file_name)).
					if compileFile {compile pfrom:combine(file_name) to pto:combine(file_name).}
					else copypath(pfrom:combine(file_name),pto:combine(file_name)).
        } else {
          print(file_name+" not found.").
        }
        }
		return true.
  }

  function refreshSpecificFiles {
		parameter keyword, from_volume_number, from_folder, to_volume_number, to_folder, compileFile.
		local pfrom is path(volume(from_volume_number)):combine(from_folder).
		local pto is path(volume(to_volume_number)):combine(to_folder).
		if exists(pto) and to_folder <> "" deletepath(pto).
		if exists(pfrom) {
			retrieveFileList(listFileContains(keyword,from_volume_number,from_folder),from_volume_number,from_folder,to_volume_number,to_folder,compileFile).
		}
		return true.
  }

  function refreshMissionFiles {
		refreshSpecificFiles("mission",0,"missions/"+CORE:ELEMENT:name,BOOTVOLUME,"missions",false).
		return true.
	}

	function refreshConfigFiles {
		refreshSpecificFiles(".cfg",0,"missions/"+CORE:ELEMENT:name,BOOTVOLUME,"",false).
		return true.
	}

	function buildMNVLex {
		parameter opsList to list().
		local libList to list().
		local lexList to list().
		MNV:clear().
		set LIBFILES to BOOTLIBFILES:COPY.
		set LEXFILES to BOOTLEXFILES:COPY.
		if opsList[0] = "all" set opsList to opsLib:keys().
		for o in opsList {
			for lb in opsLib[o] {
				if not LIBFILES:contains(lb) LIBFILES:add(lb).
			}
			for lx in opsLex[o] {
				if not LEXFILES:contains(lx) {LEXFILES:add(lx). lexList:add(lx).}
			}
		}
		UTL["delete files"](DATAVOLUME,"lib").
		UTL["delete files"](DATAVOLUME,"lex","mnv").
		updateLibFiles().
		updateLexFiles().
		for f in LIBFILES {
			runpath(DATAVOLUME+":/lib/"+f).
		}
		for f in lexlist {
			runpath(DATAVOLUME+":/lex/"+f).
			local tmpkeys to MNV_TMP:keys.
			for k in tmpkeys {
				if not MNV:hasKey(k) MNV:add(k,MNV_TMP[k]).
			}
		}
		MNV_TMP:clear().
		return true.
	}

	function updateLibFiles {
		IF HOMECONNECTION:ISCONNECTED{
			FOR f in LIBFILES {
				// compile "0:/"+"lib/"+f to DATAVOLUME+":/"+"lib/"+f.
        copypath("0:/lib/"+f+".ks",DATAVOLUME+":/lib/"+f+".ks").

			}
				UI["msg add"]("Library Files Updated.").
		} ELSE {
			UI["msg add"]("Ship not connected to Kerbin.").
		}
		return true.
	}

	function updateLexFiles {
		IF HOMECONNECTION:ISCONNECTED{
			FOR f in LEXFILES {
				// compile "0:/"+"lex/"+f to DATAVOLUME+":/"+"lex/"+f.
        copypath("0:/lex/"+f+".ks",DATAVOLUME+":/lex/"+f+".ks").
			}
				UI["msg add"]("Lexicon Files Updated.").
		} ELSE {
			UI["msg add"]("Ship not connected to Kerbin.").
		}
		return true.
	}

	function updateBootFile {
		IF HOMECONNECTION:ISCONNECTED{
			FOR f in LIBFILES {
				// compile "0:/boot/"+b to BOOTVOLUME+":/boot/"+b.
        copypath("0:/boot/"+b+".ks",BOOTVOLUME+":/boot/"+b+".ks").
			}
			UI["msg add"]("Boot Files Updated.").
		} ELSE {
		UI["msg add"]("Ship not connected to Kerbin.").
		}
		return true.
	}

	function writeToLog {
		parameter txt.
		local fname to core:element:name+"_log.txt".
		local foldername to "0:/missions/"+core:element:name+"/".
		log txt to fname. //stores locally
		if homeConnection:isconnected { //write to archive file and then delete local
			if not exists(foldername) createdir(foldername).
			open(path(foldername+fname)):write(open(fname):readall).
			deletepath(fname).
		}
	}

	function writeCommandsFile {
		parameter verbLex is lexicon(), nounLex is lexicon(), missionIndex is -1, maneuverIndex is -1, vesselActionIndex is -1, vesselVarIndex is -1.
		local fname to core:element:name+"_commands.txt".
		local foldername to "0:/missions/"+core:element:name+"/".
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
	function readCfgFile {
		parameter filename to "ship.cfg".
		if hasFile(filename,1) {
				local cfgLex is Lexicon().
				set cfgLex to parseCfgFile("1:/"+filename).
				return cfgLex.
		} else return lex().
	}
	function parseCfgFile {
    parameter fName.
    local cfgLex to lex().
    local contents to open(fName):readall.
    local currLine to contents:iterator.
    until not currLIne:NEXT{
        local tmpstr to currLine:value.
        local s to tmpstr:split(":").
        if s[1]:tonumber(-999999) <> -999999 cfgLex:add(s[0],s[1]:tonumber).
        else cfgLex:add(s[0],s[1]).
    }
    return cfgLex.
	}
	function rebootcpu {
		reboot.
	}
	function killprogram {
		UI["msg add"]("Program Killed at User Request.").
		print 1/0.
	}
}
