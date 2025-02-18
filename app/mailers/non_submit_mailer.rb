class NonSubmitMailer < ApplicationMailer

    def new_mail(user, pset, notice)
        grade_name = pset.name
        login = user.defacto_student_identifier
        mail(
            to: user.mail,
            subject: "#{Course.short_name}: submit #{grade_name}!",
            body: "#{notice}\n\n\n#{login}"
        )
    end

end
