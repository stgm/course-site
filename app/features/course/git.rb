#
#  Get remote git data, either by pulling existing, or cloning anew.
#
class Course::Git
    def initialize(base, repo)
        @basedir = Pathname.new(base)
        @repodir = Pathname.new(repo)

        Dir.chdir @basedir do
            @git = Git.open(@repodir)
        end

        if !@git && Settings.git_repo.present?
            @git = Git.clone(
            Settings.git_repo,
            @repodir.to_s,
            branch: self.get_remote_branch,
            depth: 1)
        end
    end

    def each_change(&block)
        changes_since(previous_version).each do |change|
            yield(change)
        end
        store_version
    end

    def update!
        begin
            @git.pull 'origin', @git.current_branch
        rescue Git::GitExecuteError
            return false
        end
        return true
    end

    def changes_since(hash)
        @git.diff(hash).name_status.map do |path,flag|
            Change.new(@basedir, @repodir + path, flag)
        end
    end

    def current_version
        @git.object('HEAD').sha
    end

    # def previous_version
    #     # last saved version number OR the git root hash value
    #     # the latter can be used to get a diff since the beginning of time
    #
    # end
    #
    # def store_version
    #     Settings.git_version = current_version
    # end

    private

    def get_remote_branch
        remote_branch = Settings.git_branch
        remote_branch = 'master' if remote_branch.blank?
        return remote_branch
    end

    class Change
        def initialize(base, path, flag)
            @base = base
            @path = path
            @flag = flag
        end

        def path
            Path.new @path
        end

        def parent_path
            Path.new @path.dirname
        end

        def change_type
            @flag
        end

        def read
            file.read
        end

        def file
            @base + @path
        end
    end

    class Path
        def initialize(path)
            @path = path
        end

        def to_s
            @path.to_s
        end

        def slug
            @path.to_s
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

        def filename
            @path.basename.to_s
        end

        def extension
            @path.extname
        end

        def position
            @position
        end

        private

        # Splits a path name of the form "nn textextextext" into two parts.
        # Only accepts paths where the first characters are numbers and
        # followed by white space.
        #
        def split_info(object)
            return object.match('(\d*)\s*(.*).md$') || object.match('(\d*)\s*(.*)$')
        end

        def upcase_first_if_all_downcase(s)
            s == s.downcase && s.sub(/\S/, &:upcase) || s
        end
    end
end
