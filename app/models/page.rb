class Page < ApplicationRecord
    has_many :subpages, dependent: :destroy
    has_one  :pset, dependent: :nullify  # psets should never be destroyed, because may have submits
    has_one  :schedule, dependent: :nullify  # a schedule may have this page linked as a syllabus
    has_many :questions # , dependent: :destroy

    # Make sure the subpages are always ordered
    default_scope { order(:position, :title) }

    def normalize_friendly_id(string)
        string.
        downcase.
        gsub(" ", "-").
        gsub("problem-sets", "psets")
    end

    def public_url
        if self.path.start_with?("course")
            url = File.join(Settings.git_repo.sub("git@github.com:", "https://github.com/").sub(/.git$/, ""), "raw", Settings.git_branch.to_s)
            return self.path.sub(/\Acourse/, url)
        elsif self.path.start_with?("materials")
            dir = self.path.match(/\Amaterials\/([^\/]*)/)[1]
            repo = Settings.materials[dir]
            if repo.present?
                url = File.join(repo["remote"].sub(/.git$/, ""), "raw", repo["branch"].to_s)
                return self.path.sub(/\Amaterials\/#{dir}/, url)
            else
                return "materials-dir named #{dir} does not exist (anymore)"
            end
        end
    end

    def self.syllabus
        Current.user.schedule&.page || find_by_slug("")
    end
end
