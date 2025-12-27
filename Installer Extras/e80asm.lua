-- E80 Assembler-GHDL-GTKWave one-click script
-- Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
-- Runs the assembler, points to errors (if any), prepares the VHDL firmware
-- file and and runs the GHDL & GTKWave batch.

-- shows a practical help and warning message when the editor is started
local welcome_msg_shown = false
function OnOpen(file)
	if welcome_msg_shown then return end
    print ("************************************************************")
    print (" F7: opens the VHDL output of your .e80asm program in a tab ")
    print (" F5: simulates your .e80asm program with GHDL & GTKWave     ")
    print (" IMPORTANT: You can't use the editor while GTKWave is open  ")
    print ("************************************************************")
	welcome_msg_shown = true
end

-- does everything except running the GHDL & GTKWave batch
function Assemble(vhdl_tab)
    local temp_src = 'e80asm.' .. os.time() .. '.tmp'
    local firmware_vhd = 'VHDL\\Firmware.vhd'
    local write_error = 'Error: Cannot write file '
	-- E80asm outputs VHDL code to stdout and logs to stderr. Lua does not read
    -- stderr, so we redirect stderr to stdout (via 2>&1) and split them by the
    -- ending string of the VHDL output.
    local e80asm_cmd = 'e80asm.exe /Q < ' .. temp_src .. ' 2>&1'
    local vhdl_end = '\nOTHERS => "UUUUUUUU");END;'
    local e80_error = 'Error in line (%d+)'
	-- clear logs
	scite.MenuCommand(IDM_CLEAROUTPUT)
	-- copy the text from the editor to a temporary file
    local f = io.open(temp_src, "w")
    if not f then print(write_error .. temp_src) return end
    f:write((editor:GetText())) -- double parentheses to keep text without size
    f:close()
	-- run the assembler and capture its output
    local handle = io.popen(e80asm_cmd)
    local assembler_out = handle:read("*a")
    handle:close()
	assembler_out = assembler_out:gsub("%s+$", "") -- chomp output
    os.remove(temp_src)

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
	local vhdl = string.sub(assembler_out, 1, end_idx)
	local logs = string.sub(assembler_out, end_idx+1)
	print(logs)
	-- write VHDL to Firmware.vhd
    f = io.open(firmware_vhd, "w")
    if not f then print(write_error .. firmware_vhd) return end
    f:write(vhdl)
    f:close()
    -- if vhdl_tab is set, open Firmware.vhd in a tab
    if vhdl_tab then
		scite.Open(firmware_vhd)
		scite.MenuCommand(IDM_REVERT)
	end
	return 1
end

-- calls Assemble and runs the GHDL & GTKWave batch
function Toolchain()
	if not Assemble() then return end
    local ghdl_cmd = 'g VHDL computer_tb 100ns 2>&1'
    -- run g.bat with the E80 Computer testbench to start GHDL & GTKWave
    -- again ensure that stderr will be passed to SciTE's output pane (2>&1)
    handle = io.popen(ghdl_cmd)
    local g_bat = handle:read("*a")
    handle:close()
    print(g_bat)
end