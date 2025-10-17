a = 2
type(a)
number_str = "3.14"
number_float=float(number_str)
?number_float
MyList = [3,2.44,'green',True]
MyList[1]
MyList.append('a new item')
%whos
MyTuple = ("a", "b", "c")
print(MyTuple)
MyTuple[0]
len(MyTuple)
FoodWeb=[('a','b'),('a','c'),('b','c'),('c','c')]
FoodWeb
FoodWeb[0]
FoodWeb[0][0]
a = (1, 2, []) 
a
a[2].append(1000)
a
a[2].append(1000)
a
a[2].append((100,10))
a
a = (1, 2, 3)
b = a + (4, 5, 6)
b
c = b[1:]
c
a = ("1", 2, True)
a
a = [5,6,7,7,7,8,9,9]
b = set(a)
b
c = set([3,4,5,6])
b & c # intersection
import copy

a = [[1, 2], [3, 4]]
b = copy.deepcopy(a)
a[0][1] = 22
print(a)
print(b)
s = " this is a string "
len(s) # length of s -> 18
s.replace(" ","-") # Substitute spaces " " with dashes
s.find("s") # First occurrence of s (remember, indexing starts at 0)
x = 11
for i in range(x):
    if i > 3: #4 spaces or 2 tabs in this case
        print(i)