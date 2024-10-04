# Alt+Backspace kills a small word
bind \e\x7f backward-kill-word

# Ctrl+w kills a big word (Fish defaults this to
# `backward-kill-path-component`, but that causes asymmetry with Alt+f/Alt+b
bind \cw backward-kill-bigword
