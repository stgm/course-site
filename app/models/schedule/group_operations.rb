# Import and generate group assignments for a schedule.
module Schedule::GroupOperations
    extend ActiveSupport::Concern

    def add_group(name)
        self.groups.create(name: name)
    end

    # Generate a number of groups for this schedule and randomly assign students.
    def generate_groups(number)
        # delete old groups for this schedule
        self.groups.delete_all

        # create the requested number of groups
        for n in 0..number-1
            self.groups.create(name: "#{self.name} #{(n+65).chr}")
        end

        # randomize students
        students = self.users.student.shuffle

        # get the new groups
        groups = self.groups.to_a

        # divide students into groups and assign their group each
        students.in_groups(number).each do |student_group|
            User.where("id in (?)", student_group).update_all(group_id: groups.pop.id)
        end
    end

    # Propose group assignments from a TSV paste.
    def propose_groups(paste)
        extract_user_info(paste)
    end

    # Import group assignments from a TSV paste, creating groups when necessary.
    def import_groups(paste)
        # delete all groups that are not in use by assistants
        self.groups.where.not(id: Group.joins(:users).where("users.id": User.staff)).delete_all

        extract_user_info(paste).each do |user_info|
            if !user_info[1].blank?
                group = Group.where(:name => user_info[1], schedule_id: self.id).first_or_create
            else
                group = nil
            end

            user_info[0].each do |user_id|
                import_user(user_id, group, user_info[2], user_info[3])
            end
        end
    end

    private

    def extract_user_info(paste)
        result = []
        paste.each_line do |line|
            # skip or split line
            next if line.strip == ""
            line = line.split("\t").map(&:strip)

            # decide on column contents
            unless @group_column
                down_line = line.map(&:downcase)
                @group_column = down_line.index('group') || 10
                @name_columns = down_line.index('name') && [down_line.index('name')] || [4, 3, 2]
                @email_column = down_line.index('mail') || down_line.index('mail') || 5
                @id_columns = down_line.index('id') && [down_line.index('id')] || [0, 1]

                # if this line did actually contain column headers it's time to skip to the next one
                next if down_line.index('group')
            end

            # extract info
            user_id = line.values_at(*@id_columns).uniq#.join(',')
            group_name = line[@group_column]
            group_name = nil if group_name.blank? || group_name.downcase == 'no group'
            user_name = line.values_at(*@name_columns).join(' ')
            user_mail = line[@email_column]

            # add to final result
            result << [user_id, group_name, user_name, user_mail]
        end
        return result
    end

    def import_user(user_id, group, user_name, user_mail)
        if login = Login.where(login: user_id).first
            if user = login.user
                if user.schedule_id == self.id
                    user.update_columns(name: user_name, mail: user_mail) if user.name.blank? or user.name =~ /,/
                    user.group = group
                    user.save
                end
            end
        end
    end
end
