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
            load_changes_from_git
            Settings.page_tree = generate_page_tree
            if Settings.course.blank?
                @errors << "You do not have a course.yml!"
            end

            # remove old stuff
            prune_empty

            # put psets in order
            order_psets
            Course::Tools.clean_psets

            # allow user overview to update itself
            User.touch_all
        rescue SQLite3::BusyException
            @errors << "A timeout occurred while loading the new course content. Just try again!"
        end
        return @errors
    end

    private
    
    def load_changes_from_git
        repo_dir = '.'
        git = Course::Git.new(COURSE_DIR, repo_dir)

        if not git.update!
            @errors << "Repo #{repo_dir} could not be updated. You can simply try again."
            return
        end

        if Settings.git_version
            previous_version = Settings.git_version
        else
            # set to git magic root hash to get all changes, ever
            previous_version = '4b825dc642cb6eb9a060e54bf8d69288fbee4904' 
            # on first git import, reset al page content, because the identifiers may not match
            Subpage.delete_all
        end

        git.changes_since(previous_version).each do |change|
            if change.path.extension.in? ['.md', '.adoc', '.ipynb']
                load_content change
            else
                puts "Trying #{change.file.inspect}"
                case change.path.filename
                when 'course.yml'
                    load_course_info change
                when 'grading.yml'
                    load_grading_info change
                when 'schedule.yml'
                    load_schedule change
                when 'module.yml'
                    load_module change
                when 'submit.yml'
                    load_submit change
                end
            end
        end

        Settings.git_version = git.current_version
    end

    def load_content(file)
        puts "Loading #{file.inspect}"

        page = load_page(file.parent_path)
        subpage = page.subpages.find_or_initialize_by(slug: file.path.slug)

        if file.change_type == 'D'
            # content was deleted
            subpage.destroy
        else
            # content was added or modified
            title = extract_title(file)
            content = case file.path.extension
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

            subpage.position = file.path.position
            subpage.content = content
            # subpage.description = file.front_matter['description']
            subpage.save
            @touched_subpages << subpage.id
        end
    end

    def load_page(parent)
        page = Page.find_or_initialize_by(slug: parent.slug)
        page.title = parent.title
        page.slug = parent.slug
        page.path = parent.to_s
        page.position = parent.position
        page.save
        puts page.inspect
        page
    end

    def extract_title(change)
        if change.path.extension == '.md'
            puts change.path
            fm = FrontMatterParser::Parser.parse_file(change.file)
            title = fm['title'].present? && "#{change.parent_path.title} / #{fm['title']}"
        end
        title ||= change.path.title
    end

    def load_course_info(file)
        if config = read_config(file)
            Settings["course"] = config
        end
    end

    def load_grading_info(file)
        if config = read_config(file)
            Grading.load config
            Grading.validate
        end
    end

    def load_schedule(file)
        page = load_page(file.parent_path)
        if schedule_contents = read_config(file)
            schedule_name = page.title != '.' ? page.title : 'Standard'
            schedule = Schedule.where(name: schedule_name).first_or_create
            schedule.load(schedule_contents, page)
        end
    end

    def load_module(file)
        if content_links = read_config(file)
            if content_links.class==Hash && content_links.has_key?('name')
                name = content_links['name']
                content = content_links['content']
            else
                name = file.parent_path.title.parameterize
                content = content_links
            end
            puts "MODULE #{name} #{file.parent_path}"
            mod = SubModule.where(name: name).first_or_initialize.load(content, file.parent_path.to_s)
        end
    end

    def load_submit(file)
        page = load_page(file.parent_path)
        if submit_config = read_config(file)
            if submit_config['name']
                # checks if pset already exists under name
                pset = Pset.where(name: submit_config['name']).first_or_initialize
                pset.description = file.parent_path.title.parameterize
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

    # generate a tree of (nested) sections and pages
    #
    def generate_page_tree
        ps = Page.all
        res = {}

        ps.each do |p|
            hash = hashify_path(p.slug.split('/'), p.slug, p.title)
            res.deep_merge! hash
        end
        
        return res
    end
    
    # generate nested hash for array of path segments
    #
    def hashify_path(path, full, title)
        first, *rest = path
        if rest.empty?
            # leaf node
            entry = { title => full }
        else
            entry = { first => hashify_path(rest, full, title) }
        end
        entry
    end

    # reads the config file and returns the contents
    #
    def read_config(file)
        begin
            return YAML.load(file.read)
        rescue => e
            @errors << "#{file.path} was in an unreadable format. Error message: #{e.message}. Did you confuse tabs and spaces?"
            return nil
        end
    end

    def order_psets
        # Assign order to the grades
        counter = 1
        if Settings['grading'] && Settings['grading']['grades']
            Settings['grading']['grades'].keys.each do |pset|
                if p = Pset.find_by(name:pset)
                    p.update(order: counter)
                    counter += 1
                end
            end
        end
    end
end
