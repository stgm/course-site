Course website
==============

This site serves courses that reside in a git repo consisting of mostly Markdown-formatted text files and any other source files that should be served to the students. The code is targeted towards Rails 8.0.

How to install
--------------

Clone the application:

    git clone git@github.com:uva/course-site.git
    cd course-site
    bundle install
    rails db:setup

You can now claim the site by authenticating, and then load the initial content by specifiying a git repository URL that can be cloned.

Alternatively, you can clone the course contents yourself, into the `public/course` directory:

    cd public
    git clone <course-url> course

On the source format
--------------------

* Have a look at https://github.com/minprog/platforms for information on
  how to organize your course repository. At the very least, you need a
  `course.yml` and a `info` directory containing subpages for the homepage.

Organization
------------

* Put markdown files in a directory structure (extension `.md`). That
  structure will be exposed in the live website.

        ├── problems
        │   ├── acid
        │   │   ├── index.md
        │   │   └── submit.yml
        │   ├── alfabet
        │   │   ├── alfabet.png
        │   │   ├── index.md
        │   │   └── submit.yml
        │   ├── beatles
        │   │   ├── beatles.c
        │   │   ├── index.md
        │   │   └── submit.yml

* It's common to just put a `index.md` in each directory. For example,
  `/problems/acid/index.md` will be served at `/problems/acid`. Any
  filename will do, it's not hardcoded to `index.md`

* It's also possible to put multiple markdown files in a single
  directory, in which case the file's contents will be presented below each
  other in the generated HTML.

* Small non-markdown files, like images or downloads, will be hosted directly
  in the public directory and can be referenced using relative links in markdown.

        [download beatles.c template](beatles.c)
        
        ![picture of the alphabet](alfabet.png)

* Numbering folders will make sure that they are imported and
  displayed in order.

        10 internet
        20 computing
        22 hardware
        30 ai

* Changing the name of a folder will change the URL of that folder on the
  website. This will break links from other sites to your course site.

* Add a `submit.yml` to allow submitting student work. This configuration file
  should at least specify a name for the assignment. Because of this, it's
  fine to move around files, folders and submits, as long as the submit
  configuration keeps the same name.

        name: mario
        files:
            required:
                - mario.c
            optional:
                - explanation.txt

* A submit form is shown in a separate tab on the page. If you would like
  to add special instructions for submitting, just add a `submit.md` next
  to the `submit.yml`. In that case, it's even possible to leave out the
  `index.md` or other markdown files entirely.

Configuration files
-------------------

*   You probably would like a `course.yml` in the root of the course repository. You
    can set the following keys:

        long_name: Programmeren 1
        short_name: Prog1
        language: nl
        links:
            '[icon] Link display title': /link
        acknowledgements:
            - Based on ... course - copyright 2023
        license: This work is licensed as...

    * `long_name` and `short_name` are used in a few places in the website and in 
      e-mail subjects.

    * `language` can generally be `en` or `nl`.

    * Links are added to the site toolbar. You can and should use [Bootstrap Icon] names
      to add icons to the toolbar buttons.

    * `acknowledgements` is a list of strings (may contain HTML)

    * `license` is a single string (may contain HTML)

    * Check out [YAML multiline] for more information about multi-line strings

*   Other configuration files are `schedule.yml`, `grading.yml` and `materials.yml`.

[Bootstrap Icon]: https://icons.getbootstrap.com
[YAML multiline]: https://yaml-multiline.info

Formatting your pages
----------------------

* All pages are to be formatted with [Markdown] and the [Kramdown] extensions.

* You can use [AsciiMath] or LaTeX math if enclosed within pairs of dollar signs
  (`$$sin(x)$$`, or `$sin(x)$` for inlined math). Check the [AsciiMath syntax].

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

* Install `mupdf` and `imagemagick` for upload processing.
