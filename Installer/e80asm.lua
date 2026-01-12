-- E80 Assembler-GHDL-GTKWave one-click script
-- Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

local firmware_vhd = 'VHDL\\Firmware.vhd'
local write_error = 'Error: Cannot write file '

-- Help message on editor startup
local welcome_msg_shown = false
function OnOpen(file)
	if welcome_msg_shown then return end
	print ("************ E80 Toolchain Hotkeys ***********")
	print (" F5: Assemble and simulate (GHDL/GTKWave)     ")
	print (" F7: Assemble and inspect VHDL output         ")
	print (" F8: Assemble and simulate (ModelSim)         ")
	print ("**********************************************")
	welcome_msg_shown = true
end

-- Assemble with E80asm and save VHDL output to Firmware.vhd
function Assemble()
	-- Copy the source from the editor to a temp_src file
	local temp_src = 'Assembler\\e80asm.' .. os.time() .. '.tmp'
	local vhdl_end = '\nOTHERS => "UUUUUUUU");END;'
	local e80_error = 'Error in line (%d+)'
	local f = io.open(temp_src, "w")
	if not f then print(write_error .. temp_src) return end
	f:write((editor:GetText())) -- double parentheses to keep text without size
	f:close()

	-- Run the assembler and capture its output
	-- E80asm outputs VHDL code to stdout and logs to stderr. Lua does not read
	-- stderr, so we redirect stderr to stdout (via 2>&1) and split them by the
	-- ending string of the VHDL output.
	local handle = io.popen('cmd /c Assembler\\a.bat /Q < ' .. temp_src .. ' 2>&1')
	local assembler_out = handle:read("*a")
	handle:close()
	assembler_out = assembler_out:gsub("%s+$", "") -- chomp output
	os.remove(temp_src) -- clean temp_src

	-- Find the index between VHDL and logs in the assembler output.
	-- VHDL comes first because 2>&1 places stderr before stdout
	local discard, end_idx = string.find(assembler_out, vhdl_end, 1, true)
	if not end_idx then
		-- no VHDL code was generated, output contains an error message
		print(assembler_out)
		-- find the error line number
		local error_line = string.match(assembler_out, e80_error)
		-- a few messages (eg. template not found) have no error lines
		if error_line then
			-- focus on the error line number in the editor
			editor:GotoLine(tonumber(error_line) - 1)
			editor:VerticalCentreCaret()
		end
		return
	end
	
	-- No error, split VHDL output and informal logs
	local vhdl = string.sub(assembler_out, 1, end_idx)
	local logs = string.sub(assembler_out, end_idx+1)
	print(logs)

	-- Write VHDL output to Firmware.vhd
	f = io.open(firmware_vhd, "w")
	if not f then print(write_error .. firmware_vhd) return end
	f:write(vhdl)
	f:close()
	return 1
end


-- Assemble and simulate with GHDL\GTKWave (F5 on .e80asm)
function Assembler_GHDL_GTKWave()
	scite.MenuCommand(IDM_CLEAROUTPUT) -- clear log pane
	if not Assemble() then return end
	local handle = io.popen('cmd /c GHDL\\g sim 100ns 2>&1')
	local g_bat_output = handle:read("*a")
	handle:close()
	print(g_bat_output)
end

-- Simulate with GHDL\GTKWave (F5 on Firmware.vhd)
function GHDL_GTKWave()
	scite.MenuCommand(IDM_CLEAROUTPUT) -- clear log pane
	scite.MenuCommand(106) -- save first, Firmware.vhd could have been modified
	local handle = io.popen('cmd /c GHDL\\g sim 100ns 2>&1')
	local g_bat_output = handle:read("*a")
	handle:close()
	print(g_bat_output)
end

-- Assemble and inspect VHDL output (F7 on .e80asm)
function Show_VHDL()
	scite.MenuCommand(IDM_CLEAROUTPUT) -- clear log pane
	if not Assemble() then return end
	scite.Open(firmware_vhd)
	scite.MenuCommand(IDM_REVERT) -- reload VHDL in case it was already opened
end

-- Assemble and simulate with ModelSim (F8 on .e80asm)
function Assembler_ModelSim()
	scite.MenuCommand(IDM_CLEAROUTPUT) -- clear log pane
	if not Assemble() then return end
	local handle = io.popen('cmd /c ModelSim\\m 2>&1')
	local m_bat_output = handle:read("*a")
	handle:close()
	print(m_bat_output)
end

-- Simulate with ModelSim (F8 on Firmware.vhd)
function ModelSim()
	scite.MenuCommand(IDM_CLEAROUTPUT) -- clear log pane
	scite.MenuCommand(106) -- save first, Firmware.vhd could have been modified
	local handle = io.popen('cmd /c ModelSim\\m 2>&1')
	local m_bat_output = handle:read("*a")
	handle:close()
	print(m_bat_output)
end