local emu = require "emu"
local assem = require "assem"

assem.assemble_and_write("test.asm", "compiled.bin")
emu.run("compiled.bin")
