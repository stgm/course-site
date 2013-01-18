Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students.

How to install
--------------

	git clone git@github.com:uva/course-site.git
	bundle install
	rake db:migrate

On the source format
--------------------

* Have a look at https://github.com/uva/prog-natster for information on how to
  organize your course repository. At the very least, you need a `course.yml`
  and a `info` directory containing subpages for the homepage.

* Numbering the course folders will make sure that they are imported and
  displayed in order.

* Changing the name of a folder will change the URL of that folder on the
  website. This will break links from others site to your course site.

* Changing names and positions should not be a problem for form caching and
  file submissions already done.

Formattting your pages
----------------------

* All pages are to be formatted with [Markdown] and the [Kramdown] extensions.

* You can use [AsciiMath] if enclosed within two dollar signs ($). Also check
  the [AsciiMath syntax].

* We intend to use the native Kramdown math parser if this is workable.

[Markdown]: http://daringfireball.net/projects/markdown/syntax
[Kramdown]: http://kramdown.rubyforge.org/syntax.html
[AsciiMath]: http://www.wjagray.co.uk/maths/ASCIIMathTutorial.html
[AsciiMath syntax]: http://www.intmath.com/help/send-math-email-syntax.php

TODO
----

* Do not depend on dropbox config being present at start.
* Add a setting for source git URL and do a `git clone`.
* Add a setting for the dropbox upload folder to be used.
* Possibly allow db:migrate to be run from front end.
* Allow users to register name and email.
* Allow user to register an avatar.
* Allow the course to be hosted in dropbox.
* Allow some kind of push hook that automatically updates the site when a
  new course version is in the repository.
* Remove `security` section from course.yml, should be decoupled and
  configurable in site.
