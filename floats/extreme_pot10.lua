pot10 = 1

while true do
    divisor = 10 ^ pot10
    x = 1/divisor
    x_str = '0.' .. string.rep('0', pot10-1) .. '1'
    if x ~= tonumber(x_str) then
        print(divisor, x, x_str)
        print(x - tonumber(x_str))
        print(math.log10(x))
        break
    end
    pot10 = pot10 + 1
end

pot10 = 1
previous = 0

while true do
    multiplier = 10 ^ pot10
    x = 1 * multiplier
    x_str = '1' .. string.rep('0', pot10) .. '.0'
    if x == previous then
        print(previous)
        print(multiplier, x, x_str)
        print(x - tonumber(x_str))
        print(math.log10(x))
        break
    end
    pot10 = pot10 + 1
    previous = x
end

