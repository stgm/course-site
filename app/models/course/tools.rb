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
        # GRADES
        # checks all grades defined in grading.yml, adds them with config
        if GradingConfig.grades.any?
            Pset.update_all(order: nil)
            counter = 1
            GradingConfig.grades.each do |name, definition|
                p = Pset.where(name: name).first_or_create

                # set order
                p.order = counter
                counter += 1

                # set a few flags from config for easier queries later on
                p.automatic = p.config.present? && p.config["automatic"].present?
                # get potential type from final grade config
                calc_type = GradingConfig.all.
                            select { |k,v| v['submits'] && v['submits'][name] }.
                            map{ |k,v| v['type'] }.compact&.first
                p.grade_type = definition['type'] || calc_type || :float
                p.test = definition['is_test'] || false
                p.save
            end

            GradingConfig.calculation.each do |name, formula|
                p = Pset.where(name: name).first_or_create
                p.order = counter
                counter += 1
                p.grade_type = :float
                p.save
            end
        end

        # TESTS
        # check if any grades are "tests" (for easy data entry on exams), sets flag
        Settings.tests_present = Pset.where(test:true).any?
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
