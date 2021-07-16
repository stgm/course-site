class Git::Lib

    # override to not detect renames, but simply report deletions and additions

    def diff_name_status(reference1 = nil, reference2 = nil, opts = {})
        opts_arr = ['--name-status', '--no-renames']
        opts_arr << reference1 if reference1
        opts_arr << reference2 if reference2

        opts_arr << '--' << opts[:path] if opts[:path]

        command_lines('diff', opts_arr).inject({}) do |memo, line|
            status, path = line.split("\t")
            memo[path] = status
            memo
        end
    end

end
