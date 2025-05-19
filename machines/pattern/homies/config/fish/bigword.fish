# Kill a small word
bind alt-backspace backward-kill-word

# Kill a big word (Fish defaults this to `backward-kill-path-component`, but
# that causes asymmetry with Alt+f/Alt+b
bind ctrl-w backward-kill-bigword
