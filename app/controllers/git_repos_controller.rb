class GitReposController < ApplicationController

    before_action :authorize

    layout "modal"

    def show
        @git_repo = GitRepo.includes(:owner).find(params[:id])
    end

    private

    def git_repo_params
        params.require(:git_repo).permit(:org, :repo)
    end

end
