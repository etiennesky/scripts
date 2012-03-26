all: mcd45a1-m2y 

 mcd45a1-m2y : 	mcd45a1-m2y.cpp	
	g++ -lgdal mcd45a1-m2y.cpp -o mcd45a1-m2y

 mcd45a1-monthly-m2y : 	mcd45a1-monthly-m2y.cpp	
	g++ -ggdb  -lgdal mcd45a1-monthly-m2y.cpp -o mcd45a1-monthly-m2y

 val_repl_csv : 	val_repl_csv.cpp	
	g++ -Wall -lgdal val_repl_csv.cpp -o val_repl_csv

 l3jrc-split:  l3jrc-split.cpp
	g++ -lgdal  l3jrc-split.cpp -o l3jrc-split

 testtime : 	testtime.c	
	gcc testtime.c -o testtime