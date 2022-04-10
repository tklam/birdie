import py_skiplist.skiplist as sss
sl = sss.Skiplist()

print('X')
print(1 in sl)
print(sl.get_exact_and_just_smaller(10000000))
sl[1] = 1
sl[2] = 2
sl[4] = 4
sl[5] = 5

print('A')
print(1 in sl)
print(2 in sl)

print('B')
print(3 in sl)

print('C')
print(999 in sl)

print('D')
print(sl.get_exact_and_just_smaller(1))
print(sl.get_exact_and_just_smaller(2))
print(sl.get_exact_and_just_smaller(3))
print(sl.get_exact_and_just_smaller(4))
print(sl.get_exact_and_just_smaller(5))
print(sl.get_exact_and_just_smaller(7))
print(sl.get_exact_and_just_smaller(10000000))

sl[1000] = 'A'
sl[2000] = 'B'
print('E')
print(sl.get_exact_and_just_smaller(1000))
print(sl.get_exact_and_just_smaller(1500))
print(sl.get_exact_and_just_smaller(2000))
