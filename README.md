Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students.

How to install
--------------

	git clone git@github.com:uva/course-site.git
	bundle install
	rake db:migrate

Warning!
--------

Currently, all submissions depend on the page id, which will be regenerated every time you import the course.

On the source format
--------------------

* Have a look at https://github.com/uva/prog-natster for information on how to
  organize your course repository. At the very least, you need a `course.yml`
  and a `info` directory containing subpages for the homepage.

* Numbering the course folders will make sure that they are imported and
  displayed in order. There is no harm in re-numbering your folders.

* Changing the name of a folder will change the URL of that folder on the
  website. This will break links from others site to your course site.

TODO
----

* Add required submission name to every submit.yml, in order to decouple
  submits from page id.
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
