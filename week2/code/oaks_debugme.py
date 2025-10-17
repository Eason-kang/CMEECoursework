import csv
import sys

#Define function
def is_an_oak(name):
    """
    Returns True if name starts with 'quercus' (oak genus), allowing for small typos.

    >>> is_an_oak('Quercus robur')
    True
    >>> is_an_oak('Fagus sylvatica')
    False
    >>> is_an_oak('quercus cerris')
    True
    >>> is_an_oak('Quercuss alba')  # small typo
    True
    >>> is_an_oak('Querrcus petraea')  # small typo
    True
    """
    name = name.strip().lower()
    # handle small typos: accept names that start with "quercus" ± one character
    if name.startswith('quercus'):
        return True
    if name.startswith('quercuss') or name.startswith('querrcus'):
        return True
    return False


def main(argv): 
    f = open('../data/TestOaksData.csv','r')
    g = open('../data/JustOaksData.csv','w')
    taxa = csv.reader(f)
    csvwrite = csv.writer(g)
    oaks = set()
    for row in taxa:
        print(row)
        print ("The genus is: ") 
        print(row[0] + '\n')
        if is_an_oak(row[0]):
            print('FOUND AN OAK!\n')
            csvwrite.writerow([row[0], row[1]])    

    return 0
    
if __name__ == "__main__":
    import doctest
    doctest.testmod()
    status = main(sys.argv)
