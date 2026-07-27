# Builds a single zip with everything needed to archive the course:
#
#   grades.xlsx                      all grades, same data as the xlsx export button
#   grades-with-feedback.pdf         per-student grades and feedback, one page per student
#   schedules/<slug>/grades.xlsx     the same two files, but only for this schedule
#   schedules/<slug>/grades-with-feedback.pdf
#   schedules/<slug>/syllabus.pdf    the schedule's syllabus page
#   schedules/<slug>/announcements.pdf
#   schedules/<slug>/final-grades.pdf
#
# Everything is generated synchronously; there is no job runner. Nothing is kept in
# memory as a whole: each document is rendered into its own temp file and copied into
# the archive, which is itself a temp file. Peak memory is one document's worth of
# Prawn/axlsx bookkeeping, not the size of the archive.
#
#   CourseArchive.new.write_to("/tmp/archive.zip")   # from the console
#
class CourseArchive

    # the scopes for the grade exports, shared with Admin::CourseController#export_grades;
    # without a schedule these cover the whole course
    #
    def self.grade_export_scopes(schedule = nil)
        users = User.student.joins(:submits).distinct
        psets = Pset.joins(:submits).distinct.order(:order)
        # all users who ever submitted something, students or not
        students = User.joins(:submits).distinct.order(:name)

        if schedule
            users = users.where(schedule: schedule)
            psets = psets.where(submits: { user_id: schedule.users })
            students = students.where(schedule: schedule)
        end

        [ users, psets, students ]
    end

    # the name the download is offered under, based on the course's short name
    #
    def self.filename
        course = Course.short_name.to_s.parameterize(preserve_case: true).presence || "course"
        "#{course}-archives-#{Date.current.iso8601}.zip"
    end

    # Returns the archive as a closed Tempfile. In a request, hand it to Rack so it is
    # cleaned up once the response has been sent (see Admin::CourseController#archive).
    #
    def to_tempfile
        with_locale do
            ZipWriter.to_tempfile(basename: "course-archive") { |zip| add_entries(zip) }
        end
    end

    # Writes the archive to a path of your choosing; convenient from the console.
    #
    def write_to(path)
        with_locale { Zip::OutputStream.open(path) { |zip| add_entries(zip) } }
        path
    end

    private

    # the request already sets the locale, but the archive is also generated from
    # the console every now and then
    #
    def with_locale(&block)
        I18n.with_locale(Course.language || I18n.default_locale, &block)
    end

    def add_entries(zip)
        add_entry(zip, "grades.xlsx") { |io| grades_xlsx(io) }
        add_entry(zip, "grades-with-feedback.pdf") { |io| grades_overview_pdf(io) }

        Schedule.order(:name).each do |schedule|
            dir = "schedules/#{schedule.slug}"
            add_entry(zip, "#{dir}/grades.xlsx") { |io| grades_xlsx(io, schedule) }
            add_entry(zip, "#{dir}/grades-with-feedback.pdf") { |io| grades_overview_pdf(io, schedule) }
            if schedule.page.present?
                add_entry(zip, "#{dir}/syllabus.pdf") { |io| syllabus_pdf(io, schedule) }
            end
            add_entry(zip, "#{dir}/announcements.pdf") { |io| announcements_pdf(io, schedule) }
            add_entry(zip, "#{dir}/final-grades.pdf") { |io| final_grades_pdf(io, schedule) }
        end
    end

    def helpers
        @helpers ||= ApplicationController.helpers
    end

    def t(key, **options)
        I18n.t(key, **options)
    end

    def export_date
        I18n.l(Time.current, format: :long)
    end

    # write one entry, but never let a single broken page kill the whole download:
    # on failure the zip gets an error note in place of the file
    #
    # the document is generated into a scratch file first, so that a generator that
    # fails halfway has not already written a truncated entry into the archive
    #
    def add_entry(zip, filename)
        Tempfile.create([ "archive-entry", File.extname(filename) ], binmode: true) do |scratch|
            yield scratch
            scratch.rewind
            zip.put_next_entry(filename)
            IO.copy_stream(scratch, zip)
        end
    rescue => e
        Rails.logger.error("CourseArchive: could not generate #{filename}: #{e.class}: #{e.message}")
        zip.put_next_entry("#{filename}.ERROR.txt")
        zip.write("Could not generate #{filename}\n\n#{e.class}: #{e.message}\n\n#{e.backtrace&.first(20)&.join("\n")}\n")
    end

    #
    # grades
    #

    # caxlsx_rails always hands back a String, so this one entry is still built in
    # memory; it is by far the smallest of the documents here
    #
    def grades_xlsx(io, schedule = nil)
        users, psets, students = self.class.grade_export_scopes(schedule)
        io.write(ApplicationController.render(
            template: "admin/course/export_grades",
            formats: [ :xlsx ],
            assigns: { users: users, psets: psets, students: students, title: "Export grades" }
        ))
    end

    # the PDF equivalent of admin/course/export_grades.html.erb: a page per student
    # with all their submits and grades
    #
    def grades_overview_pdf(io, schedule = nil)
        _users, _psets, students = self.class.grade_export_scopes(schedule)

        pdf_document(io, landscape: true) do |pdf|
            title = t("archive.grades.title")
            title = "#{title} - #{schedule.name}" if schedule
            pdf.text pdf_safe(title), size: 18, style: :bold
            pdf.text pdf_safe(Course.long_name), size: 11
            pdf.text pdf_safe(t("archive.exported_on", date: export_date).upcase_first), size: 11
            pdf.move_down 10

            pdf.text pdf_safe(t("archive.grades.no_students")), size: 10 if students.empty?

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
                    pdf.text pdf_safe(t("archive.grades.no_submits")), size: 8
                end
            end
        end
    end

    def grade_rows(student)
        rows = [ %w[pset submitted graded grade grader subgrades].map { |key| pdf_safe(t("archive.grades.header.#{key}")) } ]

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
                rows << [
                    pdf_safe(submit.pset&.name),
                    submit.created_at.strftime("%d-%m-%Y %H:%M"),
                    { content: pdf_safe(t("archive.grades.not_graded")), colspan: 4 }
                ]
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
    def syllabus_pdf(io, schedule)
        page = schedule.page

        pdf_document(io) do |pdf|
            pdf_heading(pdf, t(:syllabus), schedule)

            page.subpages.each_with_index do |subpage, index|
                pdf.start_new_page if index > 0
                pdf.text pdf_safe(subpage.title), size: 14, style: :bold
                pdf.move_down 6
                append_markdown(pdf, subpage.content, asset_prefix: page.public_url, trusted: true)
            end
        end
    end

    def announcements_pdf(io, schedule)
        alerts = Alert.having_schedule_or_nil(schedule).where(published: true)

        pdf_document(io) do |pdf|
            pdf_heading(pdf, t(:announcements), schedule)

            if alerts.empty?
                pdf.text pdf_safe(t("archive.announcements.none")), size: 10
            end

            alerts.each do |alert|
                pdf.text pdf_safe(I18n.l(alert.created_at, format: :long)), size: 8
                pdf.text pdf_safe(alert.title), size: 13, style: :bold
                pdf.move_down 4
                append_markdown(pdf, alert.body)
                pdf.move_down 14
            end
        end
    end

    #
    # final grade calculation
    #

    # explains, in prose and tables, how every final grade of this schedule is
    # calculated, so that an exam committee can follow it without reading grading.yml
    #
    def final_grades_pdf(io, schedule)
        config = schedule.grading_config

        pdf_document(io) do |pdf|
            pdf_heading(pdf, t("archive.final_grades.title"), schedule)

            if config.calculation.blank?
                pdf.text pdf_safe(t("archive.final_grades.none")), size: 10
                next
            end

            pdf.text pdf_safe(t("archive.final_grades.intro")), size: 10
            pdf.move_down 14

            # every component is only transcribed once; later final grades refer back to
            # the first one, because a resit usually repeats most of it
            described = []
            reference = nil

            config.calculation.each do |final_name, components|
                describe_final_grade(pdf, config, final_name, components, reference, described)
                reference ||= [ final_name, components ]
            end

            describe_rounding(pdf)
            describe_assignment_grades(pdf, config)
        end
    end

    def describe_final_grade(pdf, config, final_name, components, reference, described)
        pdf.text pdf_safe(t("archive.final_grades.heading", name: final_name)), size: 14, style: :bold
        pdf.move_down 4

        if reference && reference.last == components
            pdf.text pdf_safe(t("archive.final_grades.same_as", name: reference.first)), size: 10
            pdf.move_down 14
            return
        end

        pdf.text pdf_safe(t("archive.final_grades.weighted_average")), size: 10
        pdf.move_down 6

        rows = [ %w[component weight based_on].map { |key| pdf_safe(t("archive.final_grades.header.#{key}")) } ]
        components.each do |component_name, weight|
            component = config.components[component_name]
            rows << [
                pdf_safe(component_name),
                weight.to_s,
                pdf_safe(component ? component["submits"].keys.join(", ") : t("archive.final_grades.not_defined"))
            ]
        end
        pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 8, padding: 4 }) do
            row(0).font_style = :bold
        end
        pdf.move_down 10

        differences = reference ? component_differences(reference.last, components) : []
        if differences.any?
            pdf.text pdf_safe(t("archive.final_grades.compared_to",
                name: reference.first, differences: differences.join("; "))), size: 10
            pdf.move_down 4
        end

        repeated = components.keys.select { |name| described.include?(name) }
        if repeated.any?
            pdf.text pdf_safe(t("archive.final_grades.not_repeated", names: repeated.join(", "))),
                size: 9, style: :italic
            pdf.move_down 8
        end

        components.each_key do |component_name|
            next if described.include?(component_name)
            describe_component(pdf, config, component_name)
            described << component_name
        end
        pdf.move_down 6
    end

    # what sets this final grade apart from the one described earlier
    #
    def component_differences(reference, components)
        differences = []

        (components.keys - reference.keys).each do |name|
            differences << t("archive.final_grades.difference.used_instead", name: name, weight: components[name])
        end
        (reference.keys - components.keys).each do |name|
            differences << t("archive.final_grades.difference.not_used", name: name)
        end
        (components.keys & reference.keys).each do |name|
            next if components[name] == reference[name]
            differences << t("archive.final_grades.difference.other_weight",
                name: name, weight: components[name], previous: reference[name])
        end

        differences
    end

    # the three strategies of User::FinalGradeCalculator, in words
    #
    def component_strategy(component)
        strategy = component&.[]("type")
        strategy = "average" unless strategy.in?([ "points", "maximum" ])
        t("archive.final_grades.strategy.#{strategy}")
    end

    def describe_component(pdf, config, component_name)
        component = config.components[component_name]
        if component.blank?
            pdf.text pdf_safe(t("archive.final_grades.component_undefined", name: component_name)),
                size: 9, style: :italic
            return
        end

        pdf.text pdf_safe(t("archive.final_grades.component_heading", name: component_name)), size: 11, style: :bold
        pdf.move_down 3
        pdf.text pdf_safe(t("archive.final_grades.component_is", strategy: component_strategy(component))), size: 9

        rules = component_rules(component)
        if rules.any?
            pdf.move_down 3
            rules.each { |rule| pdf.text pdf_safe("- #{rule}"), size: 9 }
        end
        pdf.move_down 5

        label = component["type"] == "points" ? "points_available" : "weight"
        rows = [ [
            pdf_safe(t("archive.final_grades.header.assignment")),
            pdf_safe(t("archive.final_grades.header.#{label}"))
        ] ]
        component["submits"].each { |name, weight| rows << [ pdf_safe(name), weight.to_s ] }
        component["bonus"]&.each do |name, weight|
            rows << [ pdf_safe(t("archive.final_grades.bonus_label", name: name)), weight.to_s ]
        end

        pdf.table(rows, header: true, width: pdf.bounds.width / 2, cell_style: { size: 8, padding: 3 }) do
            row(0).font_style = :bold
        end
        pdf.move_down 10
    end

    # the exceptions and extra conditions that User::FinalGradeCalculator applies
    #
    def component_rules(component)
        rules = []
        rules << rule(:minimum, minimum: component["minimum"]) if component["minimum"]
        rules << rule(:maximum, maximum: component["maximum"]) if component["maximum"]
        rules << rule(:attempt_required) if component["attempt_required"]
        rules << rule(:fill_missing, value: component["fill_missing"]) if component["fill_missing"].present?
        rules << rule(:missing_cancels) if !component["fill_missing"].present? && component["type"].blank?
        rules << rule(:required) if component["required"]
        rules << rule(:drop_lowest) if component["drop"].to_s == "lowest"
        rules << rule(:bonus) if component["bonus"].present?
        rules << rule(:zero_weight_required) if component["type"] == "points" && component["submits"].value?(0)
        rules << rule(:deadline, deadline: component["deadline"]) if component["deadline"].present?
        rules
    end

    def rule(name, **options)
        t("archive.final_grades.rule.#{name}", **options)
    end

    def describe_rounding(pdf)
        pdf.text pdf_safe(t("archive.final_grades.rounding.title")), size: 14, style: :bold
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.rounding.intro")), size: 10
        pdf.move_down 3
        t("archive.final_grades.rounding.rules").each { |line| pdf.text pdf_safe("- #{line}"), size: 9 }
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.rounding.note")), size: 9
        pdf.move_down 14
    end

    # how the grade of a single assignment comes about, from its subgrades
    #
    def describe_assignment_grades(pdf, config)
        assignments = config.calculation.values.flat_map do |components|
            components.keys.flat_map { |name| config.components[name]&.dig("submits")&.keys || [] }
        end.uniq

        return if assignments.empty?

        pdf.start_new_page unless pdf.cursor == pdf.bounds.top
        pdf.text pdf_safe(t("archive.final_grades.assignments.title")), size: 14, style: :bold
        pdf.move_down 4
        pdf.text pdf_safe(t("archive.final_grades.assignments.intro")), size: 10
        pdf.move_down 6

        rows = [ %w[assignment type parts formula].map { |key| pdf_safe(t("archive.final_grades.header.#{key}")) } ]
        assignments.each do |name|
            grade_config = config.grades[name] || {}
            automatic = grade_config["automatic"].to_h.keys
            parts = grade_config["subgrades"].to_h.keys.map do |part|
                automatic.include?(part) ? t("archive.final_grades.assignments.automatic", name: part) : part
            end
            rows << [
                pdf_safe(name),
                pdf_safe(grade_config["type"] || "float"),
                pdf_safe(parts.join(", ")),
                pdf_safe(grade_config["calculation"])
            ]
        end

        pdf.table(rows, header: true, width: pdf.bounds.width, cell_style: { size: 8, padding: 3 }) do
            row(0).font_style = :bold
        end
        pdf.move_down 8
        pdf.text pdf_safe(t("archive.final_grades.assignments.note")), size: 9
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

    # renders straight into the given IO, so the finished PDF is never also held as a
    # String; prawn still keeps the document itself in memory until it is rendered
    #
    def pdf_document(io, landscape: false)
        # text is transliterated by pdf_safe, so the warning about the built-in fonts
        # not supporting UTF-8 is only noise
        Prawn::Fonts::AFM.hide_m17n_warning = true

        pdf = Prawn::Document.new(
            page_size: "A4",
            page_layout: landscape ? :landscape : :portrait,
            margin: 36
        )
        yield pdf
        pdf.render(io)
    end

    def pdf_heading(pdf, what, schedule)
        pdf.text pdf_safe("#{what} - #{schedule.name}"), size: 16, style: :bold
        pdf.text pdf_safe("#{Course.long_name} - #{t('archive.exported_on', date: export_date)}"), size: 9
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

        # kramdown wraps the items of a "loose" list (items separated by blank lines) in
        # paragraphs; prawn-html then puts the bullet and the text on separate lines, so
        # unwrap the paragraph that opens a list item
        doc.css("li > p:first-child").each { |paragraph| paragraph.replace(paragraph.inner_html) }

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
