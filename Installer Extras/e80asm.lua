-- E80 Assembler-GHDL-GTKWave one-click script
-- Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
-- Runs the assembler, points to errors (if any), prepares the VHDL firmware
-- file and and runs the GHDL batch.

local welcome_msg_shown = false
function OnOpen(file)
	if welcome_msg_shown then return end
    print ("********************************************************")
    print (" Press F5 to assemble & simulate your .e80asm program.  ")
    print ("                     !!! IMPORTANT !!!                  ")
    print ("The editor will NOT be responsive while GTKWave is open.")
    print ("********************************************************")
	welcome_msg_shown = true
end

function E80Toolchain()
    local temp_src = 'e80asm.' .. os.time() .. '.tmp'
    local firmware_vhd = 'VHDL\\Firmware.vhd'
    local write_error = 'Error: Cannot write file '
    -- e80asm outputs VHDL code to stdout and logs to stderr. Lua does not read
    -- stderr, so we redirect stderr to stdout (via 2>&1) and split them by the
    -- ending string of the VHDL output.
    local e80asm_cmd = 'e80asm.exe /Q < ' .. temp_src .. ' 2>&1'
    local vhdl_end = '\nOTHERS => "UUUUUUUU");END;'
    local e80_error = 'Error in line (%d+)'
    local e80_error_block = '(%*+[%s%S]-%*+)'
    local ghdl_cmd = 'cmd /c g VHDL computer_tb 100ns 2>&1'
	-- clear logs
	scite.MenuCommand(IDM_CLEAROUTPUT)
    -- copy the text from the editor to a temporary file
    local f = io.open(temp_src, "w")
    if not f then print(write_error .. temp_src) return end
    f:write((editor:GetText())) -- double parentheses to keep text without size
    f:close()
    -- run the assembler and keep its combined output in cmd_out
    local handle = io.popen(e80asm_cmd)
    local cmd_out = handle:read("*a")
    handle:close()
    os.remove(temp_src)
    -- find the end of VHDL
    local discard, end_idx = string.find(cmd_out, vhdl_end, 1, true)
    if not end_idx then -- no VHDL code was generated, cmd_out is logs only
		print(string.match(cmd_out, e80_error_block))
		local error_line = string.match(cmd_out, e80_error)
		if not error_line then return end
		-- go to the error line in the editor
		editor:GotoLine(tonumber(error_line) - 1)
		editor:VerticalCentreCaret()
		return
	end
	-- no error, print logs and write Firmware.vhd
	print(string.sub(cmd_out, end_idx+1)) -- logs after VHDL
    f = io.open(firmware_vhd, "w")
    if not f then print(write_error .. firmware_vhd) return end
    f:write(string.sub(cmd_out, 1, end_idx)) -- VHDL before logs
    f:close()
    -- run g.bat with the E80 Computer testbench to start GHDL & GTKWave
    -- again ensure that stderr will be passed to SciTE's output pane (2>&1)
    handle = io.popen(ghdl_cmd)
    cmd_out = handle:read("*a")
    handle:close()
    print(cmd_out)
end