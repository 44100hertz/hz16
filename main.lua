local emu = require "emu"
local assem = require "assem"

assem.assemble_and_write(io.open("test.asm", "r"), io.open("compiled.bin", "wb"))
--emu.run(io.open("compiled.bin", "rb"))
