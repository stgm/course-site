class Course::Loader

    # This class is responsible for importing course information from
    # the source into the database.

    COURSE_DIR = "public/course"

    def initialize
        @errors = []
        @touched_subpages = []
    end

    # Re-read the course contents from the git repository.
    def run
        begin
            repo_dir = '.'
            git = Course::Git.new(COURSE_DIR, repo_dir)

            # if not git.update!
            #     @errors << "Repo #{repo_dir} could not be updated. You can simply try again."
            #     return
            # end

            if Settings.git_version
                previous_version = Settings.git_version
            else
                # set to git magic root hash to get all changes, ever
                previous_version = '4b825dc642cb6eb9a060e54bf8d69288fbee4904' 
                Subpage.delete_all
            end

            git.changes_since(previous_version).each do |change|
                if change.extension.in? ['.md', '.adoc', '.ipynb']
                    load_content change
                else
                    puts "Trying #{change.filename.inspect}"
                    case change.filename
                    # when 'course.yml'
                    #     load_course_info change
                    # when 'grading.yml'
                    #     load_grading_info change
                    when 'schedule.yml'
                        puts change.inspect
                        load_schedule change
                    # when 'module.yml'
                    #     load_module change
                    # when 'submit.yml'
                    #     load_submit change
                    end
                end
            end
            
            Settings.git_version = git.current_version

            # Settings.page_tree = traverse(Pathname.new('.'), '')

            # remove old stuff
            prune_empty

            # put psets in order
            # order_psets
            # Course::Tools.clean_psets

            # update
            # User.touch_all
        rescue SQLite3::BusyException
            @errors << "A timeout occurred while loading the new course content. Just try again!"
        end

        return @errors, @touched_subpages
    end

    private

    def load_content(file)
        puts "Loading #{file.inspect}"

        page = get_page(file)
        subpage = page.subpages.find_or_initialize_by(slug: file.slug)

        if file.change_type == 'D'
            # content was deleted
            subpage.destroy
        else
            # content was added or modified
            title = extract_title(file)
            content = case file.extension
            when '.md'
                file.read
            when '.adoc'
                document = Asciidoctor.load(file,
                    safe: :safe,
                    attributes: {
                        'showtitle' => true,
                        'imagesdir' => page.public_url,
                        'skip-front-matter' => true,
                        'stem' => true
                    })
                html = document.convert
            when '.ipynb'
                GradingHelper::NBConverter.new(file).run
            end

            subpage.position = file.position
            subpage.content = content
            # subpage.description = file.front_matter['description']
            subpage.save
            @touched_subpages << subpage.id
        end
    end

    def get_page(file)
        page = Page.find_or_initialize_by(slug: file.parent_slug)
        page.title = file.parent_title
        page.slug = file.parent_slug
        page.path = file.parent_path
        page.position = file.position
        page.save
        puts page.inspect
        page
    end

    def extract_title(change)
        if change.extension == '.md'
            puts change.path
            fm = FrontMatterParser::Parser.parse_file(change.file_path)
            title = fm['title'].present? && "#{change.parent_title} / #{fm['title']}"
        end
        title ||= change.title
    end

    def load_course_info(change)
        if config = read_config(change)
            Settings["course"] = config
        else
            @errors << "You do not have a course.yml!"
        end
    end

    def load_grading_info(change)
        if grading = read_config(change)
            Settings['grading'] = grading
            validate_grading(grading)
        end
    end

    def load_schedule(file)
        page = get_page(file)
        # load schedule if available
        puts file.file_path
        if schedule_contents = read_config(file.file_path)
            puts schedule_contents
            schedule_name = page.title != '.' ? page.title : 'Standard'
            schedule = Schedule.where(name: schedule_name).first_or_create
            schedule.load(schedule_contents, page)
        end
    end

    def load_module(change)
        # load module info if available
        if content_links = read_config(change.path)
            if content_links.class==Hash && content_links.has_key?('name')
                name = content_links['name']
                content = content_links['content']
            else
                name = page_info[2].parameterize
                content = content_links
            end
            mod = SubModule.where(name: name).first_or_initialize.load(content, page_path)
        end
    end

    def load_submit(change)
        page = get_page(change)

        if submit_config = read_config(change)

            db_pset = nil

            if submit_config['name']
                # checks if pset already exists under name
                pset = Pset.where(:name => submit_config['name']).first_or_initialize
                pset.description = page_info[2]
                pset.message = submit_config['message'] if submit_config['message']
                pset.form = !!submit_config['form']
                pset.url = !!submit_config['url']
                pset.page = page  # restore link to owning page!
                if submit_config['files']
                    pset.files = submit_config['files']
                else
                    pset.files = nil
                end

                pset.config = submit_config
                pset.save

                Pset.where("id != ?", pset).where(page_id: page).update_all(page_id: nil)
            end
        else
            Pset.where(page_id: page).update_all(page_i,d: nil)
        end
    end

    def prune_empty
        # remove all pages having no subpages
        to_delete = Page.includes(:subpages).where(:subpages => { :id => nil }).pluck(:id)

        # remove pages and disassociate any related psets
        Page.where("id in (?)", to_delete).destroy_all
    end

    def validate_grading(grading_config)
        progress_categories = grading_config.select { |category, value| value['show_progress'] }
        if progress_categories.any?
            if grading_config['grades'].blank?
                @errors << "Problem loading grading.yml. There are grading categories like #{progress_categories.first.first} but no grades section is present specifying how to calculate grades."
                return
            end
            all_submit_names = progress_categories.map { |k,v| [k,v['submits'].keys] }
            invalid_grade_names = all_submit_names.map { |k,v| [k,v.select { |name| !grading_config['grades'].include?(name) }] }.select { |k,v| v.any? }.map{|k,v| "#{k}->#{v.join(',')}"}
            if invalid_grade_names.any?
                @errors << "Problem loading grading.yml. Some grades were specified as part of the final grade, but could not be found in the grades section: #{invalid_grade_names.join('; ')}."
                return
            end
        end
    end


    # Walk the directory structure, recursively:
    #  - stores the structurs in a Hash to later render the table of contents (TOC)
    #  - creates pages w/ subpages in the database
    #
    def traverse(curdir, path)
        # this is the tree for the TOC
        res={}

        # get all subdirectories in alphanumerical order
        subdirs = curdir.each_child.filter{|name| !name.basename.to_s.start_with?('.') && name.directory?}.sort

        subdirs.each do |subdir|
            # take the subfolder name and generate a slug
            curslug = split_info(subdir.basename.to_s)[2].parameterize

            # first time, we start out with the subdir-slug
            # if we would use File.join immediately, it would introduce a leading /
            subslug = path.present? ? File.join(path,curslug) : curslug

            # collect the subtree
            subsubs = traverse(subdir, subslug)

            # create a page at this position
            page = process_pages(subdir, subslug)

            if subsubs.any?
                # if we found a subtree, we add that for the TOC, even if a page is also found here
                # however, the page may still be found at the slugged URL
                res[curslug] = subsubs
            elsif page
                # no subdirs, so add a link to this page
                res[page.title] = page.slug
            end
        end

        return res
    end


    # Reads the config file and returns the contents.
    #
    def read_config(file)
        begin
            return YAML.safe_load(file.read)
        rescue => e
            @errors << "#{file} was in an unreadable format. Error message: #{e.message}. Did you confuse tabs and spaces?"
            return nil
        end
    end

    def order_psets
        # Assign order to the grades
        counter = 1
        if Settings['grading'] && Settings['grading']['grades']
            Settings['grading']['grades'].keys.each do |pset|
                if p = Pset.find_by(name:pset)
                    p.update_attribute(:order,counter)
                    counter += 1
                end
            end
        end
    end

end
