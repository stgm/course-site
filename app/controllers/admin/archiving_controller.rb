class Admin::ArchivingController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin

    layout "modal"

    def index
    end

    #
    # export all course grades in XLSX or HTML format (archiving)
    #
    def export_grades
        @users, @psets, @students = CourseArchive.grade_export_scopes
        @title = "Export grades"

        respond_to do |format|
            format.xlsx
            format.html { render layout: false }
        end
    end

    #
    # download a single zip with everything needed to archive the course:
    # grades (xlsx + pdf) and a syllabus and announcements pdf per schedule
    #
    def archive
        file = CourseArchive.new.to_tempfile

        # Rack::TempfileReaper unlinks this once the response has been sent
        (request.env["rack.tempfiles"] ||= []) << file

        send_file file.path,
            type: "application/zip",
            filename: CourseArchive.filename,
            disposition: "attachment"
    end

end
