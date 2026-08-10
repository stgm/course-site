require 'test_helper'
require_relative '../support/zip_inspection'

class CourseArchiveTest < ActiveSupport::TestCase

    include ZipInspection

    def entries(path)
        Zip::File.open(path) { |zip| zip.to_h { |e| [ e.name, e.get_input_stream.read ] } }
    end

    test "replaces a failed entry with an error note and keeps writing" do
        archive = CourseArchive.new

        file = ZipWriter.to_tempfile(basename: "archive-test") do |zip|
            archive.send(:add_entry, zip, "broken.pdf") { raise "boom" }
            archive.send(:add_entry, zip, "fine.txt") { |io| io.write("still here") }
        end

        written = entries(file.path)
        assert_equal [ "broken.pdf.ERROR.txt", "fine.txt" ], written.keys.sort
        assert_includes written["broken.pdf.ERROR.txt"], "Could not generate broken.pdf"
        assert_equal "still here", written["fine.txt"],
            "an entry after a failed one must still be written"

        assert_readable_by_unzip(file.path)
        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

    # the pass/fail strategies have their own prose, columns and rules in the grade
    # calculation PDF, none of which is reached by the archive as a whole when no
    # final grades are configured
    test "describes a pass/fail final grade" do
        Settings.grading = {
            "grades" => { "check_1" => { "type" => "pass" }, "exam_1" => { "type" => "pass" } },
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "exams"  => { "type" => "pass_any", "submits" => [ "exam_1", "exam_2" ] },
            "calculation" => {
                "final" => { "type" => "pass", "components" => [ "checks", "exams" ] }
            }
        }
        schedule = Schedule.create!(name: "Pass Fail")

        io = StringIO.new
        I18n.with_locale(:en) { CourseArchive.new.send(:final_grades_pdf, io, schedule) }

        assert_operator io.string.bytesize, :>, 0
        assert io.string.start_with?("%PDF"), "expected a PDF document"
    end

    # the registration system takes codes, not grades: AVV for a passed final grade,
    # NAV for a failed one
    test "exports a passed final grade as AVV" do
        pset = Pset.create!(name: "sp1", final: true, config: { "type" => "pass" })
        student = users(:test_user)
        # a submit resolves its grading config through the user's schedule, and the
        # export only lists students (fixtures leave the role column null)
        student.update!(role: :student, schedule: Schedule.create!(name: "Export"))
        submit = student.submits.create!(pset: pset)
        grade = submit.create_grade!(grader: student, status: :published)
        # the setter reads the type off the submit, so the grade needs its submit first
        grade.update!(grade: -1)

        io = StringIO.new
        CourseArchive.new.send(:grades_xlsx, io)
        sheet = nil
        Zip::File.open_buffer(io.string) { |zip| sheet = zip.read("xl/worksheets/sheet1.xml") }

        assert_includes sheet, "AVV"
    end

    test "builds a readable archive" do
        file = CourseArchive.new.to_tempfile

        assert_includes entries(file.path).keys, "grades.xlsx"
        assert_readable_by_unzip(file.path)
        assert_not_zip64(file.path)
    ensure
        file&.close!
    end

end
