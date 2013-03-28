Before running benchmark, create 3 versions of test data (small, medium, huge) 
To make it easier, I included dart script that does it, along with 10Kb file (which gets "multiplied" by N) - see script
You have to modify location of files hardcoded in the script

then run benchmark from command line. It expects input in stdin and output in stdout (which is normally /dev/null)
In benchmark program, TEST_MODE provides a way to run from Dart Editor, specifying hardcoded file names.
If you run in test mode, timing will be printed on the console.
 