#!/usr/bin/env bash
# Copied from https://github.com/dshoreman/realworld-colourtest/blob/master/colours.sh

main() {
    all
    colours
    messages
    weechat
    zsh_prompt blue
    zsh_prompt green "git --no-pager diff"
    git_diff
    cdk
}

dim=$(tput dim)
bold=$(tput bold)

black=$'\e[30m'
grey=$'\e[38;5;236m'
white=$'\e[37m'
default=$'\e[39m'
red=$'\e[31m'
green=$'\e[32m'
blue=$'\e[34m'
cyan=$'\e[36m'
yellow=$'\e[33m'
magenta=$'\e[35m'
Bblack=$'\e[90m'
Byellow=$'\e[93m'
Bmagenta=$'\e[95m'
reset=$'\e[0m'

bgWhite='\e[48;5;7m'
bgRed='\e[48;5;52m'
bgGreen='\e[48;5;22m'
bgBGreen='\e[48;5;2m'
bgBlue='\e[48;5;4m'
bgMagenta='\e[45m'
bgReset='\e[49m'

pad() {
    str=${2:- }
    yes "$str" | head -n "$1" | tr -d '\n'
}

colours() {
    echo
    colour_blocks 0 {40..47}
    colour_blocks "" {100..107}
}

colour_blocks() {
    local padding=$1
    shift

    for c in "$@"; do
        echo -ne "\e[${c}m    ${padding}${c}    ${reset} "
    done
    echo
}

git_diff() {
    echo -e "${dim}${cyan}diff --git a/foo.sh b/foo.sh"
    echo -e "index abcdef0..93f3a4d 100755"
    echo -e "--- a/foo.sh"
    echo -e "+++ b/foo.sh${reset}"
    echo -e "${dim}${magenta}@@ -42,2 +42,3 @@${reset} * Some list item"
    echo -e " * Some other list item"
    echo -e "${bold}${red}-## A${bgRed}n old ${bgReset}${red}title${reset}"
    echo -e "${bold}${green}+"
    echo -e "+##${bgGreen}#${bgReset} A${bgGreen} newly changed sub${bgReset}title${reset}"
}

messages() {
    echo
    echo -e "${dim}Dim line of text       ${cyan}Dim info message       ${yellow}Dim warning message       ${red}Dim error message${reset}"
    echo -e "Normal line of text    ${cyan}Normal info message    ${yellow}Normal warning message    ${red}Normal error message${reset}"
    echo -e "${bold}Bold line of text      ${cyan}Bold info message      ${yellow}Bold warning message      ${red}Bold error message${reset}"
}

weechat() {
    echo
    echo -e "${bgBlue} ${green}1.${default}weechat            ${bgReset}${blue}│${bgBlue}${default}Highlight Monitor$(pad 55)${bgReset}"
    echo -en "${reset}   freenode           ${blue}│${default}16${yellow}:${default}20${yellow}:${default}42 "
    echo -en "${cyan}<${Bmagenta}freenode#archlinux${cyan}> "
    echo -e "${default}<${bgMagenta}${Byellow}hunter1${bgReset}${default}> $(whoami): ping!${reset}"
    echo -en " ${green}2.${default}highmon$(pad 12)${blue}│${bgBlue}${cyan}[${default}17:12${cyan}] [${default}4${cyan}]"
    echo -en " ${default}${yellow}2${cyan}:${default}highmon ${cyan}[${default}H:"
    echo -en " ${magenta}3${cyan}:${default}#archlinux${cyan}(${magenta}1${cyan},${yellow}42${cyan}),"
    echo -e " ${green}5${cyan}:${default}hunter1${cyan}(${green}7${cyan}), ${yellow}4${cyan}(${yellow}512${cyan},${default}538${cyan})] "
    echo -en "${reset} ${green}3.  ${magenta}#archlinux       ${blue}│${cyan}[${default}INSERT${cyan}]"
    echo -e "[$(whoami)${cyan}(${default}Ri${cyan})] ${default}▯"
    echo -e " ${green}4.  ${yellow}#sway$(pad 12)${blue}│$(pad 72 -)"
    echo -e " ${green}5.  hunter1$(pad 10)${blue}│"
}

zsh_prompt() {
    local bg dir text sep=''

    if [ "$1" = "green" ]; then
        bg=${bgBGreen}
        dir=${green}
        text=${grey}
        icons="${red}✘ ${grey}⬇ ${blue}✹ ${green}✚"
    else
        bg=${bgBlue}
        dir=${blue}
        text=${white}
        icons="${green}✔ ${grey}⬆ ${yellow}✭"
    fi

    echo
    echo -en "${bgWhite}${black} 16:20:42 ${bg}${white}${sep}${text} ~/dev/project ${bgWhite}${dir}${sep}"
    echo -e "${black}  master ${icons} ${bgReset}${white}${sep}${reset}"
    echo -e "${bold}${green}\$${reset} ${2}"
}

cdk() {
    echo -e " ${Bblack}this is bright black${reset}"
}

all() {
    for x in {0..8}; do
        for i in {30..37}; do
            for a in {40..47}; do
                echo -ne "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "
            done
            echo
        done
    done
    echo ""
}
main
