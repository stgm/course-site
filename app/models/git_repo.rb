class GitRepo < ApplicationRecord
    belongs_to :owner, polymorphic: true

    validates :provider, inclusion: { in: ['github'] }
    validates :org, :repo, presence: true

    # Delegate fetching and updating to backend
    def backend
        @backend ||= GithubBackend.new(self)
    end

    def update_latest_commit!
        info = backend.fetch_latest_commit
        update!(
            latest_commit_hash: info[:hash],
            latest_commit_message: info[:message],
            latest_commit_at: info[:datetime]
        )
    end

    def install_webhook!(callback_url)
        backend.install_webhook(callback_url)
    end

    def url
        case provider
        when 'github'
            "https://github.com/#{org}/#{repo}"
        end
    end
end
