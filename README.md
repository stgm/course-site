Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students.

How to install
--------------

Clone the application:

	git clone git@github.com:uva/course-site.git
	bundle install
	rake db:migrate

And clone the course contents into the `public/course` directory:

	cd public
	git clone <course-url> course

On the source format
--------------------

* Have a look at https://github.com/uva/prog-natster for information on how to
  organize your course repository. At the very least, you need a `course.yml`
  and a `info` directory containing subpages for the homepage.

* Numbering the course folders will make sure that they are imported and
  displayed in order. Any folders besides `info` that are not numbered will
  not be imported.

* Non-markdown files, like images or downloads, will be hosted directly in the
  public directory and can be referenced using relative links.

* Changing the name of a folder will change the URL of that folder on the
  website. This will break links from others site to your course site.

* Changing names and positions should not be a problem for form caching and
  file submissions already done. (**Warning**: updating the course while users
  have the page loaded will break their submit experience. Do not update the
  course mid-session for now.)

* Add a content delivery network server by adding a link to it in `course.yml`:

		cdn: http://cdn.mprog.nl/data-science


Formatting your pages
----------------------

* All pages are to be formatted with [Markdown] and the [Kramdown] extensions.

* You can use [AsciiMath] if enclosed within pairs of dollar signs ($$). Check
  the [AsciiMath syntax].

* Add a table of contents to a page using for example:

		* Table of Contents
		{:toc}

  This bullet is then replaced with a full table of contents of level 1 and 2
  headings.

[Markdown]: http://daringfireball.net/projects/markdown/syntax
[Kramdown]: http://kramdown.rubyforge.org/syntax.html
[AsciiMath]: http://www.wjagray.co.uk/maths/ASCIIMathTutorial.html
[AsciiMath syntax]: http://www.intmath.com/help/send-math-email-syntax.php

TODO
----

### Easy setup

* Add a setting for source git URL and do a `git clone`.
* Possibly allow db:migrate to be run from front end for easy installing.
* Allow the course to be hosted in dropbox.

### Configuration

* Add a setting for the dropbox upload folder to be used.

### Course updates

* Allow some kind of push hook that automatically updates the site when a
  new course version is in the repository.
