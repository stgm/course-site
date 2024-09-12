class Course::Tools
    # Removes any pages that remain without content
    #
    def self.prune_empty_pages
        # find all pages having no subpages
        to_delete = Page.includes(:subpages).where(:subpages => { :id => nil }).pluck(:id)

        # remove those pages and disassociate any related psets
        Page.where("id in (?)", to_delete).destroy_all
    end

    # Walks all psets named in course.yml and ranks them in the database
    #
    def self.clean_psets
        Pset.update_all(order: nil)
        counter = 1

        config = GradingConfig.base
        config.grades.each do |name, definition|
            self.register_grade(name, counter)
            counter += 1
        end
        config.calculation.each do |name, formula|
            self.register_final_grade(name, counter)
            counter += 1
        end

        Schedule.all.map(&:name).each do |schedule_name|
            schedule_config = GradingConfig.with_schedule(schedule_name)
            schedule_config.grades.each do |name, definition|
                self.register_grade(name, counter)
                counter += 1
            end
            schedule_config.calculation.each do |name, formula|
                self.register_final_grade(name, counter)
                counter += 1
            end
        end
    end

    def self.register_grade(name, order)
        p = Pset.where(name: name).first_or_create
        p.order = order
        p.automatic = p.config.present? && p.config["automatic"].present?
        p.save

        # create or delete associated exam record if config has { exam: true }
        if p.config.present? && p.config["exam"].present?
            exam = Exam.find_or_initialize_by(pset: p)
            if p.config["files"].present?
                # convert submit.yml files to what's needed for exam config storage
                exam.config = { "files" => p.config["files"]["required"].collect{|k,v| { 'name' => k, 'template' => v } } }
            end
            exam.save
        else
            Exam.find_by(pset: p)&.destroy!
        end
    end

    def self.register_final_grade(name, order)
        p = Pset.where(name: name).first_or_create
        p.order = order
        p.final = true
        p.config = { 'type' => 'float' }
        p.save
    end

    # Generate a tree of (nested) sections and pages
    #
    def self.regenerate_page_tree
        ps = Page.all
        res = {}

        ps.each do |p|
            hash = hashify_path(p.slug.split('/'), p.slug, p.title)
            res.deep_merge! hash unless p.slug.blank?
        end

        Settings.page_tree = res
    end

    # Generate nested hash for array of path segments
    #
    def self.hashify_path(path, full, title)
        first, *rest = path
        if rest.empty?
            # leaf node
            entry = { title => full }
        else
            entry = { first => hashify_path(rest, full, title) }
        end
        entry
    end
end
