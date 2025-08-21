module Submit::AutoCheck::Receiver

    extend ActiveSupport::Concern

    # Saves incoming check results.
    # Takes the "result" object returned by the check server and stores it raw.
    # Other functions will then analyze the object.
    def register_auto_check_results(json)
        # save the raw results
        self.check_token = nil
        self.check_results = json

        create_auto_grade
        self.save
    end

    def create_auto_grade(send_mail = true)
        if self.grading_config["auto_publish"]
            # create a create if needed
            grade = self.grade || self.build_grade

            # overwrite previous automatic scores
            self.automatic_scores.each do |k, v|
                grade.subgrades[k] = v
            end

            # immediately try calculating the grade and publishing
            grade.set_calculated_grade
            grade.status = Grade.statuses[:published]
            grade.grader = User.admin.first
            grade.save

            # if the results do not appear OK, send an e-mail
            if send_mail && grade.calculated_grade == 0
                GradeMailer.bad_submit(self).deliver
            end
        end
    end

end
