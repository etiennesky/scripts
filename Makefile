all: mcd45a1-m2y mcd45a1-monthly-m2y val_repl_csv

mcd45a1-m2y : 	mcd45a1-m2y.cpp	
	g++ mcd45a1-m2y.cpp -g -o mcd45a1-m2y -lgdal

mcd64a1-m2y : 	mcd64a1-m2y.cpp	
	g++ mcd64a1-m2y.cpp -g -o mcd64a1-m2y -lgdal

mcd45a1-monthly-m2y : 	mcd45a1-monthly-m2y.cpp	
	g++ -ggdb mcd45a1-monthly-m2y.cpp -o mcd45a1-monthly-m2y -lgdal 

val_repl_csv : 	val_repl_csv.cpp	
	g++ -Wall val_repl_csv.cpp -o val_repl_csv -lgdal 

# l3jrc-split:  l3jrc-split.cpp
#	g++ -lgdal  l3jrc-split.cpp -o l3jrc-split

testtime : 	testtime.c	
	gcc testtime.c -o testtime

clean:
	rm -f mcd45a1-m2y mcd45a1-monthly-m2y val_repl_csv testtime
