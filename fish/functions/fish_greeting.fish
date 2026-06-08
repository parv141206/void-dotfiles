function fish_greeting
    if command -q fastfetch
        fastfetch --config ~/.config/fastfetch/config.jsonc
    end
end
