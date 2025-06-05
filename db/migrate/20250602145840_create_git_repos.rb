class CreateGitRepos < ActiveRecord::Migration[8.0]
    def change
        create_table :git_repos do |t|
            t.string :provider, default: "github", null: false
            t.string :org, null: false      # GitHub org/user
            t.string :repo, null: false     # Repo name

            t.references :owner, polymorphic: true, index: true, null: false

            t.string :latest_commit_hash
            t.string :latest_commit_message
            t.datetime :latest_commit_at
            t.timestamps
        end
    end
end
