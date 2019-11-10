Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students. Ruby 1.9 with Rails 4.0 is required.

How to install
--------------

Clone the application:

	git clone git@github.com:uva/course-site.git
	bundle install
	rake db:schema:load

You can now claim the site by authenticating, and then load the initial content by specifiying a git repository URL that can be cloned.

Alternatively, you can clone the course contents yourself, into the `public/course` directory:

	cd public
	git clone <course-url> course

On the source format
--------------------

* Have a look at https://github.com/uva/uva-prog-physics for information on
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

* You can use [AsciiMath] if enclosed within pairs of dollar signs ($$). Check
  the [AsciiMath syntax].

* Add a table of contents to a page using:

		* Table of Contents
		{:toc}

    This single bullet item is then replaced with a full table of contents of
    level 1 and 2 headings.

* Add a content delivery network server by adding a link to it in
  `course.yml`:

		cdn: http://cdn.mprog.nl/uva-prog-physics

    Then, any link starting with `cdn://` will be rewritten to start with
    that exact cdn url.

* Use `videoplayer` as the alt text for an image link in order to generate a video player:

        ![videoplayer](cdn://video/lecture001.mp4)

[Markdown]: http://daringfireball.net/projects/markdown/syntax
[Kramdown]: http://kramdown.rubyforge.org/syntax.html
[AsciiMath]: http://www.wjagray.co.uk/maths/ASCIIMathTutorial.html
[AsciiMath syntax]: http://www.intmath.com/help/send-math-email-syntax.php

Admin configuration options
---------------------------

* Setting a `DROPBOX_KEY` and `DROPBOX_SECRET` will allow the admin user to
  connect their Dropbox account to the course site.

* Setting an `COURSESITE_API_TOKEN` will allow another website to import some data from a special endpoint.

* Setting a `CAS_BASE_URL` is needed for authentication using CAS (the only option). In development, a "fake" login screen is used which accepts any username.

* Setting a `MAILER_ADDRESS` and `MAILER_DOMAIN` will allow mails to be sent to users.

Some stuff we still want
------------------------

* Allow the course to be hosted in dropbox.
* Support some other authentication mechanism than CAS only.
