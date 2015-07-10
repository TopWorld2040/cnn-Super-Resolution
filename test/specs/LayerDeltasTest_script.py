# helper script to generate expected delta values
# for LayerDeltasTest

deltas=[0.122, 0.083, 0.064,
        0.057, 0.075, 0.055,
        0.025, 0.058, 0.138,
        0.170, 0.068, 0.144,
        0.121, 0.013, 0.176,
        0.065, 0.169, 0.049,
        0.003, 0.181, 0.051,
        0.021, 0.136, 0.062,
        0.066, 0.165, 0.176]
f=3
n_curr = 3
n_prev = 2

# 00000    -
# 0___0    0
# 0___0    1
# 0___0    2
# 00000    -

d=[None]*25
d[0] = [(0,0)]
d[1] = [(0,0),(0,1)]
d[2] = [(0,0),(0,1),(0,2)]
d[3] = [(0,1),(0,2)]
d[4] = [(0,2)]

d[5] = [(0,0),(1,0)]
d[6] = [(0,0),(0,1),(1,0),(1,1)]
d[7] = [(0,0),(0,1),(0,2), (1,0),(1,1),(1,2)]
d[8] = [(0,1),(0,2), (1,1),(1,2)]
d[9] = [(0,2), (1,2)]

d[10] = [(0,0),(1,0),(2,0)]
d[11] = [(0,0),(0,1),(1,0),(1,1),(2,0),(2,1)]
d[12] = [(0,0),(0,1),(0,2), (1,0),(1,1),(1,2), (2,0),(2,1),(2,2)]
d[13] = [(0,1),(0,2), (1,1),(1,2), (2,1),(2,2)]
d[14] = [(0,2), (1,2), (2,2)]

d[15] = [(2,0),(1,0)]
d[16] = [(2,0),(2,1),(1,0),(1,1)]
d[17] = [(2,0),(2,1),(2,2), (1,0),(1,1),(1,2)]
d[18] = [(2,1),(2,2), (1,1),(1,2)]
d[19] = [(2,2), (1,2)]

d[20] = [(2,0)]
d[21] = [(2,0),(2,1)]
d[22] = [(2,0),(2,1),(2,2)]
d[23] = [(2,1),(2,2)]
d[24] = [(2,2)]

for xs in d:
  summ = 0
  for row,col in xs:
    idx = row*f*f + col*f
    for k in range(n_curr):
      summ += deltas[idx+k]
  print(summ)
