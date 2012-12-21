# Designgids

## while True

In Python, it is sometimes tempting to write code like this:

	while True
	    # do something
	    print "Hello."
	    if <condition>
	        break

The problem is that -- especially with longer loops -- you must look over the whole loop for the break statement to see when the loop finishes.

It is almost always possible to rewrite the loop without the `while True`. For example, the loop above is equivalent to this one:

	print "Hello." # (one time)
	
	while not <condition>
	    # do something
	    print "Hello."

It is shorter, and you can see right at the beginning when the loop will terminate.
