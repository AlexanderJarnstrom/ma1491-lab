#
## AES.sage
## Robert Nyqvist, 2022-2023
#

R.<x> = GF(2)[]
F.<x> = GF(2^8, name = 'x', modulus = x^8 + x^4 + x^3 + x + 1)

def text_till_polynom(t) :
    a = ZZ(ord(t))
    c = a.digits(base = 2, padto = 8)
    return F(c)

def polynom_till_text(p, format = 'text') :
    f = R(p)
    c = f.coefficients(sparse = False)
    n = -len(c) % 8
    c += n * [0]
    if format == 'text' :
        a = ZZ(c, base = 2)
        t = chr(a)
    elif format == 'hex' :
        s = []
        s += ZZ(c[4:], base = 2).digits(base = 16, digits = '0123456789ABCDEF', padto = 1)
        s += ZZ(c[:4], base = 2).digits(base = 16, digits = '0123456789ABCDEF', padto = 1)
        t = ''.join(s)
    return t

def text_till_block(klartext, utft = 'X') :
    m = klartext
    n = -len(m) % 16 # bestäm antal utfyllnadstecken för totala längden är en m
    m += n * utft
    S = [m[k:k+16] for k in range(0, len(m), 16)] # dela upp i delsträngar av l
    S = list(map(lambda s : [text_till_polynom(t) for t in s], S))
    L = list(map(lambda l : matrix(4, 4, l).transpose(), S))
    return L

def bitstr(p) :
    f = R(p)
    c = f.coefficients(sparse = False)
    c += (8 - len(c)) * [0]
    b = c[::-1]
    b = list(map(str, b))
    return u''.join(b)

def block_till_text(A, format = 'text') :
    L = []
    for j in [0..3] :
        for i in [0..3] :
            L += polynom_till_text(A[i,j], format)
    T = ''.join(L)
    return T

def binblock(m) :
    b = '\n'.join(['  '.join([bitstr(b) for b in list(r)]) for r in m])
    return b

def Sbox(p) :
    B = matrix(GF(2), 8, 8, [1, 0, 0, 0, 1, 1, 1, 1,
                             1, 1, 0, 0, 0, 1, 1, 1,
                             1, 1, 1, 0, 0, 0, 1, 1,
                             1, 1, 1, 1, 0, 0, 0, 1,
                             1, 1, 1, 1, 1, 0, 0, 0,
                             0, 1, 1, 1, 1, 1, 0, 0,
                             0, 0, 1, 1, 1, 1, 1, 0,
                             0, 0, 0, 1, 1, 1, 1, 1])
    u = vector(GF(2), [1, 1, 0, 0, 0, 1, 1, 0])
    if p == 0 :
        z = u
    else :
        y = p^(-1)
        y = R(y)
        y = y.coefficients(sparse = False)
        n = -len(y) % 8
        y += n * [0]
        y = vector(GF(2), y)
        z = B * y + u
    return F(z)

def SubBytes(A) :
    P = A.apply_map(Sbox)
    return P

def ShiftRows(A) :
    for k in [1..3] :
        v = A[k,:k]
        h = A[k,k:]
        A[k,-k:] = v
        A[k,:-k] = h
    return A

def MixColumns(A) :
    M = matrix(F, 4, 4, [x, x + 1, 1, 1,
                         1, x, x + 1, 1,
                         1, 1, x, x + 1,
                         x + 1, 1, 1, x])
    return M * A

def T(w, i) :
    u = vector([w[1], w[2], w[3], w[0]]).apply_map(Sbox)
    v = vector(F, [x^((i-4)//4), 0, 0, 0])
    return u + v

def rundnycklar(K) :
    W = text_till_block(K)[0]
    w = W.columns()
    for i in [4..43] :
        if mod(i, 4) == 0 :
            wi = w[i-4] + T(w[i-1], i)
        else :
            wi = w[i-4] + w[i-1]
        w.append(wi)
    W = matrix(w).transpose()
    return W

def AddRoundKey(A, W, i) :
    Wi = W[:,4*i:4*i+3+1]
    return A + Wi

def AES128(P, K) :
    W = rundnycklar(K)
    A = AddRoundKey(P, W, 0)
    for i in [1..10] :
        A = SubBytes(A)
        A = ShiftRows(A)
        if i < 10 :
            A = MixColumns(A)
        A = AddRoundKey(A, W, i)
    C = A
    return C
