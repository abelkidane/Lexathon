# Semester Project for 3340.001, Professor Nguyen, Fall 2015
# Team "Treehouse":  Abel Kidane, Matt Roberts, Joseph Sawczyn, Aaron Parks-Young
# Last Update/Modification: December 3rd, 2015


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^Features^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
-This program simulates a somewhat simplified version of Lexathon in MIPS. The program will randomly select a 9-letter word from the dictionary and a random “center letter” and populate the answer sheet using these seeds.
-The program recognizes when input doesn’t meet input criteria and will remind the user of the criteria for input. (Must be four to nine letters long inclusive, not contain special characters unless entering a command, not contain numbers, and must contain the center letter.)
-The program displays the 9 letters available to the user in a grid format, with the middle letter taking the middle slot, as in the Lexathon game.
-The user may enter as many guesses as time allows. Correct words will increase their score and add 10 seconds to their remaining time.
-The user may also enter commands to perform special functions: /r for rules, /s to shuffle the grid, /st to stop a game and start a new one, /c to show the correct answers found, /o to show other answers attempted, or /e to exit.
-The game will end after time expires (requiring the user to enter something, but answers submitted past the end of the allowed time will be ignored), all of the answers are found, the user chooses to start a new game, or exit the program.
-Correct and “valid” but incorrect answers are logged seperately. "Invalid" answers are discarded.
-Answers found vs. answers left, score, and time remaining at refresh are shown to the user along with the grid containing the letters from the seed word.
-Multiple rounds may be played without restarting the program.
-Scoring is partialy dependent on time elapsed and is determined with this formula, which is our approximation to Lexathon’s scoring algorithm: score=250(words found/ total words)+(words per minute * 11)
-With great care for formatting, words can be added to or removed from our modifiedFullDictionary and 9LetterWords files to modify solution sets.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^Limitations^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
-modifiedFullDictionary.txt and 9LetterWords.txt must be present in the same directory as MARS, assuming the MARS emulator is being used, for the program to run properly.
-Extremely rapid entry of answers could cause an overflow of some of the reserved memory, but we’re talking thousands of unique entries within the timespan allotted by the game. This type of overflow would cause unexpected behavior, but effectively we only consider it a possibility if the user is machine assisted and intends to cause the overflow.
-Because of the limitations of MARS and MIPS, the timer will only show an updated value whenever the user inputs information during a game, though the timer is still counting in between inputs. Thus the string for time remaining mentions the time “at refresh”.
-Entering a 9 letter string for input will automatically submit the input. This is known and is not considered a problem because the only penalty for an incorrect solution is the time lost in entering that solution.
-The game takes approximately 40 seconds to generate a new answer sheet for a new game, as it is parsing our whole dictionary, which allows for a somewhat dynamic game (as you can modify the dictionary if you are careful). 
-Repeated resets/assembles of our code with MARS seems to slow the program to a point where it is unuseable and doesn't appear to meet the requirements. If this happens, restart MARS and load our code again.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^How to Run^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
modifiedFullDictionary.txt and 9LetterWords.txt must be present in the same directory as MARS for the program to run properly. In our experience the treehouse_project.asm can be loaded from a different  (or the same) directory as MARS so long as the two text files reside  in the same directory with MARS.

1. Ensure modifiedFullDictionary.txt and 9LetterWords.txt are properly saved as mentioned above.
2. Open the MARS emulator, if MARS is already open we suggest closing and starting MARS again before running our code as we’ve noticed execution of code by MARS seems to slow with repeated assembles/program resets. 
2. Load treehouse_project.asm
3. From the drop down menu “Run” click “Assemble”.
4. Press the green button with a single triangle (pointing to the right), “Run the current program”
5. Follow the prompts on the console. See rules below for answer entry information. Special commands are listed in game for reference and include: /r for rules, /s to shuffle the grid, /st to stop a game and start a new one, /c to show the correct answers found, /o to show other answers attempted, or /e to exit.

Rules:
Rules (as listed in game with /r command):
1. Enter a word using each letter in the grid at most once, ensuring the center letter is included.
2. Ensure the word is between 4 and 9 letters, inclusive, long.
3. Each correct answer earns you points and more time.
4.Enter as many correct answers as you can before time runs out!


