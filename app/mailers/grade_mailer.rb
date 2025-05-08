class GradeMailer < ApplicationMailer

    helper GradesHelper

    def new_mail(grade)
        @course_name = Course.short_name
        @grade_name = grade.pset.name
        @feedback = grade.comments
        if grade.grading_config["hide_calculated"]
            @grade = grade.assigned_grade
        else
            @grade = grade.grade
        end
        @login = grade.submit.used_login if grade.submit
        @header = File.read("#{Rails.root}/public/course/mail/grade.txt") if File.exist?("#{Rails.root}/public/course/mail/grade.txt")
        mail(to: grade.user.mail, subject: "#{Course.short_name}: feedback for #{@grade_name}")
    end

    def bad_submit(submit)
        @course_name = Course.short_name
        @grade_name = submit.pset_name
        @login = submit.used_login
        mail(to: submit.user.mail, subject: "#{@course_name}: failed check for #{@grade_name}")
    end

    def self.periodic_round
        if self.available?
            Grade.where("grades.mailed_at is null").published.where("grades.updated_at > ?", 1.day.ago).where("grades.updated_at < ?", 2.hours.ago).joins([ :submit ]).find_each do |g|
                if g.comments.present?
                    GradeMailer.new_mail(g).deliver
                    ActiveRecord::Base.transaction do
                        g.touch(:mailed_at)
                    end
                end
            end
        end
    end

    def self.available?
        Settings.send_grade_mails && super
    end

end
