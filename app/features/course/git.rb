# Get remote git data, either by pulling existing, or cloning anew.
#
class Course::Git
    LOCAL_DIR = Pathname.new('public')
    def initialize(base, repo, remote, branch='main')
        @basedir = Pathname.new(base)
        @repodir = Pathname.new(repo)

        target = LOCAL_DIR + @basedir
        target.mkdir unless target.exist?

        Dir.chdir target do
            begin
                @git = Git.open(repo)
            rescue ArgumentError
                @git = Git.clone(
                    remote,
                    repo,
                    branch: branch,
                    depth: 1)
            end
        end
    end

    def update!
        begin
            @git.pull 'origin', @git.current_branch
        rescue Git::GitExecuteError
            return false
        end
        return true
    end

    def each_change(&block)
        changes_since(previous_version).each do |change|
            yield(change)
        end
        store_version
    end

    private

    def current_version
        @git.object('HEAD').sha
    end

    def new?
        # second part is for upgrade purposes; new values are always stored like in the first part
        Settings.git_version[@repodir].blank? && Settings.find_by_var("git_version_#{@repodir}")&.value.blank?
    end

    def previous_version
        if new?
            # git magic root hash to get all changes, ever
            '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
        else
            # Settings["git_version_#{@repodir}"]
            Settings.git_version[@repodir] || Settings.find_by_var("git_version_#{@repodir}")&.value
        end
    end

    def store_version
        Rails.logger.info "New git version: #{current_version}"
        Settings.git_version = Settings.git_version.merge({ @repodir => current_version })
    end

    def get_remote_branch
        remote_branch = Settings.git_branch
        remote_branch = 'master' if remote_branch.blank?
        return remote_branch
    end

    def changes_since(hash)
        @git.diff(hash).name_status.map do |path,flag|
            Change.new(@basedir, @repodir, Pathname.new(path), flag)
        end
    end

    class Change
        def initialize(base, repo, path, flag)
            @base = base
            @repo = repo
            @path = path
            @flag = flag
        end

        def path
            Path.new @base, @repo, @path
        end

        def parent_path
            Path.new @base, @repo, @path.dirname
        end

        def type
            @flag
        end

        def read
            file.read
        end

        def file
            LOCAL_DIR + @base + @repo + @path
        end

        def basename
            @path.basename.to_s
        end

        def extension
            @path.extname
        end
    end

    class Path
        def initialize(base, repo, path)
            @base = base
            @repo = repo
            @path = path
        end

        def to_s
            (@base + @repo + @path).to_s
        end

        def slug
            (@repo + @path).to_s
            .split('/')
            .map{|c| split_info(c)[2].parameterize}
            .join('/')
        end

        def title
            upcase_first_if_all_downcase(split_info(@path.basename.to_s)[2])
        end

        def position
            pos = split_info(@path.basename.to_s).captures[0]
            pos.present? && pos || 0
        end

        private

        # Splits a path name of the form "nn textextextext" into two parts.
        # Only accepts paths where the first characters are numbers and
        # followed by white space.
        def split_info(object)
            return object.match('(\d*)\s*(.*).md$') || object.match('(\d*)\s*(.*)$')
        end

        def upcase_first_if_all_downcase(s)
            s == s.downcase && s.sub(/\S/, &:upcase) || s
        end
    end
end
