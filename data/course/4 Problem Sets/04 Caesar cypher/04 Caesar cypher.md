# Caesar Chipher.

**Notice**: from now on, you are required to format your code according to the [style guide]. If you already submitted this problem set, you must reformat your code and submit again!

[style guide]: http://600.mprog.nl/page/28

<!-- *Check your pseudocode against ours before you finish your implementation!*-->

Encryption is the process of obscuring information to make it unreadable 
without special knowledge. For centuries, people have devised schemes to 
encrypt messages -- some better than others -- but the advent of the 
computer and the Internet revolutionized the field. These days, it's hard 
not to encounter some sort of encryption, whether you are buying something 
online or logging into Athena.

A cipher is an algorithm for performing encryption (and the reverse, 
decryption). The original information is called plaintext. After it is 
encrypted, it is called ciphertext. The ciphertext message contains all 
the information of the plaintext message, but it's not in a format 
readable by a human or computer without the proper mechanism to decrypt 
it; it should resemble random gibberish to those not intended to read it.

A cipher usually depends on a piece of auxiliary information, called a 
key. The key is incorporated into the encryption process; the same 
plaintext encrypted with two different keys should have two different 
ciphertexts. Without the key, it should be difficult to decrypt the 
resulting ciphertext into readable plaintext.

This assignment will deal with a well-known (though not very secure) 
encryption method called the Caesar cipher. In this problem set you will 
need to devise your own algorithms and will practice using recursion to 
solve a non-trivial problem.

## The algorithm.

In this problem set, we will examine the Caesar cipher. The basic idea in 
this cipher is that you pick an integer for a key, and shift every letter 
of your message by the key. For example, if your message was "hello" and 
your key was 2, "h" becomes "j", "e" becomes "g", and so on. If you're 
interested in learning more about the Caesar cipher, check out the 
Wikipedia article.

In this problem set, we will use a variant of the standard Caesar cipher 
where the space character is included in the shifts: space is treated as 
the letter after "z", so with a key of 2, "y" would become " ", "z" would 
become "a", and " " would become "b".

## Getting Started.

Download the [code templates][1].

* `ps4-pseudo.txt`: for problems 2a and 4a;
* `ps4.py`: the skeleton you’ll fill in;
* `words.txt`: a list of English words;
* `fable.txt`: an encoded fable.

Run the code without making any modifications to it, in order to ensure 
that everything is set up correctly. The code that we have given you loads 
a list of words from a file. If everything is okay, after a small delay, 
you should see the following printed out:

	Loading word list from file...
	55902 words loaded.

If you see an `IOError` instead (e.g., No such file or directory), you 
should change the value of the `WORDLIST_FILENAME` constant (defined near 
the top of the file) to the complete pathname for the file `words.txt` 
(this will vary based on where you saved the file).

The file, `ps4.py`, has a few functions already implemented that you can 
use while writing up your solution. You can ignore the code between the 
following comments, though you should read and understand everything else:

	# -----------------------------------
	# Helper code
	# (you don't need to understand this helper code) ...
	# (end of helper code)
	# -----------------------------------

## Pseudocode.

Pseudocode is writing out the algorithm/solution in a form that is like 
code, but not quite code. Pseudocode is language independent, uses plain 
English (or your native language), and is readily understandable. 
Algorithm related articles in wikipedia often use pseudocode to explain 
the algorithm.

Think of writing pseudocode like you would explain it to another person --
it doesn't generally have to conform to any particular syntax as long as 
what's happening is clear to the grader.

Pseudocode is a compact and informal high-level description of a computer 
programming algorithm that uses the structural conventions of a programming 
language, but is intended for human reading rather than machine reading. 

> Pseudocode typically omits details that are not essential for human 
> understanding of the algorithm, such as variable declarations,
> system-specific code and subroutines. The purpose of using pseudocode
> is that it is easier for humans to understand than conventional
> programming language code, and that it is a compact and environment-
> independent description of the key principles of an algorithm. No 
> standard for pseudocode syntax exists, as a program in pseudocode is 
> not an executable program. -- [Wikipedia][2]

In order to help you solve these problems correctly, we are requiring that 
you submit pseudocode for your solutions to problems 2 and 4 by Tuesday.
To do this, read problems 2 and 4, and think about high level algorithms
to solve both problems. Write down the steps in your algorithms and save
it in a plain text file named `ps4.txt`. Upload this file to Blackboard.

On Wednesday, we will post our own pseudocode. You can use our pseudocode 
or your own (if it's close enough), to write the Python code that actually 
solves problems 2 and 4.

## Problem 1. Encryption and Decryption.

Write a program to encrypt plaintext into ciphertext using the Caesar 
cipher. We have provided skeleton code for the following functions:

* `build_coder(shift)`
* `build_encoder(shift)`
* `build_decoder(shift)`
* `apply_coder(text, coder)`
* `apply_shift(text, shift)`

Once you've completed this program, you should be able to use it to encode strings.

## Problem 2. Code-breaking.

Your friend, who is also taking 6.00, is really excited about the program 
she wrote for Problem 1 of this problem set. She sends you emails, but 
they're all encrypted with the Caesar cipher!

The problem is, you don't know which shift key she is using. The good news 
is, you know your friend only speaks and writes English words. So if you 
can write a program to find the decoding that produces the maximum number 
of words, you can probably find the right decoding (There’s always a chance 
that the shift may not be unique. Accounting for this would probably use 
statistical methods that we won't require of you.)

### Part a: Pseudocode.

Think about an algorithm you could use to solve this problem. Write the steps down and save in the textfile named `ps4.txt`.

### Part b: Python code.

Implement `find_best_shift`. This function takes a wordlist and a bit of 
encrypted text and attempts to find the shift that encoded the text. A 
simple indication of whether or not the correct shift has been found is if 
all the words obtained after a shift are valid words. Note that this only 
means that all the words obtained are actual words. It is possible to have 
a message that can be decoded by two separate shifts into different sets 
words. While there are various strategies for deciding between ambiguous 
decryptions, for this problem we are only looking for a simple solution.

To assist you in solving this problem, we have provided a helper function:
`is_word(wordlist, word)`. This simply determines if word is a valid word 
according to wordlist. This function ignores capitalization and 
punctuation.

Hint: You may find the function `string.split` to be useful for dividing 
the text up into words.

Once you’ve written this function you can decode your friend’s emails!

## Problem 3. Multi-level Encryption & Decryption.

Clearly the basic Caesar cipher is not terribly secure. To make things a 
little harder to crack, you will now implement a multi-level Caesar cipher. 

Instead of shifting the entire string by a single value, you will perform 
additional shifts at specified locations throughout the string. This 
function takes a string text and a list of tuples shifts. The tuples in 
shifts represent the location of the shift, and the shift itself. For 
example a tuple of `(0,2)` means that the shift starts are position 0 in 
the string and is a Caesar shift of 2.

Additionally, the shifts are layered. This means that a set of shifts `[(0,2), (5, 3)]` will first apply a Caesar shift of 2 to the entire 
string, and then apply a Caesar shift of 3 starting at the 6th letter in 
the string.

To do this, implement the following function according to the 
specification.

## Problem 4. Multi-level Code-breaking.

Your friend has sent you another message, but this one can't be decrypted 
by your solution to Problem 2 — it must be using a multi-layer shift.

To keep things from getting too complicated, we will add the restriction 
that a shift can begin only at the start of a word. This means that once 
you have found the correct shift at one location, it is guaranteed to 
remain correct at least until the next occurrence of a space character.

### Part a: Pseudocode.

As in Problem 2, Part b, we want you to sketch out a high level step-by-
step algorithm for solving this problem.

HINT: Use recursion.

Save your steps in ps4.txt and upload this to your workspace.

### Part b: Python code.

To do this, implement the following function according to the 
specification.

To solve this problem successfully, we highly recommend that you use 
recursion (did we say use recursion again?). The non-recursive version of 
this function is much more difficult to understand and code. The key to 
getting the recursion correct is in understanding the seemingly
unnecessary parameter "start". As always with recursion, you should begin 
by thinking about your base case, the simplest possible sub-problem you 
will need to solve. What value of start would make a good base case?
(Hint: the answer is NOT zero.)

To help you test your code, we’ve given you two simple helper functions: 
`random_string(wordlist, n)` generates $n$ random words from wordlist and 
returns them in a string.

`random_scrambled(wordlist, n)` generates $n$ random words from wordlist 
and returns them in a string after encrypting them with a random multi-
level Caesar shift. You can start by making sure your code decrypts a 
single word correctly, then move up to 2 and higher.

NOTE: This function depends on your implementation of `apply_shifts`, so it 
will not work correctly until you have completed Problem 3.

## Problem 5. The Moral of the Story.

Now that you have all the pieces to the puzzle, please use them to decode 
the file, `fable.txt`. At the bottom of the skeleton file, you will see a 
method `get_fable_string()` that will return the encrypted version of the 
fable. Create the following method and include as a comment at the end of 
the problem set how the fable relates to your education at the University
of Amsterdam.

## Hand-In Procedure.

1. You should be using `ps4.txt` to save your pseudocode answers.
   Remember, this part is turned in first!

   You should be using the ps4.py skeleton given to you in this problem 
   set. Fill in the code for the functions: `build_coder()`,
   `apply_coder()`, `apply_shift()`, `find_best_shift()`, `apply_shifts()`,
   and `find_best_shifts()`. Any other code is not necessary. Save your 
   solution as `ps4.py`. Do not ignore this step or save your file with a 
   different name.

2. At the start of each file, in a comment, write down the number of hours 
   (roughly) you spent on the problems in that part, and the names of the 
   people you collaborated with. For example:

		# Problem Set 4
		# Name: Jane Lee
		# Collaborators (Discussion): John Doe
		# Collaborators (Identical Solution): Jane Smith
		# Time: 1:30
		#
		... your code goes here ...

[1]: http://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-00sc-introduction-to-computer-science-and-programming-spring-2011/unit-2/lecture-10-hashing-and-classes/ps4.zip

[2]: http://en.wikipedia.org/wiki/Pseudocode
