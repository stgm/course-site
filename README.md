Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students. The code is targeted towards Rails 6.1.

How to install
--------------

Clone the application:

	git clone git@github.com:uva/course-site.git
	bundle install
	rails db:schema:load

You can now claim the site by authenticating, and then load the initial content by specifiying a git repository URL that can be cloned.

Alternatively, you can clone the course contents yourself, into the `public/course` directory:

	cd public
	git clone <course-url> course

On the source format
--------------------

* Have a look at https://github.com/minprog/platforms for information on
  how to organize your course repository. At the very least, you need a
  `course.yml` and a `info` directory containing subpages for the homepage.

* Numbering the course folders will make sure that they are imported and
  displayed in order. Any folders besides `info` that are not numbered will
  not be imported.

* Small non-markdown files, like images or downloads, will be hosted directly
  in the public directory and can be referenced using relative links.

* Changing the name of a folder will change the URL of that folder on the
  website. This will break links from other sites to your course site.

* Changing names and positions of folders and Markdown files should not be a
  problem for form caching and file submissions already done.

Formatting your pages
----------------------

* All pages are to be formatted with [Markdown] and the [Kramdown] extensions.

* You can use [AsciiMath] or LaTeX if enclosed within pairs of dollar signs (`$$sin(x)$$`, or `$sin(x)$` for inlined math). Check the [AsciiMath syntax].

* Add a table of contents to a page using:

		* Table of Contents
		{:toc}

    This single bullet item is then replaced with a full table of contents of
    level 1 and 2 headings.

[Markdown]: http://daringfireball.net/projects/markdown/syntax
[Kramdown]: https://kramdown.gettalong.org/syntax.html
[AsciiMath]: http://www.wjagray.co.uk/maths/ASCIIMathTutorial.html
[AsciiMath syntax]: http://www.intmath.com/help/send-math-email-syntax.php

Admin configuration options
---------------------------

* Setting a `CAS_BASE_URL` is needed for authentication using CAS (the only option). In development, a "fake" login screen is used which accepts any username.

* Setting a `MAILER_ADDRESS` and `MAILER_DOMAIN` will allow mails to be sent to users.

Dependencies
------------

* Install `libvips` according to the instructions for the [ImageProcessing](https://github.com/janko/image_processing) gem in order to be able to view images uploaded by students.

Some stuff we still want
------------------------

* Support some other authentication mechanism than CAS only.
