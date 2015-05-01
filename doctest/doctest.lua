local g = _G -- store environment
--[=[= 
doctest.lua - I missed it from python, so I ported it to lua -- Andre Bogus
usage: lua doctest.lua - module1.lua [module2.lua ...]
or you can use the doctest method (see below).

To make doctest regard a comment, delimit it like this comment. Then you can
simply paste a lua-interpreter session into the comment to have it tested.
This way, you can regression-test your code *and* documentation. You might
even want to test against the version as a reminder to update the docs, too.

> =doctest.VERSION
0.0.1

You can easily interleave tests and comments, but beware that test results may
not include multiple newlines. You can work around that by substituting 
newlines with \n:

> ="1\n\n2"
1\n\n2

Doctest will match with ellipsis (see the matches-function below), so you can
use it even when you are not fully sure about the example. The following 
example shows the matching with ellipsis as well as the usual method of 
handling errors.

> error("This should fail")
...This should fail

The three usual methods of giving output to the console (error, print, 
io.write) are plugged into doctest, so if you generate output another way (say,
by calling os.exec, you are out of luck - doctest will not pipe stdout.

Multiline code is also accepted. 

> x = 1
> =x
1

The context of all code snippets stays the same, so having added a variable
means we can use it later:

> =x
1
=]=]
doctest = module("doctest")


VERSION = "0.0.1"

log = g.print -- uncomment to enable logging
--log = function() end -- uncomment to disable logging

comment_start = "--[=[="
comment_end = "=]=]"

--[=[=
requote quotes a regular expression against pattern syntax, so that
x:find(requote(y)) == x:find(y, 1, true) for all x and y

> =doctest.requote("^$()%.[]*+-?")
%^%$%(%)%%%.%[%]%*%+%-%?
> =doctest.requote("nothing to do")
nothing to do
> =doctest.requote("1-2=-1")
1%-2=%-1

Oh, and the context for execution is still the same:

> =x
1
=]=]
function requote(p)
	return g.unpack({p:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")}, 1, 1)
end

--[=[=
Creates a string representation of a given string that, in lua code would
recreate the given string.
> =doctest.stringify("abc")
"abc"
> =doctest.stringify("a\tb\rc\nd")
"a\tb\rc\nd"
=]=]
function stringify(s)
	local t = g.type(s)
	if t ~= "string" then return t..":"..g.tostring(s) end
	return '"'..s:gsub("[\t\r\n\"]", 
		{["\t"]="\\t", ["\r"]="\\r", ["\n"]="\\n", ['"']='\\"'})..'"'
end

--[=[=
> =doctest.matches(",", ",")
true
> =doctest.matches("abc", "abcd")
false
> =doctest.matches("abcd", "abc")
false
> =doctest.matches("123456789", "1...9")
true
> =doctest.matches("1234567890", "1...9")
false
> =doctest.matches("12345", "1...")
true
> =doctest.matches("abcde...opq...wxyz", "a...o...z")
true
=]=]
function matches(x, y)
	local x = x:gsub("\\[rtn]", {["\\r"]="\r", ["\\t"]="\t", ["\\n"]="\n"})
	local y = y:gsub("\\[rtn]", {["\\r"]="\r", ["\\t"]="\t", ["\\n"]="\n"})
	local pos, endpos = y:find("...", 0, true)
	if pos == nil then return x == y end
	local pat = g.string.format("^%s$", requote(y):gsub("%%%.%%%.%%%.", ".-"))
	return x:match(pat) ~= nil
end

-- test a single code/result snippet. This gets exercised enough, so no doctest needed.
function doctestSnippet(descr, code, result)
		local output = ""
		local expect = (result or ""):match("%s*(.*)")
		local chunk, err = g.loadstring(code)
		if g.type(chunk) == "function" then
			local _print = g.print
			local _write = g.io.write
			function mkout(sep, suf)
				return function(...)
					local r = {}
					for k, v in g.pairs({...}) do r[k] = g.tostring(v) end
					output = output .. g.table.concat(r, sep)..(suf or "")
				end
			end
			g.print, g.io.write = mkout("\t", "\n"), mkout()
			local rettab = {}
			local xrettab = {g.pcall(chunk)}
			g.print = _print
			g.io.write = _write
			if xrettab[1] then 
				for xretpos, retval in g.ipairs(xrettab) do 
					if retval == nil then retval = "" end
					if xretpos > 1 then 
						rettab[xretpos - 1] = g.tostring(retval)
					end
				end
			else
				rettab[1] = g.tostring(xrettab[2])
			end
			local ret = g.table.concat(rettab, "\t")
			if ret == nil then ret = "" else ret = ret.."\n" end
			output = (output..ret):match("^(.-)[\r\n]*$")
			expect = expect:match("^(.-)[\r\n]*$")
			if matches(output, expect) then
				log(descr, "ok")
				return true
			else
				g.print(g.string.format("error in test %s expected %s, got %s",
					descr, stringify(expect), stringify(output)))
				return false
			end
		else
			g.print("syntax error in test", descr, err)
			g.print(code)
			return false
		end
end

-- parse code/result snippets from a comment and test them. 
function doctestComment(codeAndResults, num, fun)
	local oks, tests = 0, 0
	local code, result, comment_meta = {}, {}, {}
	function comment_meta:__newindex(k, v) end
	function comment_meta:__index(k) return "" end
	local comment = g.setmetatable({}, comment_meta)
	local mode = comment
	for angle, line, newline in codeAndResults:gmatch("(>*) *([^\n]*)(\n?)") do
		if angle == "" then
			if mode == code then
				g.table.insert(result, line)
				mode = result
			elseif mode == result then
				if line:match("^%s*$") then
					mode = comment
				else
					local modelen = #mode
					mode[modelen] = g.string.format("%s\n%s", mode[modelen], line or "")
				end
			end
		else
			if line:match("^%s*%=") then
				line = "return "..line:match("%=(.*)")
			end
			if mode == code then
				local modelen = #mode
				mode[modelen] = g.string.format("%s\n%s", mode[modelen], line or "")
			else
				g.table.insert(code, line)
				mode = code
			end
		end
	end
	for i = 1, #code do
		descr = g.string.format("%i.%i (%s):", num, i, 
			fun:match("^(.-)[ \r\n]*$"))
		if doctestSnippet(descr, code[i], result[i]) then oks = oks + 1 end
		tests = tests + 1
	end
	return oks, tests
end

--[=[=
doctestre will match the comment block plus first literal of the command line,
so we can include it in parenthesis with the test. For example, the following
test would be logged as "5.1 (doctestre):	ok"

> =1
1
=]=]
local doctestre = g.string.format("%s(.-)%s[\r\n]*([%%w _]*)",
	requote(comment_start), requote(comment_end));

--[=[=
This function will test all code snippets found in comments that follow the 
form comment_start .. [comment] .. comment_end (like this comment does). To let
doctest test itself, call "lua doctest.lua - doctest.lua".

Note that I will not test this function with doctest.lua because this would
create an infinite loop.

Also note that it is easy to write a small script using the lfs lua file system
module to doctest all lua files below a directory recursively.
=]=]	
function doctest(filename)
	log("testing "..filename)
	g.assert(g.loadfile(filename))()
	log("---------------")
	f = g.io.open(filename)
	local num = 1
	local oks = 0
	local tests = 0
	local code = f:read("*a")
	for comment, fun in code:gmatch(doctestre) do
		fun = (fun or ""):gsub("^local ", "")
		local start = comment:find("\n%s*>%s*")
		if start then
			local doks, dtests = doctestComment(
				comment:match("^%s*(.-)%s*$", start), num, (fun or ""))
			oks = oks + doks
			tests = tests + dtests
			num = num + 1
		end
	end
	f:close()
	log("---------------")
	log(g.string.format("%i of %i ok", oks, tests))
end

if g.arg and g.type(g.arg) == "table" and g.arg[0] == "doctest.lua" then
	do -- clear arg to enable self-test
		local _arg = g.arg
		g.arg = nil
		for num, filename in g.ipairs(_arg) do
			if num > 1 then
				doctest(filename)
			end
		end
		g.arg = _arg
	end
end
