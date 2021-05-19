# This class is responsible for importing course information from
# the source into the database.
#
class Course::Loader
    COURSE_DIR = "course"
    MATERIALS_DIR = "materials"

    def initialize
        @errors = []
        @touched_subpages = []
    end

    # Re-reads the course contents from the git repository
    #
    def run(reset=false)
        # if requested, reset all page content, because the identifiers may not match
        # when upgrading from the previous import system
        if reset
            Settings.where("var like 'git_version%'").destroy_all
            Subpage.delete_all
        end

        begin
            # main load event
            load_all_changes

            # finishing touches
            Course::Tools.prune_empty_pages
            Course::Tools.clean_psets if @grading_changed
            Course::Tools.regenerate_page_tree

            # allow user overview to update itself
            User.touch_all if @grading_changed
        rescue SQLite3::BusyException
            @errors << "A timeout occurred while loading the new course content. Just try again!"
        end

        if Settings.course.blank?
            @errors << "You do not have a course.yml, consider making one!"
        end
        return @errors
    end

    private

    def load_all_changes
        # load the repo as set in the front-end
        load_changes_from_git({
            'remote' => Settings.git_repo,
            'branch' => Settings.git_branch
        }, COURSE_DIR, '.')

        other_repos = Settings["materials"] || {}
        other_repos.each do |dir, repo|
            load_changes_from_git(repo, MATERIALS_DIR, dir)
        end
    end

    def load_changes_from_git(repo, base_dir, repo_dir)
        Rails.logger.info "Updating course from #{repo['remote']}"
        git = Course::Git.new(base_dir, repo_dir, repo['remote'], repo['branch'])

        if !git.update!
            @errors << "Repo #{repo_dir} could not be updated. You can simply try again."
            return
        end

        git.each_change do |change|
            if change.extension.in? ['.md', '.adoc', '.ipynb']
                load_content change
            else
                case change.basename
                when 'course.yml'
                    load_course_info change
                when 'materials.yml'
                    load_materials_info change
                when 'grading.yml'
                    load_grading_info change
                    @grading_changed = true
                when 'schedule.yml'
                    load_schedule change
                when 'module.yml'
                    load_module change
                when 'submit.yml'
                    load_submit change
                    @grading_changed = true
                end
            end
        end
    end

    def load_content(change)
        page = load_page(change.parent_path)
        subpage = page.subpages.find_or_initialize_by(slug: change.path.slug)

        if change.type == 'D'
            # content was deleted
            subpage.destroy
        else
            # content was added or modified
            case change.extension
            when '.md'
                fm = FrontMatterParser::Parser.parse_file(change.file)
                title = fm['title'].present? && "#{change.parent_path.title} / #{fm['title']}"
                content = fm.content
                description = fm['description']
            when '.adoc'
                document = Asciidoctor.load(
                    change,
                    safe: :safe,
                    attributes: {
                        'showtitle' => true,
                        'imagesdir' => page.public_url,
                        'skip-front-matter' => true,
                        'stem' => true
                    })
                content = document.convert
            when '.ipynb'
                content = GradingHelper::NBConverter.new(change).run
            end

            title ||= change.path.title
            description ||= nil

            subpage.title = title
            subpage.position = change.path.position
            subpage.content = content
            subpage.description = description
            subpage.save
            @touched_subpages << subpage.id
        end
    end

    def load_page(path)
        page = Page.find_or_initialize_by(slug: path.slug)
        page.title = path.title
        page.slug = path.slug
        page.path = path
        page.position = path.position
        page.save
        page
    end

    def load_course_info(file)
        if config = read_config(file)
            Settings["course"] = config
        end
    end

    def load_materials_info(file)
        if config = read_config(file)
            Settings["materials"] = config
        end
    end

    def load_grading_info(file)
        if config = read_config(file)
            GradingConfig.load config
            GradingConfig.validate
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

            mod = SubModule.where(name: name).first_or_initialize
            mod.load(content, file.parent_path.slug)
        end
    end

    def load_submit(file)
        page = load_page(file.parent_path)
        if submit_config = read_config(file)
            if name = submit_config['name']
                pset = Pset.where(name: name).first_or_initialize

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
                submit_config.merge! GradingConfig.grades[name].to_h
                pset.config = submit_config
                pset.save

                if Pset.where("id != ?", pset).where(page_id: page).any?
                    Pset.where("id != ?", pset).where(page_id: page).update_all(page_id: nil)
                end
            end
        else
            Pset.where(page_id: page).update_all(page_id: nil)
        end
    end

    # Reads the config file and returns the contents
    #
    def read_config(file)
        begin
            return YAML.load(file.read)
        rescue => e
            @errors << "#{file.path} was in an unreadable format. Error message: #{e.message}."
            return nil
        end
    end
end
