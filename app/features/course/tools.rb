class Course::Tools

    # Remove any pages that remain without content
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
        if Grading.grades.any?
            Pset.update_all(order: nil)
            counter = 1
            Grading.grades.each do |name, definition|
                p = Pset.where(name: name).first_or_create

                # set order
                p.order = counter
                counter += 1

                # add any info from course.yml to the pset config, which already can contain info from submit.yml
                p.config = (p.config || {}).merge(definition || {})

                # set a few flags from config for easier queries later on
                p.automatic = p.config.present? && p.config["automatic"].present?
                p.grade_type = definition['type'] || :float
                p.test = definition['is_test'] || false
                p.save
            end

            Grading.calculation.each do |name, formula|
                p = Pset.where(name: name).first_or_create
                p.order = counter
                counter += 1
                p.grade_type = :float
                p.save
            end
        end

        # TESTS
        # check if any grades are "tests" (for easy data entry on exams), sets flag
        Settings['tests_present'] = Pset.where(test:true).any?

        # PSET MODULES
        # check all module definitions, connect psets to parent psets
        if Settings['grading'] && Settings['grading']['modules']
            Settings['grading']['modules'].each do |name, psets|
                parent_pset = Pset.where(name: name).first_or_create
                psets.each do |pset_name|
                    pset = Pset.find_by_name(pset_name)
                    pset.update(parent_pset: parent_pset)
                end
            end
        end
    end
end
