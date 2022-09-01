# Allowing submits

Add a file named `submit.yml` to any directory to allow submits on the respective page. 

    name: resize
    files:
        required:
            - resize.c
        optional:
            - any_file.py
            - any_file.c
    check:
        tool: check50
        slug: minprog/checks/2022/resize/more

## Name

Any single `name` can only be used on one page on the site. It will identify the submit internally and to users (graders, admins). You can use underscores or dashes in the name.

Renaming a submit is never recommended, because the relation between the old name and new name will not be inferred. It will just create a new submit identifier in the website which will exist next to the old one. Old submits will still be linked to the old name for students and teachers alike.

## Files

You may include a `files` key which in turn should contain one or more keys that specify types of files, like `required` or `optional` in the example above. For each type of file you should include one or more expected file names.

Note that the file picker on the website will be configured to allow only files of the extension that is specified here.

The file types `required` and `optional` are special in the sense that i18n translations for these keys are included in the website. The file type `required` is also special because the form will be configured to make these files mandatory.

It is not possible to configure to allow a variable number of files to be submitted. However, you can request zip-files or other archive formats.

## Forms

You can add text form fields in markdown files to add these to the web page. Answers will be stored with the submission and can be inspected in the grading interface.

    <input name="form[q1a]" type="text" required>
    <textarea name="form[q2]" rows="8" required></textarea>

## Checks

The auto-check function is hardcoded to our local configuration. The key `tool` may be `checkpy` or `check50`. The configuration for `checkpy` would look like this:

    check:
        tool: checkpy
        repo: uva/progns
        args: -m monopoly
