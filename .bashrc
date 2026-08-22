# ~/.bashrc: executed by bash(1) for non-login shells.

export LANG=uk_UA.UTF-8
export LANGUAGE=uk_UA
export LC_ALL=uk_UA.UTF-8
export GTK_OVERLAY_SCROLLING=0
export GTK_USE_OVERLAY_SCROLLING=0
export QT_QPA_PLATFORM=xcb
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export VICMD=nvim
export EDITOR='nvim'
export VISUAL='nvim'
export PATH="$HOME/.local/bin:$PATH"

case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=50000
HISTFILESIZE=100000

shopt -s checkwinsize
# Автоматично виправляти дрібні друкарські помилки в іменах папок при використанні `cd`
shopt -s cdspell
# Дозволяє переходити в папку, просто написавши її ім'я без команди `cd`
shopt -s autocd
# Увімкнути розширений глоббінг (наприклад, cp **/*.txt /backup/)
shopt -s globstar

# Записувати історію одразу після виконання команди, а не при закритті сесії
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Ігнорувати дублікати та команди, що починаються з пробілу
HISTCONTROL=ignoreboth:erasedups

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias cls='clear'
    alias elinks='netsurf-gtk'
    alias sakura='st'
    alias grep='grep --color=auto'
    alias ll='exa -lh --icons'
    alias la='exa -lah --icons'
    alias tree='exa --tree --icons'
    alias dir='exa -F --icons'
    alias dirtree='exa --tree --level=2 --icons'
fi
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias micro='nvim'
alias nano='nvim'
alias vi='nvim'
alias vim='nvim'
alias lodraw_gen='SAL_USE_VCLPLUGIN=gen lodraw'
alias lowriter='lowriter --nologo --nofirststartwizard'
alias loimpress='loimpress --nologo --nofirststartwizard'
alias localc='localc --nologo --nofirststartwizard'
alias trash-clean='trash-empty && pkill -RTMIN+2 dwmblocks'
alias v='nvim $(rg --files --hidden 2>/dev/null | fzf --preview "batcat --color=always --style=numbers --line-range :500 {}")'

mkd() {
    mkdir -p "$1" && cd "$1"
}

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


# =============================================================================
# НАЛАШТУВАННЯ FZF (ПІДКАЗКИ, КОЛЬОРИ GRUVBOX ТА КАСТОМНІ КЛАВІШІ)
# =============================================================================
# 1. Завантажуємо стандартні гарячі клавіші fzf
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
else
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
fi

# 2. Скасовуємо стандартний біндінг для Alt+C (\ec)
bind -r '\ec'

# динамічна тема FZF (GRUVBOX)
if [ -f "$HOME/.lightmode" ]; then
    # --- СВІТЛА ТЕМА GRUVBOX ---
    export FZF_DEFAULT_OPTS="
      --color=bg+:#ebdbb2,bg:#fbf1c7,spinner:#427b58,hl:#7c6f64 \
      --color=fg:#3c3836,header:#7c6f64,info:#427b58,pointer:#9d0006 \
      --color=marker:#b57614,fg+:#3c3836,prompt:#9d0006,hl+:#9d0006 \
      --color=border:#bdae93,header:#b57614"
else
    # --- ТЕМНА ТЕМА GRUVBOX ---
    export FZF_DEFAULT_OPTS="
      --color=bg+:#3c3836,bg:#282828,spinner:#8ec07c,hl:#928374 \
      --color=fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934 \
      --color=marker:#fabd2f,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934 \
      --color=border:#7c6f64,header:#fabd2f"
fi

# Кастомізація Ctrl + T (Пошук файлів)
export FZF_CTRL_T_OPTS="
  --height=80% \
  --border=sharp \
  --margin=1 \
  --header='🔍 ПОШУК ФАЙЛІВ ТА КАТАЛОГІВ' \
  --header-first \
  --prompt='📂 Файл > '"

# Кастомізація Ctrl + R (Пошук історії команд)
export FZF_CTRL_R_OPTS="
  --height=80% \
  --border=sharp \
  --margin=1 \
  --header='📜 ИСТОРІЯ КОМАНД BASH' \
  --header-first \
  --prompt='⌨️  Команда > '"

# 4. Функція для Ctrl+G з вбудованими налаштуваннями візуалу
_fzf_goto_dir() {
    local dir
    # Опції прописані прямо тут, тому Bash зчитає їх без жодних помилок парсингу
    dir=$(find . -path '*/.*' -prune -o -type d -print 2> /dev/null | fzf +m \
        --height=80% \
        --border=sharp \
        --margin=1 \
        --header='📁 ШВИДКИЙ ПЕРЕХІД ДО ДИРЕКТОРІЇ' \
        --header-first \
        --prompt='🚶 Каталог > ')
    
    if [ -n "$dir" ]; then
        cd "$dir"
    fi    
    READLINE_LINE=""
    READLINE_POINT=0
    printf '\r'
}

# Реєструємо функцію на комбінацію Ctrl+G
bind -x '"\C-g": _fzf_goto_dir'
# =============================================================================

# =============================================================================
# LF
# =============================================================================
function l() {
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT INT TERM

    lf -last-dir-path="$tmp" "$@"

    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        trap - EXIT INT TERM

        if [ -n "$dir" ] && [ -d "$dir" ] && [ "$dir" != "$(pwd)" ]; then
            cd "$dir"
        fi
    fi
}
alias д=l

alias rm_fuse_files='find . -name ".fuse_hidden*" -delete'
alias ncdu='NCDU_MODE="NCU" SHELL=/bin/bash ncdu'

alias copy_card='rclone sync "/mnt/chromeos/removable/SD Card/" "/mnt/chromeos/removable/UNTITLED/" --exclude ".fuse_hidden*" --exclude "*.~tmp*" --delete-before --stats "1s" -P --stats-one-line --tpslimit 8 --drive-chunk-size 64M --fast-list'

eval "$(zoxide init bash)"
eval "$(starship init bash)"
