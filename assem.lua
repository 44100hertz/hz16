local ops = require "ops"

local assem = {}

assem.assemble = function (infile, outfile)
  local lexed = assem.lex(infile)
  assem.parse(lexed)
--  local binary = assem.link(lexed)
end

-- turn a file into a list of lines that should be easy to parse
assem.lex = function (infile)
  local token_sig = "[%a_][%w_]*"
  local lexed = {}

  for line in infile:lines() do
    local len = #lexed+1
    lexed[len] = {}

    line = line:gsub(";.*", "")

    -- empty line
    if line:match("^%s*$") then
      goto continue
    end

    -- basic assignment, not considered part of binary
    local lvalue, rvalue = line:match("(" .. token_sig .. ")%s*=%s*([^%s]*)")
    if lvalue then
      lexed[len] = {
        kind = "assignment",
        lvalue = lvalue,
        rvalue = rvalue,
      }
      goto continue
    end

    -- label must be at start of line (no whitespace), colon optional
    -- control flow labels are stored alongside the data
    local label, lend = line:find("^(" .. token_sig .. ")")
    if label then
      lexed[len].label = line:sub(label, lend)
    end

    -- opcode must have whitespace before it
    -- opcode starting with . indicates directive
    local opname, oend = line:find("[.]?%a+", lend and lend+1)
    if opname then
      -- arguments are a list of commas which can include 'quotes'
      lexed[len] = {
        kind = "instruction",
        opname = line:sub(opname, oend):lower()
      }
      local args = {}
      local pos = oend+1
      while true do
        -- quotes get priority over other arguments
        local quote, qend = line:find("%b''", pos)
        local normal, nend = line:find("[^%s,]+", pos)
        if quote then
          args[#args+1] = line:sub(quote, qend)
          pos = qend+1
        elseif normal then
          args[#args+1] = line:sub(normal, nend)
          pos = nend+1
        else
          break
        end
      end
      lexed[len].args = args

--      io.write(lexed[len].opname, " ", table.concat(lexed[len].args, ", "), "\n")
    end
    ::continue::
  end

  return lexed
end

-- The parser just adds a .words = {...} to lexed data
assem.parse = function (lexed)
  local get_amode = function (arg)
    if not arg then
      return 0
    end
    local amode
    local ptr

    -- special arguments seen as registers
    local regs = {
      a = 0,
      b = 1,
      c = 2,
      d = 3,
      pc = 4,
      sp = 5,
    }
    -- for *x "pointer" register syntax
    if arg:sub(1,1) == "*" then
      arg = arg:sub(2)
      ptr = true
    end
    local reg = regs[arg]
    if reg then
      if ptr then
        return reg + 6
      end
      return reg
    end
    -- for regular values (which must be parsed)
    if arg:sub(1,1) == "#" then
      return 0xC, assem.parse_expr(arg:sub(2))
    else
      return 0xD, assem.parse_expr(arg)
    end
  end

  for i, line in ipairs(lexed) do
    if line.kind ~= "instruction" then
      goto continue
    end
    local op = ops.by_name[line.opname]

    if op then
      local amode = 0
      local m1, v1 = get_amode(line.args[1])
      local m2, v2 = get_amode(line.args[2])
      line.words = {op.code * 0x1000 + m1 * 0x10 + m2}
      -- if no values (i.e. registers), nothing is added
      table.insert(line.words, v1)
      table.insert(line.words, v2)
--      print(line.opname, ("%02x"):format(amode))
      for _,v in ipairs(line.words) do io.write(("%04x "):format(v)) end print()
    else
      -- handle directive
    end
    ::continue::
  end
end

assem.parse_expr = function (expr)
  return 0
end

return assem
