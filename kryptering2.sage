#
## kryptering2.sage
## Robert Nyqvist, 2022-2024
#

def bitar(m) :
    if type(m) is str :
        x = []
        for t in m :
            x += ZZ(ord(t)).digits(base = 2, padto = 8)
    else :
        x = [m[i:i+8] for i in range(0, len(m), 8)]
        x = [chr(ZZ(b, base = 2)) for b in x]
        x = ''.join(x)
    return x

def kod(m, k) :
    if type(m) is str :
        x = bitar(m)
        x = [x[i:i+k] for i in range(0, len(x), k)]
        x = [ZZ(b, base = 2) for b in x]
    else :
        x = flatten([h.digits(base = 2, padto = k) for h in m])
        x = bitar(x)
    return x
