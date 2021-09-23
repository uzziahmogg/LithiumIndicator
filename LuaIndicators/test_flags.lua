function setflag(p, s, r)
    return (256 * p + 16 * s + r)
end

function getflag(f)
    p = math.floor(f / 256)
    s = math.floor((f - p * 256) / 16)
    r = f - p * 256 - s * 16

    return p, s, r
end

function getdebugsignals(a)
    local r = {}

    r.param4 = a & 8
    r.param3 = a & 4
    r.param2 = a & 2
    r.param1 = a & 1

    return r
end

function printds(c)
    print("param1\tparam2\tparam3\tparam4")
    print(c.param1 .. "\t" .. c.param2 .. "\t" .. c.param3 .. "\t".. c.param4)
end

params = { category1 = { param1 = 1, param2 = 2, param3 = 4, param4 = 8 },
            category2 = { param1 = 1, param2 = 2, param3 = 4, param4 = 8 },
            category3 = { param1 = 1, param2 = 2, param3 = 4, param4 = 8 }}

f = setflag((params.category1.param1 + params.category1.param4), (params.category2.param4), (params.category3.param2 + params.category3.param3))
p, s, r = getflag(f)

print("p=" .. p .. "\ts=" .. s .. "\tr=" .. r)

p1 = getdebugsignals(p)
s1 = getdebugsignals(s)
r1 = getdebugsignals(r)

printds(p1)
printds(s1)
printds(r1)
