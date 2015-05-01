from math import log

pot10 = 1

while True:
    divisor = 10 ** pot10
    x = 1.0/divisor
    x_str = '0.' + '0' * (pot10-1) + '1'
    print divisor, str(x), x_str
    if x != float(x_str):
        print x - float(x_str)
        print log(x, 10)
        break
    pot10 += 1
