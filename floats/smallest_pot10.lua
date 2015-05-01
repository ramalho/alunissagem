pot10 = 1

while true do
    divisor = 10 ^ pot10
    x = 1/divisor
    x_str = '0.' .. string.rep('0', pot10-1) .. '1'
    print(divisor, x, x_str)
    if x ~= tonumber(x_str) then
        print(x - tonumber(x_str))
        print(math.log10(x))
        break
    end
    pot10 = pot10 + 1
end