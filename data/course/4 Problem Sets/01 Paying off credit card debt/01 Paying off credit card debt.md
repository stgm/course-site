# Paying Off Credit Card Debt

This problem set will introduce you to using control flow in Python and formulating a computational solution to a problem. You will design and write three simple Python programs, test them, and hand them in. Be sure to read this problem set thoroughly.

Each month, a credit card statement will come with the option for you to pay a minimum amount of your charge, usually 2% of the balance due. However, the credit card company earns money by charging interest on the balance that you don’t pay. So even if you pay credit card payments on time, interest is still accruing on the outstanding balance.

Say you’ve made a € 5000 purchase on a credit card with 18% annual interest rate and 2% minimum monthly payment rate. After a year, how much is the remaining balance? Use the following equations.

* **Minimum monthly payment** = Minimum monthly payment rate x Balance (Minimum monthly payment gets split into interest paid and principal paid) 
* **Interest Paid** = Annual interest rate / 12 months x Balance
* **Principal paid** = Minimum monthly payment – Interest paid
* **Remaining balance** = Balance – Principal paid

For month 1, we can compute the minimum monthly payment by taking 2% of the balance:

**Minimum monthly payment** = .02 x €5000.0 = €100.0

We can't simply deduct this from the balance because there is compounding interest. Of this €100 monthly payment, compute how much will go to paying off interest and how much will go to paying off the principal. Remember that it's the annual interest rate that is given, so we need to divide it by 12 to get the monthly interest rate.

* **Interest paid** = .18/12.0 x €5000.0 = €75.0
* **Principal paid** = €100.0 – €75.0 = €25

The remaining balance at the end of the first month will be the principal paid this month subtracted from the balance at the start of the month.

**Remaining balance** = €5000.0 – €25.0 = €4975.0

For month 2, we repeat the same steps:

* **Minimum monthly payment** = .02 x €4975.0 = €99.50
* **Interest Paid** = .18/12.0 x €4975.0 = €74.63
* **Principal Paid** = €99.50 – €74.63 = €24.87
* **Remaining Balance** = €4975.0 – €24.87 = €4950.13

After 12 months, the total amount paid is €1167.55, leaving an outstanding balance of €4708.10. Pretty depressing!

## Paying the Minimum

###Problem 1

Write a program to calculate the credit card balance after one year if a person only pays the minimum monthly payment required by the credit card company each month.

Use `raw_input()` to ask for the following three floating point numbers:

1. the outstanding balance on the credit card
2. annual interest rate
3. minimum monthly payment rate

For each month, print the minimum monthly payment, remaining balance, principle paid in the format shown in the test cases below. All numbers should be rounded to the nearest penny. Finally, print the result, which should include the total amount paid that year and the remaining balance.

### Test Case 1

	>>>
	Enter the outstanding balance on your credit card: 4800
	Enter the annual credit card interest rate as a decimal: .2
	Enter the minimum monthly payment rate as a decimal: .02
	Month: 1
	Minimum monthly payment: €96.0
	Principle paid: €16.0
	Remaining balance: €4784.0
	Month: 2
	Minimum monthly payment: €95.68
	Principle paid: €15.95
	Remaining balance: €4768.05
	Month: 3
	Minimum monthly payment: €95.36
	Principle paid: €15.89
	Remaining balance: €4752.16
	Month: 4
	Minimum monthly payment: €95.04
	Principle paid: €15.84
	Remaining balance: €4736.32
	Month: 5
	Minimum monthly payment: €94.73
	Principle paid: €15.79
	Remaining balance: €4720.53
	Month: 6
	Minimum monthly payment: €94.41
	Principle paid: €15.73
	Remaining balance: €4704.8
	Month: 7
	Minimum monthly payment: €94.1
	Principle paid: €15.69
	Remaining balance: €4689.11
	Month: 8
	Minimum monthly payment: €93.78
	Principle paid: €15.63
	Remaining balance: €4673.48
	Month: 9
	Minimum monthly payment: €93.47
	Principle paid: €15.58
	Remaining balance: €4657.9
	Month: 10
	Minimum monthly payment: €93.16
	Principle paid: €15.53
	Remaining balance: €4642.37
	Month: 11
	Minimum monthly payment: €92.85
	Principle paid: €15.48
	Remaining balance: €4626.89
	Month: 12
	Minimum monthly payment: €92.54
	Principle paid: €15.43
	Remaining balance: €4611.46
	RESULT
	Total amount paid: €1131.12
	Remaining balance: €4611.46
	>>>

### Test Case 2

In recent years, many credit card corporations tightened restrictions by raising their minimum monthly payment rate to 4%. As illustrated in the second test case below, people will be able to pay less interest over the years and get out of debt faster.

	>>>
	Enter the outstanding balance on your credit card: 4800
	Enter the annual credit card interest rate as a decimal: .2
	Enter the minimum monthly payment rate as a decimal: .04
	Month: 1
	Minimum monthly payment: €192.0
	Principle paid: €112.0
	Remaining balance: €4688.0
	Month: 2
	Minimum monthly payment: €187.52
	Principle paid: €109.39
	Remaining balance: €4578.61
	Month: 3
	Minimum monthly payment: €183.14
	Principle paid: €106.83
	Remaining balance: €4471.78
	Month: 4
	Minimum monthly payment: €178.87
	Principle paid: €104.34
	Remaining balance: €4367.44
	Month: 5
	Minimum monthly payment: €174.7
	Principle paid: €101.91
	Remaining balance: €4265.53
	Month: 6
	Minimum monthly payment: €170.62
	Principle paid: €99.53
	Remaining balance: €4166.0
	Month: 7
	Minimum monthly payment: €166.64
	Principle paid: €97.21
	Remaining balance: €4068.79
	Month: 8
	Minimum monthly payment: €162.75
	Principle paid: €94.94
	Remaining balance: €3973.85
	Month: 9
	Minimum monthly payment: €158.95
	Principle paid: €92.72
	Remaining balance: €3881.13
	Month: 10
	Minimum monthly payment: €155.25
	Principle paid: €90.56
	Remaining balance: €3790.57
	Month: 11
	Minimum monthly payment: €151.62
	Principle paid: €88.44
	Remaining balance: €3702.13
	Month: 12
	Minimum monthly payment: €148.09
	Principle paid: €86.39
	Remaining balance: €3615.74
	RESULT
	Total amount paid: €2030.15 Remaining balance: €3615.74
	>>>

### Hints

Use the `round` function.

To help you get started, here is a rough outline of the stages you should probably follow in
writing your code:

* Retrieve user input.
* Initialize some state variables. Remember to find the monthly interest rate from the annual interest rate taken in as input.
* For each month:
	* Compute the new balance. This requires computing the minimum monthly payment and figuring out how much will be paid to interest and how much will be paid to the principal.
	* Update the outstanding balance according to how much principal was paid off.
	* Output the minimum monthly payment and the remaining balance.
	* Keep track of the total amount of paid over all the past months so far.
* Print out the result statement with the total amount paid and the remaining balance.

Use these ideas to guide the creation of your code.

## Paying Debt Off In a Year

### Problem 2

Now write a program that calculates the minimum fixed monthly payment needed in order pay off a credit card balance within 12 months. We will not be dealing with a minimum monthly payment rate.

Take as `raw_input()` the following floating point numbers:

1. the outstanding balance on the credit card
2. annual interest rate as a decimal

Print out the fixed minimum monthly payment, number of months (at most 12 and possibly less than 12) it takes to pay off the debt, and the balance (likely to be a negative number).
Assume that the interest is compounded monthly according to the balance at the start of the month (before the payment for that month is made). The monthly payment must be a multiple of €10 and is the same for all months. Notice that it is possible for the balance to become negative using this payment scheme. In short:

* **Monthly interest rate** = Annual interest rate / 12.0
* **Updated balance each month** = Previous balance x (1 + Monthly interest rate) – Minimum monthly payment

### Test Case 1

	>>>
	Enter the outstanding balance on your credit card: 1200
	Enter the annual credit card interest rate as a decimal: .18
	RESULT
	Monthly payment to pay off debt in 1 year: 120
	Number of months needed: 11
	Balance: -10.05
	>>>

### Test Case 2

	>>>
	Enter the outstanding balance on your credit card: 32000
	Enter the annual credit card interest rate as a decimal: .2
	RESULT
	Monthly payment to pay off debt in 1 year: 2970
	Number of months needed: 12
	Balance: -74.98
	>>>

### Hints

Start at €10 payments per month and calculate whether the balance will be paid off (taking into account the interest accrued each month). If €10 monthly payments are insufficient to pay off the debt within a year, increase the monthly payment by €10 and repeat.

### Using Bisection Search to Make the Program Faster

You’ll notice that in problem 2, your monthly payment had to be a multiple of €10. Why did we make it that way? In a separate file, you can try changing the code so that the payment can be any dollar and cent amount (in other words, the monthly payment is a multiple of €0.01). Does your code still work? It should, but you may notice that your code runs more slowly, especially in cases with very large balances and interest rates.

How can we make this program faster? We can use bisection search (to be covered in lecture 3)!

We are searching for the smallest monthly payment such that we can pay off the debt within a year. What is a reasonable lower bound for this value? We can say €0, but you can do better than that. If there was no interest, the debt can be paid off by monthly payments of one-twelfth of the original balance, so we must pay at least this much. One-twelfth of the original balance is a good lower bound.

What is a good upper bound? Imagine that instead of paying monthly, we paid off the entire balance at the end of the year. What we ultimately pay must be greater than what we would’ve paid in monthly installments, because the interest was compounded on the balance we didn’t pay off each month. So a good upper bound would be one-twelfth of the balance, after having its interest compounded monthly for an entire year.

In short:

* **Monthly payment lower bound** = Balance / 12.0
* **Monthly payment upper bound** = (Balance * (1 + (Annual interest rate / 12.0)) ** 12.0) / 12.0

### Problem 3

Write a program that uses these bounds and bisection search (for more info check out the [Wikipedia page](http://en.wikipedia.org/wiki/Bisection_method)) to find the smallest monthly payment to the cent (no more multiples of €10) such that we can pay off the debt within a year. Try it out with large inputs, and notice how fast it is. Produce the output in the same format as you did in problem 2.

### Test Case 1

	>>>
	Enter the outstanding balance on your credit card: 320000
	Enter the annual credit card interest rate as a decimal: .2
	RESULT
	Monthly payment to pay off debt in 1 year: 29643.05
	Number of months needed: 12
	Balance: -0.1
	>>>

### Test Case 2

	>>>
	Enter the outstanding balance on your credit card: 999999
	Enter the annual credit card interest rate as a decimal: .18
	RESULT
	Monthly payment to pay off debt in 1 year: 91679.91
	Number of months needed: 12
	Balance: -0.12
	>>>

## Hand-In Procedure

1. Save
	
	Save your solution to Problem 1 as ps1a.py, Problem 2 as ps1b.py, and Problem 3 as ps1c.py. Do not ignore this step or save your files with a different name.

2. Time and Collaboration Info

	At the start of each file, in a comment, write down the number of hours (roughly) you spent on the problems in that part, and the names of the people you collaborated with.

	For example:

		# Problem Set 1
		# Name: Jane Lee
		# Collaborators: John Doe
		# Time Spent: 3:30
		#
		... your code goes here ...

3. Upload on Blackboard! Simply add the three files to your submission.

