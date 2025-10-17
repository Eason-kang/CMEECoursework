
import sys

def foo_1(x):
    """Return the square root of x"""
    return x ** 0.5

def foo_2(x, y):
    """Return the larger of two numbers"""
    if x > y:
        return x
    return y

def foo_3(x, y, z):
    """Sort the three input values x, y, and z in ascending order, and return the sorted result as a list in ascending order"""
    if x > y:
        tmp = y
        y = x
        x = tmp
    if y > z:
        tmp = z
        z = y
        y = tmp
    return [x, y, z]

def foo_4(x):
    """Return the factorial of x using a for loop"""
    result = 1
    for i in range(1, x + 1):
        result = result * i
    return result

def foo_5(x): # a recursive function that calculates the factorial of x
    """Return the factorial of x using recursion"""
    if x == 1:
        return 1
    return x * foo_5(x - 1)
     
def foo_6(x): # Calculate the factorial of x in a different way; no if statement involved
    """Return the factorial of x using a while loop"""
    facto = 1
    while x >= 1:
        facto = facto * x
        x = x - 1
    return facto

def main(argv):
    
    #Example function call
    print(foo_1(25))
    print(foo_2(5,10))
    print(foo_3(3,2,1))
    print(foo_4(10))
    print(foo_5(10))
    print(foo_6(5))

if __name__ == "__main__":
    sys.exit(main(sys.argv))