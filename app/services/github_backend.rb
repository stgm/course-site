class GithubBackend
    def initialize(git_repo)
        @repo = git_repo
        @client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
        @full_name = "#{@repo.org}/#{@repo.repo}"
    end

    # Returns hash with keys :hash, :message, :datetime
    def fetch_latest_commit
        commit = @client.commits(@full_name).first
        {
            hash: commit.sha,
            message: commit.commit.message,
            datetime: commit.commit.author.date
        }
    end

    # Installs a webhook to POST to callback_url on push
    def install_webhook(callback_url)
        @client.create_hook(
            @full_name,
            "web",
            {
                url: callback_url,
                content_type: "json"
            },
            { events: ["push"], active: true }
        )
    end
end
