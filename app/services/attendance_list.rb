# Renders the attendance list ("presentielijst") that is signed during an exam.
#
# One A4 portrait page holds two blocks of students side by side. Each block
# has three columns: name with student ID, number of pages and hand-in time.
# The two blocks are drawn as one table, so the page reads as a single grid.
# The tuning constants below control how much room each part gets.
class AttendanceList
    include PdfText

    MARGIN = 34
    ROW_HEIGHT = 25        # height of one student row, in points
    HEADER_ROW_HEIGHT = 26
    BLOCK_GAP = 14         # blank column between the two blocks
    COLUMN_RATIOS = [ 0.575, 0.205, 0.22 ].freeze  # name, pages, hand-in time
    NAME_SIZE = 8.5
    ID_SIZE = 7.5
    HEAD_SIZE = 7.5
    CELL_PADDING = [ 2, 5, 4, 5 ].freeze  # top, right, bottom, left
    LETTER_WIDTH = 7          # width of the status letter; its right edge sits at the cell padding
    DATE_BOX_WIDTH = 156
    DATE_BOX_HEIGHT = 34
    FIELD_LABEL_WIDTH = 110   # width of the label before the date/staff lines
    LEGEND_SPACING = 24       # vertical space between the staff line and the legend
    FIELD_SPACING = 22        # vertical space between the date/staff lines

    INK = "222222"
    MUTED = "777777"
    LINE = "BBBBBB"
    HEAD_FILL = "E4E8EE"

    TEXT = {
        en: {
            title: "Exam attendance list",
            university: "University of Amsterdam",
            date: "Date",
            staff: "Attending staff",
            name: "Name / student ID",
            pages: "# pages",
            handed_in: "Hand-in time",
            page: "Page",
            legend: "Status letter after a name:",
            status: { "registered" => "R", "inactive" => "I", "done" => "D" },
            status_names: { "registered" => "registered", "inactive" => "inactive", "done" => "done" }
        },
        nl: {
            title: "Presentielijst tentamen",
            university: "Universiteit van Amsterdam",
            date: "Datum",
            staff: "Aanwezige docenten",
            name: "Naam / studentnummer",
            pages: "# pagina's",
            handed_in: "Inlevertijd",
            page: "Pagina",
            legend: "Letter achter naam:",
            status: { "registered" => "R", "inactive" => "I", "done" => "D" },
            status_names: { "registered" => "registered", "inactive" => "inactive", "done" => "done" }
        }
    }.freeze

    def initialize(schedule, course_name: Course.long_name, language: Course.language)
        @schedule = schedule
        @course_name = course_name
        @text = TEXT[language.to_s.downcase.start_with?("nl") ? :nl : :en]
        @students = schedule.students.includes(:logins).to_a
            .sort_by { |student| student.name.to_s.downcase }
    end

    # Returns the finished PDF as a string.
    def render
        Prawn::Fonts::AFM.hide_m17n_warning = true

        pdf = Prawn::Document.new(page_size: "A4", margin: MARGIN,
                            info: { Title: pdf_safe("#{@text[:title]} #{@schedule.name}") })
        draw_header(pdf)
        draw_students(pdf)
        draw_page_numbers(pdf)
        pdf.render
    end

    private

    def draw_header(pdf)
        draw_date_box(pdf)

        pdf.fill_color INK
        pdf.text pdf_safe(@text[:title]), size: 20, style: :bold, width: pdf.bounds.width - DATE_BOX_WIDTH - 12
        pdf.move_down 4
        pdf.text pdf_safe("#{@text[:university]}  |  #{@course_name}  |  #{@schedule.name}"),
            size: 9.5, color: MUTED, width: pdf.bounds.width - DATE_BOX_WIDTH - 12
        pdf.move_down 20

        draw_field(pdf, @text[:staff])
        pdf.move_down LEGEND_SPACING
        draw_legend(pdf)
    end

    # Draws an empty box in the top right corner to write the date in.
    def draw_date_box(pdf)
        left = pdf.bounds.right - DATE_BOX_WIDTH
        top = pdf.cursor
        pdf.stroke_color LINE
        pdf.line_width 0.7
        pdf.stroke_rounded_rectangle [ left, top ], DATE_BOX_WIDTH, DATE_BOX_HEIGHT, 3
        pdf.fill_color MUTED
        pdf.text_box pdf_safe(@text[:date]), at: [ left + 6, top - 5 ], width: DATE_BOX_WIDTH - 12,
            height: 10, size: 7.5
    end

    # Explains the status letters that follow some names.
    def draw_legend(pdf)
        items = @text[:status].map { |status, letter| "#{letter} = #{@text[:status_names][status]}" }
        pdf.fill_color MUTED
        pdf.text pdf_safe("#{@text[:legend]} #{items.join(', ')}"), size: 7.5
        pdf.move_down 3
    end

    # Prints a label with a line after it to write on.
    def draw_field(pdf, label)
        pdf.fill_color INK
        pdf.text_box pdf_safe(label), at: [ 0, pdf.cursor ], width: FIELD_LABEL_WIDTH, height: 12, size: 10
        pdf.stroke_color LINE
        pdf.line_width 0.7
        pdf.stroke_horizontal_line FIELD_LABEL_WIDTH, pdf.bounds.width, at: pdf.cursor - 11
    end

    def draw_students(pdf)
        pages = paginate(pdf)
        pages.each_with_index do |(students, capacity), index|
            pdf.start_new_page if index > 0
            draw_table(pdf, students, capacity)
        end
    end

    # Splits the students over pages. Returns a list of [students, rows per block].
    def paginate(pdf)
        first = rows_that_fit(pdf.cursor)
        later = rows_that_fit(pdf.bounds.height)
        pages = []
        remaining = @students.dup
        capacity = first
        loop do
            pages << [ remaining.shift(capacity * 2), capacity ]
            break if remaining.empty?
            capacity = later
        end
        pages
    end

    def rows_that_fit(height)
        [ ((height - HEADER_ROW_HEIGHT - 20) / ROW_HEIGHT).floor, 1 ].max
    end

    # Draws one page of students as a single table with two blocks, adding
    # empty rows until the blocks are `capacity` rows tall.
    def draw_table(pdf, students, capacity)
        per_block = (students.size / 2.0).ceil
        left = students.first(per_block)
        right = students.drop(per_block)

        rows = [ header_row + [ "" ] + header_row ]
        marks = {}
        capacity.times do |i|
            rows << student_cells(left[i]) + [ "" ] + student_cells(right[i])
            marks[[ i + 1, 0 ]] = status_letter(left[i])
            marks[[ i + 1, 4 ]] = status_letter(right[i])
        end

        widths = block_widths(pdf)
        column_widths = widths + [ BLOCK_GAP ] + widths
        pdf.fill_color INK
        table = pdf.make_table(rows, header: true, column_widths: column_widths,
                cell_style: { size: NAME_SIZE, padding: CELL_PADDING, border_color: LINE,
                              border_width: 0.5, height: ROW_HEIGHT, valign: :top,
                              inline_format: true }) do |table|
            style_table(table)
        end
        origin_y = pdf.cursor
        table.draw
        draw_status_letters(pdf, table, marks, origin_y)
    end

    # Prints each status letter in the top right corner of the name cell.
    def draw_status_letters(pdf, table, marks, origin_y)
        pdf.fill_color MUTED
        marks.each do |(row, col), letter|
            next if letter.nil?
            cell = table.cells[row, col]
            pdf.text_box letter, at: [ cell.x + cell.width - CELL_PADDING[1] - LETTER_WIDTH, origin_y + cell.y - CELL_PADDING[0] - 2 ],
                width: LETTER_WIDTH, height: 10, size: NAME_SIZE, style: :bold, align: :center
        end
    end

    def status_letter(student)
        student && @text[:status][student.status]
    end

    def style_table(table)
        table.row(0).font_style = :bold
        table.row(0).size = HEAD_SIZE
        table.row(0).background_color = HEAD_FILL
        table.row(0).height = HEADER_ROW_HEIGHT
        # the gap column has no borders and no fill
        table.columns(3).borders = []
        table.columns(3).background_color = "FFFFFF"
        table.columns([ 1, 2, 4, 5 ]).align = :left
    end

    def block_widths(pdf)
        block = (pdf.bounds.width - BLOCK_GAP) / 2
        COLUMN_RATIOS.map { |ratio| block * ratio }
    end

    def header_row
        [ pdf_safe(@text[:name]), pdf_safe(@text[:pages]), pdf_safe(@text[:handed_in]) ]
    end

    def student_cells(student)
        return [ "", "", "" ] if student.nil?

        name = "<font size='#{NAME_SIZE}'>#{escape(pdf_safe(student.name))}</font>"
        id = "<font size='#{ID_SIZE}' name='Helvetica'><color rgb='#{MUTED}'>#{escape(pdf_safe(student.defacto_student_identifier))}</color></font>"
        [ "#{name}\n#{id}", "", "" ]
    end

    def escape(text)
        text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end

    def draw_page_numbers(pdf)
        pdf.number_pages "#{@text[:page]} <page> / <total>", at: [ pdf.bounds.right - 100, -14 ],
            width: 100, align: :right, size: 7, color: MUTED
    end

end
