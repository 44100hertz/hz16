local ops = require "ops"
local lex = require "lex"

local assem = {}

assem.assemble_and_write = function (inpath, outpath)
    local infile = io.input(inpath)
    local program = assem.assemble(infile)
    local bin = assem.link(program, 0)
    assem.write_bin(bin, outpath)
    infile:close()
end

assem.assemble = function (infile)
    local program = lex.tokenize(infile)
    assem.parse(program)
    return program
end

assem.write_bin = function (bin, outpath)
    local outfile = io.open(outpath, "wb")
    for i = 0,#bin do
        local word = bin[i]
        outfile:write(string.char(
                          bit.band(0xff, word),
                          bit.band(0xff, bit.rshift(word, 8))))
    end
    outfile:close()
end

assem.parse = function (lines, defined)
    defined = defined or {}
    for _, line in ipairs(lines) do
        assem.parse_line(line, defined)
--        if line.words then for _, w in ipairs(line.words) do if type(w) == "number" then io.write(("%04x "):format(w)) else io.write(w, " ") end end print() end
    end
end

assem.parse_line = function (line, defined)
    local pos = 1
    -- defining a symbol
    if line[2] == '=' then
        local lvalue = line[pos]
        defined[lvalue] = assem.parse_data_list(line, 3, defined)
        return
    end
    -- if not directive or op, must be label
    if line[pos]:find("[%a_][%w_]*") and not ops.by_name[line[pos]:lower()] then
        line.label = line[pos]
        pos = pos + 1
        -- skip label colon
        if line[pos] == ':' then
            pos = pos + 1
        end
    end
    -- directive
    if line[pos] == "." then
        if line[pos+1]:lower() == "data" then
            pos = pos + 2
            line.words = assem.parse_data_list(line, pos, defined)
        end
        return
    end

    -- operator
    if not line[pos] then
        -- never mind
        return
    end

    local cond
    if line[pos] == "|" then
        cond = true
        pos = pos + 1
    end

    local op = ops.by_name[line[pos]]
    assert(op, ("unknown op: %s"):format(line[pos]))

    local args = assem.split_by_comma(line, pos+1)
    assert(#args <= #op.args, "Too many arguments.")

    local mode0, arg0 = assem.parse_arg(args[1], defined)
    local mode1, arg1 = assem.parse_arg(args[2], defined)

    local op_and_args =
        (cond and 0x0400 or 0x0) +
        bit.lshift(op.code, 11) +
        bit.lshift(mode0, 4) +
        bit.lshift(mode1, 0)

    line.words = {op_and_args}
    line.words[#line.words+1] = arg0
    line.words[#line.words+1] = arg1
end

-- turn a flat array of tokens into an array of token arrays split at commas
-- does not include commas
assem.split_by_comma = function (line, pos)
    if not line[pos] then
        return {}
    end
    local args = {{}}
    local arg = args[1]
    repeat
        if line[pos] == ',' then
            args[#args+1] = {}
            arg = args[#args]
        else
            arg[#arg+1] = line[pos]
        end
        pos = pos + 1
    until not line[pos]
    return args
end

assem.parse_arg = function (arg, defined)
    if not arg then
        return 0x0, nil, pos
    end
    local ptr   = arg[1] == "*"
    local immed = arg[1] == "#"
    local pos = (ptr or immed) and 2 or 1
    local reg_def = {
        a = 0,
        b = 1,
        c = 2,
        d = 3,
        e = 4,
        pc = 5,
        sp = 6,
    }
    local reg_code = reg_def[arg[pos]]
    -- registers default to immediate
    if reg_code then
        local mode = ptr and reg_code+8 or reg_code
        return mode, nil
    end
    assem.simplify(arg, pos, defined)
    assert(#arg - pos == 0, "failed to resolve argument")
    -- numbers default to addresses (pointers).
    -- labels default to immediate.
    if immed or (not ptr and type(arg[pos]) == "string") then
        return 0x7, arg[pos]
    else
        return 0xf, arg[pos]
    end
end

assem.parse_data_list = function (line, pos, defined)
    local args = assem.split_by_comma(line, pos)
    local words = {}
    for _,arg in ipairs(args) do
        -- find values
        assem.simplify(arg, 1, defined)
        -- flatten arguments
        for _,v in ipairs(arg) do
            words[#words+1] = v
        end
    end
    return words
end

assem.simplify = function (expr, pos, defined)
    local pass = function (fn)
        local i = pos
        while expr[i] do
            if type(expr[i]) == "number" then
                i = i + 1
            else
                i = fn(expr, i)
            end
        end
        return i
    end
    local defined_pass = function (expr, pos)
        if expr[pos]:find("^[%a_]") and defined[expr[pos]] then
            local def = defined[expr[pos]]
            table.remove(expr, pos)
            if expr[pos-1] == "len" then
                expr[pos-1] = #def
            else
                for i, v in pairs(def) do
                    table.insert(expr, pos+i-1, v)
                end
            end
        end
        return pos + 1
    end
    local value_pass = function (expr, pos)
        if expr[pos] == "$" then
            -- workaround for https://github.com/LuaJIT/LuaJIT/issues/413
            local sign = 1
            local num_pos = 1
            if expr[pos+1]:find("^-") then
                sign = -1
                num_pos = 2
            end
            local num = tonumber(expr[pos+1]:sub(num_pos), 16)
            assert(num, "Could not parse hex.")
            table.remove(expr, pos)
            expr[pos] = (num * sign) % 0x10000
        elseif expr[pos]:find("^[-%d]") then
            local num = tonumber(expr[pos])
            assert(num, "Could not parse decimal.")
            expr[pos] = num % 0x10000
        end
        return pos + 1
    end
    local quote_pass = function (expr, pos)
        if expr[pos]:find("^['\"]") then
            local esc = assem.unescape_quote(expr[pos]:sub(2, -2))
            local bytes = {esc:byte(1, esc:len())}
            table.remove(expr, pos)
            for _,byte in ipairs(bytes) do
                table.insert(expr, pos, byte)
                pos = pos + 1
            end
        end
        return pos + 1
    end
    pass(defined_pass)
    pass(value_pass)
    pass(quote_pass)
end

assem.unescape_quote = function (quote)
    return quote
        :gsub('\\0', '\0')
        :gsub('\\r', '\r')
        :gsub('\\n', '\n')
        :gsub('\\t', '\t')
        :gsub('\\(.)', '%1')
end

assem.link = function (program, pc)
    -- find program labels
    local labels = {}
    for _,line in ipairs(program) do
        if line.label then
            labels[line.label] = pc
        end
        pc = pc + (line.words and #line.words or 0)
    end

    -- apply program labels and make bin
    pc = 0
    local bin = {}
    for _,line in ipairs(program) do
        if not line.words then
            goto continue
        end
        io.write(("%04x %s %s"):format(
                pc, line.raw_line, (" "):rep(40 - line.raw_line:len())))
        for _,word in ipairs(line.words) do
            if type(word) == "string" then
                assert(labels[word], ("undefined label: %s"):format(word))
                bin[pc] = labels[word]
            else
                bin[pc] = word
            end
            io.write(("%04x "):format(bin[pc]))
            pc = pc + 1
        end
        print()
        ::continue::
    end
    return bin
end

return assem
