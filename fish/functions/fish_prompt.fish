function fish_prompt
    set -l last_status $status

    set_color 5a8a5a
    echo -n (prompt_pwd)

    if test $last_status -ne 0
        set_color 9e4444
        echo -n " [$last_status]"
    end

    set_color c8c8c8
    echo -n " > "
    set_color normal
end
