class Page < ApplicationRecord
    has_many :subpages, dependent: :destroy
    has_one  :pset, dependent: :nullify  # psets should never be destroyed, because may have submits

    # Make sure the subpages are always ordered
    default_scope { order(:position, :title) }

    def normalize_friendly_id(string)
        string.
        downcase.
        gsub(" ", "-").
        gsub("problem-sets", "psets")
    end

    def public_url
        return File.join("/", path)
    end
end
