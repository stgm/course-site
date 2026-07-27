# Builds a single zip with everything needed to archive the course:
#
#   grades.xlsx                      all grades, same data as the xlsx export button
#   grades-overview.pdf              per-student grade overview, one page per student
#   schedules/<slug>/syllabus.pdf    the schedule's syllabus page
#   schedules/<slug>/announcements.pdf
#
# Everything is generated synchronously and in memory; there is no job runner.
#
class CourseArchive

    # the scopes for the grade exports, shared with Admin::CourseController#export_grades
    #
    def self.grade_export_scopes
        [
            User.student.joins(:submits).uniq,
            Pset.joins(:submits).distinct.order(:order),
            # all users who ever submitted something
            User.joins(:submits).distinct.order(:name)
        ]
    end

    def to_zip
        Zip::OutputStream.write_buffer do |zip|
            add_entry(zip, "grades.xlsx") { grades_xlsx }
            add_entry(zip, "grades-overview.pdf") { grades_overview_pdf }

            Schedule.order(:name).each do |schedule|
                dir = "schedules/#{schedule.slug}"
                if schedule.page.present?
                    add_entry(zip, "#{dir}/syllabus.pdf") { syllabus_pdf(schedule) }
                end
                add_entry(zip, "#{dir}/announcements.pdf") { announcements_pdf(schedule) }
            end
        end.string
    end

    private

    def helpers
        @helpers ||= ApplicationController.helpers
    end

    # write one entry, but never let a single broken page kill the whole download:
    # on failure the zip gets an error note in place of the file
    #
    def add_entry(zip, filename)
        contents = yield
        zip.put_next_entry(filename)
        zip.write(contents)
    rescue => e
        Rails.logger.error("CourseArchive: could not generate #{filename}: #{e.class}: #{e.message}")
        zip.put_next_entry("#{filename}.ERROR.txt")
        zip.write("Could not generate #{filename}\n\n#{e.class}: #{e.message}\n\n#{e.backtrace&.first(20)&.join("\n")}\n")
    end

    #
    # grades
    #

    def grades_xlsx
        users, psets, students = self.class.grade_export_scopes
        ApplicationController.render(
            template: "admin/course/export_grades",
            formats: [ :xlsx ],
            assigns: { users: users, psets: psets, students: students, title: "Export grades" }
        )
    end

    # the PDF equivalent of admin/course/export_grades.html.erb: a page per student
    # with all their submits and grades
    #
    def grades_overview_pdf
        _users, _psets, students = self.class.grade_export_scopes

        pdf_document(landscape: true) do |pdf|
            pdf.text "Course export", size: 18, style: :bold
            pdf.text pdf_safe(Course.long_name), size: 11
            pdf.text "Exported on #{DateTime.now.to_fs(:long)}", size: 11
            pdf.move_down 10

            students.each_with_index do |student, index|
                pdf.start_new_page if index > 0
                pdf.text pdf_safe("#{student.name} (#{student.defacto_student_identifier})"), size: 12, style: :bold
                pdf.move_down 4

                rows = grade_rows(student)
                if rows.size > 1
                    pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 7, padding: 3 }) do
                        row(0).font_style = :bold
                    end
                else
                    pdf.text "No submits.", size: 8
                end
            end
        end
    end

    def grade_rows(student)
        rows = [ [ "pset", "submitted", "graded", "grade", "grader", "subgrades" ] ]

        student.submits.each do |submit|
            grade = submit.grade
            if grade.present?
                rows << [
                    pdf_safe(submit.pset&.name),
                    submit.created_at.strftime("%d-%m-%Y %H:%M"),
                    grade.updated_at.strftime("%d-%m-%Y %H:%M"),
                    pdf_safe(helpers.translate_grade(grade.assigned_grade)),
                    pdf_safe(grade.grader_name),
                    pdf_safe(grade.subgrades.to_h.values.join(" / "))
                ]
                if grade.comments.present?
                    rows << [ { content: pdf_safe(grade.comments), colspan: 6 } ]
                end
            else
                rows << [ pdf_safe(submit.pset&.name), submit.created_at.strftime("%d-%m-%Y %H:%M"), { content: "not graded", colspan: 4 } ]
            end
        end

        rows
    end

    #
    # syllabus and announcements, per schedule
    #

    # the syllabus is the page linked to the schedule; Page.syllabus resolves the same
    # thing but only for the currently logged in user, so go through the schedule here
    #
    def syllabus_pdf(schedule)
        page = schedule.page

        pdf_document do |pdf|
            pdf_heading(pdf, "Syllabus", schedule)

            page.subpages.each_with_index do |subpage, index|
                pdf.start_new_page if index > 0
                pdf.text pdf_safe(subpage.title), size: 14, style: :bold
                pdf.move_down 6
                append_markdown(pdf, subpage.content, asset_prefix: page.public_url, trusted: true)
            end
        end
    end

    def announcements_pdf(schedule)
        alerts = Alert.having_schedule_or_nil(schedule).where(published: true)

        pdf_document do |pdf|
            pdf_heading(pdf, "Announcements", schedule)

            if alerts.empty?
                pdf.text "No announcements.", size: 10
            end

            alerts.each do |alert|
                pdf.text alert.created_at.to_fs(:long), size: 8
                pdf.text pdf_safe(alert.title), size: 13, style: :bold
                pdf.move_down 4
                append_markdown(pdf, alert.body)
                pdf.move_down 14
            end
        end
    end

    #
    # pdf plumbing
    #

    # prawn's built-in fonts only cover Windows-1252, and there is no font shipped with
    # the app; transliterate anything else (accents survive, exotic characters become ?)
    #
    def pdf_safe(text)
        text.to_s.encode(
            "Windows-1252",
            fallback: ->(char) { I18n.transliterate(char, replacement: "?") }
        ).encode("UTF-8")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end

    def pdf_document(landscape: false)
        # text is transliterated by pdf_safe, so the warning about the built-in fonts
        # not supporting UTF-8 is only noise
        Prawn::Fonts::AFM.hide_m17n_warning = true

        pdf = Prawn::Document.new(
            page_size: "A4",
            page_layout: landscape ? :landscape : :portrait,
            margin: 36
        )
        yield pdf
        pdf.render
    end

    def pdf_heading(pdf, what, schedule)
        pdf.text pdf_safe("#{what} - #{schedule.name}"), size: 16, style: :bold
        pdf.text pdf_safe("#{Course.long_name} - exported on #{DateTime.now.to_fs(:long)}"), size: 9
        pdf.move_down 12
    end

    # render markdown through the same helper the site uses, then feed the HTML to
    # prawn-html; that has no notion of tables, so tables are pulled out of the flow
    # and drawn with prawn-table instead
    #
    def append_markdown(pdf, markdown, **options)
        html = helpers.render_markdown(markdown.to_s, **options)
        doc = simplify_html(html)

        buffer = []
        append_nodes(pdf, doc.children, buffer)
        flush_html(pdf, buffer)
    rescue => e
        Rails.logger.warn("CourseArchive: falling back to plain text (#{e.class}: #{e.message})")
        pdf.text pdf_safe(markdown), size: 9
    end

    # collect nodes into a buffer of html for prawn-html, interrupting the buffer
    # whenever a table shows up; tables are often wrapped in a div, so descend into
    # any element that contains one
    #
    def append_nodes(pdf, nodes, buffer)
        nodes.each do |node|
            if node.name == "table"
                flush_html(pdf, buffer)
                append_table(pdf, node)
            elsif node.element? && node.css("table").any?
                flush_html(pdf, buffer)
                append_nodes(pdf, node.children, buffer)
            else
                buffer << node
            end
        end
    end

    def flush_html(pdf, buffer)
        html = buffer.map(&:to_html).join
        buffer.clear
        PrawnHtml.append_html(pdf, pdf_safe(html)) if html.strip.present?
    end

    def append_table(pdf, node)
        rows = node.css("tr").map { |tr| tr.css("th, td").map { |cell| pdf_safe(cell.text.squish) } }
        rows.reject!(&:empty?)
        return if rows.empty?

        # prawn-table needs every row to have the same number of columns
        columns = rows.map(&:size).max
        rows.each { |row| row.fill("", row.size...columns) }

        pdf.table(rows, header: node.css("th").any?, width: pdf.bounds.width, cell_style: { size: 8, padding: 3 })
        pdf.move_down 10
    rescue Prawn::Errors::CannotFit, Prawn::Errors::CannotGroup
        pdf.text pdf_safe(rows.map { |row| row.join(" | ") }.join("\n")), size: 8
        pdf.move_down 10
    end

    # prawn-html cannot load remote images and chokes on the markup that katex and
    # coderay produce, so simplify all of that away first
    #
    def simplify_html(html)
        doc = Nokogiri::HTML::DocumentFragment.parse(html)

        doc.css("script, style").each(&:remove)

        doc.css("img").each do |img|
            label = img["alt"].presence || img["src"].presence || "image"
            img.replace("<p>[#{CGI.escapeHTML(label)}]</p>")
        end

        # nested tables cannot be lifted out of the text flow, flatten those to lines
        doc.css("table table").each do |table|
            lines = table.css("tr").map do |tr|
                CGI.escapeHTML(tr.css("th, td").map { |cell| cell.text.squish }.join(" | "))
            end
            table.replace("<p>#{lines.join("<br>")}</p>")
        end

        doc
    end

end
