
my_dictionary = {"a key": 10, "another key": 11}
import pickle
f = open("../sandbox/testp.p","wb")
pickle.dump(my_dictionary,f)
f.close()

f = open("../sandbox/testp.p","rb")
another_dictionary=pickle.load(f)
f.close()

print(another_dictionary)