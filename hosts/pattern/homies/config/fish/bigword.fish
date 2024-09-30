# Alt+Backspace kills a bigword
bind \e\x7f backward-kill-bigword

# Ctrl+w kills a smaller word (Fish defaults this to
# `backward-kill-path-component`, but that causes asymmetry with Alt+f/Alt+b
bind \cw backward-kill-word
