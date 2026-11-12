# vim-surround for fish's vi mode, a port of kylechui/nvim-surround's logic.
#
#   ys{motion}{char}   add     motions: iw iW aw aW $ s (the whole line, so `yss`)
#   ds{char}           delete
#   cs{old}{new}       change
#   S{char}            add around the visual selection
#
# {char} is any printable key. These have special meaning, like in nvim-surround:
#   ( [ { <     pad with a space ( ... ); the closing forms ) ] } > don't. `ds(` also drops the padding.
#   b r B a     aliases for ) ] } >
#   q s         ds/cs targets: nearest of " ' ` / nearest of } ] ) > " ' `
#   t T         HTML tag, prompts for `h1 class="x"`; T keeps the attributes when changing
#   f           function call, prompts for the name
#   i           prompts for the left and right delimiter
# Any other key is a symmetric delimiter (`ysiw*` gives *word*, `ds-` deletes -...-).
# Prompts show up on the command line itself; Enter accepts, Escape cancels.
#
# Finding the surround, like nvim-surround: brackets use the innermost pair around the cursor, falling
# back to the nearest opening bracket before it; quotes and other symmetric chars use the nearest one
# on each side on the cursor's line, falling back to the next pair after it.
# shortcut: no counts, dot-repeat, or highlight; the tag finder doesn't handle `>` inside attributes.

# usage: __surround_load; snapshots the buffer as a list of chars for the finders, plus the 1-based cursor
function __surround_load
    set -g __surround_chars (string split '' -- (commandline -b | string collect))
    set -g __surround_cur (math (commandline -C) + 1)
end

# usage: __surround_alias <char>
function __surround_alias
    switch $argv[1]
        case a
            echo '>'
        case b
            echo ')'
        case B
            echo '}'
        case r
            echo ']'
        case '*'
            printf '%s\n' $argv[1]
    end
end

# usage: __surround_pair <bracket>; prints its opening and closing form, one per line
function __surround_pair
    switch $argv[1]
        case '(' ')'
            printf '%s\n' '(' ')'
        case '[' ']'
            printf '%s\n' '[' ']'
        case '{' '}'
            printf '%s\n' '{' '}'
        case '<' '>'
            printf '%s\n' '<' '>'
    end
end

# usage: __surround_needs <char>; how many prompts the delimiters of <char> need
function __surround_needs
    switch (__surround_alias $argv[1])
        case t T f
            echo 1
        case i
            echo 2
        case '*'
            echo 0
    end
end

# usage: __surround_delims <char> [prompt answers...]; prints the left and right delimiter, one per line
function __surround_delims
    set -l c (__surround_alias $argv[1])
    set -e argv[1]
    switch $c
        case '(' '[' '{' '<'
            set -l p (__surround_pair $c)
            printf '%s\n' "$p[1] " " $p[2]"
        case ')' ']' '}' '>'
            printf '%s\n' (__surround_pair $c)
        case t T
            set -l el (string replace -r '^<?([^\s>]*).*' '$1' -- $argv[1])
            set -l attrs (string match -rg '^<?[^\s>]*\s+(.*?)>?$' -- $argv[1])
            test -n "$el"; or return 1
            set -l open $el
            test -n "$attrs"; and set open "$el $attrs"
            printf '%s\n' "<$open>" "</$el>"
        case f
            test -n "$argv[1]"; or return 1
            printf '%s\n' "$argv[1](" ')'
        case i
            printf '%s\n' "$argv[1]" "$argv[2]"
        case '*'
            string match -qr -- '^[[:print:]]$' $c; or return 1
            printf '%s\n' $c $c
    end
end

# usage: __surround_line; prints the first and last position of the cursor's line
function __surround_line
    set -l a $__surround_cur
    set -l b $a
    while test $a -gt 1
        set -l prev (math $a - 1)
        test (string escape -- $__surround_chars[$prev]) != '\n'; or break
        set a $prev
    end
    while test $b -lt (count $__surround_chars)
        set -l next (math $b + 1)
        test (string escape -- $__surround_chars[$next]) != '\n'; or break
        set b $next
    end
    printf '%s\n' $a $b
end

# Finders print four positions: the surround's first char, the last char of its left delimiter,
# the first char of its right delimiter, and its last char. They return 1 when nothing is found.

# usage: __surround_find_pair <open> <close>
function __surround_find_pair
    set -l open $argv[1]
    set -l close $argv[2]
    set -l n (count $__surround_chars)
    set -l cur $__surround_cur
    test $cur -le $n; or return 1
    set -l a 0
    set -l depth 0
    for i in (seq $cur -1 1)
        if test "x$__surround_chars[$i]" = "x$open"
            test $depth -eq 0; and set a $i; and break
            set depth (math $depth - 1)
        else if test "x$__surround_chars[$i]" = "x$close"; and test $i -ne $cur
            set depth (math $depth + 1)
        end
    end
    if test $a -eq 0
        # not inside a pair: take the nearest opening bracket before the cursor
        for i in (seq $cur -1 1)
            test "x$__surround_chars[$i]" = "x$open"; and set a $i; and break
        end
    end
    test $a -gt 0; or return 1
    set depth 0
    for i in (seq (math $a + 1) $n)
        if test "x$__surround_chars[$i]" = "x$open"
            set depth (math $depth + 1)
        else if test "x$__surround_chars[$i]" = "x$close"
            test $depth -eq 0; and printf '%s\n' $a $a $i $i; and return 0
            set depth (math $depth - 1)
        end
    end
    return 1
end

# usage: __surround_find_sym <char>
function __surround_find_sym
    set -l q $argv[1]
    set -l l (__surround_line)
    set -l cur $__surround_cur
    set -l qs
    for i in (seq $l[1] $l[2])
        test "x$__surround_chars[$i]" = "x$q"; and set -a qs $i
    end
    set -l a 0
    set -l b 0
    set -l k (contains -i -- $cur $qs)
    if test -n "$k"
        # on a delimiter: they pair up from the start of the line
        set -l o $k
        test (math $k % 2) -eq 0; and set o (math $k - 1)
        set -q qs[(math $o + 1)]; or return 1
        set a $qs[$o]
        set b $qs[(math $o + 1)]
    else
        for i in $qs
            if test $i -lt $cur
                set a $i
            else if test $b -eq 0
                set b $i
            end
        end
        if test $a -eq 0
            # nothing before the cursor: take the first pair after it
            test (count $qs) -ge 2; or return 1
            set a $qs[1]
            set b $qs[2]
        end
    end
    test $a -gt 0 -a $b -gt 0; or return 1
    printf '%s\n' $a $a $b $b
end

# the innermost <tag>...</tag> around the cursor
function __surround_find_tag
    set -l buf (string join '' -- $__surround_chars | string collect)
    set -l stack
    set -l best
    for t in (string match -rna -- '<[^<>]*>' $buf)
        set -l pos (string split ' ' -- $t)
        set -l s $pos[1]
        set -l e (math $s + $pos[2] - 1)
        set -l text (string sub -s $s -l $pos[2] -- $buf)
        if string match -qr -- '^</' $text
            set -l name (string replace -r '^</\s*([^\s>]+).*' '$1' -- $text)
            for i in (seq (count $stack) -1 1)
                set -l top (string split ' ' -- $stack[$i])
                test "x$top[1]" = "x$name"; or continue
                if test $top[2] -le $__surround_cur -a $__surround_cur -le $e
                    if test (count $best) -eq 0; or test $top[2] -gt $best[1]
                        set best $top[2] $top[3] $s $e
                    end
                end
                set -e stack[$i..-1]
                break
            end
        else if string match -qr -- '^<[A-Za-z]' $text; and not string match -q -- '*/>' $text
            set -a stack (string replace -r '^</?\s*([^\s>/]+).*' '$1' -- $text)" $s $e"
        end
    end
    test (count $best) -gt 0; or return 1
    printf '%s\n' $best
end

# the innermost name(...) around the cursor, else the next one after it, else the last one before
function __surround_find_func
    set -l n (count $__surround_chars)
    set -l cur $__surround_cur
    set -l inside
    set -l after
    set -l before
    for p in (seq $n)
        test "x$__surround_chars[$p]" = 'x('; or continue
        set -l s $p
        while test $s -gt 1; and not string match -qr -- '[\s=(){}]' $__surround_chars[(math $s - 1)]
            set s (math $s - 1)
        end
        test $s -lt $p; or continue
        set -l depth 0
        set -l q 0
        for j in (seq (math $p + 1) $n)
            switch $__surround_chars[$j]
                case '('
                    set depth (math $depth + 1)
                case ')'
                    test $depth -eq 0; and set q $j; and break
                    set depth (math $depth - 1)
            end
        end
        test $q -gt 0; or continue
        if test $s -le $cur -a $cur -le $q
            if test (count $inside) -eq 0; or test $s -gt $inside[1]
                set inside $s $p $q $q
            end
        else if test $s -gt $cur
            test (count $after) -eq 0; and set after $s $p $q $q
        else
            set before $s $p $q $q
        end
    end
    set -l best $inside
    test (count $best) -eq 0; and set best $after
    test (count $best) -eq 0; and set best $before
    test (count $best) -gt 0; or return 1
    printf '%s\n' $best
end

# usage: __surround_select <char>; finds the surround for a ds/cs target
function __surround_select
    set -l c (__surround_alias $argv[1])
    switch $c
        case '(' ')'
            __surround_find_pair '(' ')'
        case '[' ']'
            __surround_find_pair '[' ']'
        case '{' '}'
            __surround_find_pair '{' '}'
        case '<' '>'
            __surround_find_pair '<' '>'
        case t T
            __surround_find_tag
        case f
            __surround_find_func
        case i
            return 1
        case q s
            set -l list '"' "'" '`'
            test $c = s; and set list '}' ']' ')' '>' '"' "'" '`'
            set -l best
            for x in $list
                set -l r (__surround_select $x); or continue
                # keep the surround that contains the cursor, nested deepest, else the nearest one
                if test (count $best) -eq 0
                    set best $r
                    continue
                end
                set -l cur $__surround_cur
                if test $best[1] -le $cur -a $cur -le $best[4]
                    test $r[1] -le $cur -a $cur -le $r[4] -a $r[1] -ge $best[1] -a $r[4] -le $best[4]; and set best $r
                else if test $cur -le $best[1]
                    if test $r[1] -le $cur -a $cur -le $r[4]; or test $cur -le $r[1] -a $r[1] -le $best[1]
                        set best $r
                    end
                else if test $r[1] -le $cur -a $cur -le $r[4]; or test $best[4] -le $r[4]
                    set best $r
                end
            end
            test (count $best) -gt 0; or return 1
            printf '%s\n' $best
        case '*'
            __surround_find_sym $c
    end
end

# usage: __surround_trim <char> <selection...>; opening brackets also take one space of padding on each side
function __surround_trim
    set -l ch $argv[1]
    set -l a $argv[2]
    set -l oe $argv[3]
    set -l cs $argv[4]
    set -l b $argv[5]
    if contains -- $ch '(' '[' '{' '<'
        set -l p (math $a + 1)
        test "x$__surround_chars[$p]" = 'x '; and test $p -lt $b; and set oe $p
        set p (math $b - 1)
        test "x$__surround_chars[$p]" = 'x '; and test $p -gt $oe; and set cs $p
    end
    printf '%s\n' $a $oe $cs $b
end

# usage: __surround_apply <ls> <le> <rs> <re> <left> <right>
# replaces the left delimiter ls..le and the right delimiter rs..re (either may be empty: le = ls - 1)
function __surround_apply
    set -l buf (commandline -b | string collect)
    set -l pre (string sub -l (math $argv[1] - 1) -- $buf | string collect)
    set -l mid (string sub -s (math $argv[2] + 1) -l (math $argv[3] - $argv[2] - 1) -- $buf | string collect)
    set -l post (string sub -s (math $argv[4] + 1) -- $buf | string collect)
    commandline -r -- $pre$argv[5]$mid$argv[6]$post
    commandline -C (math $argv[1] - 1)
end

# usage: __surround_cls <char> <big>; word chars, spaces and punctuation are separate classes for iw
function __surround_cls
    if test (string escape -- $argv[1]) = '\n'
        echo n
    else if string match -qr -- '^\s$' $argv[1]
        echo s
    else if test $argv[2] = 1; or string match -qr -- '^[[:alnum:]_]$' $argv[1]
        echo w
    else
        echo p
    end
end

# usage: __surround_motion <motion>; prints the first and last position the motion covers
function __surround_motion
    set -l m $argv[1]
    set -l cur $__surround_cur
    set -l n (count $__surround_chars)
    test $cur -le $n; or return 1
    switch $m
        case '$'
            printf '%s\n' $cur (__surround_line)[2]
        case ss
            __surround_line
        case iw iW aw aW
            set -l big 0
            string match -q -- '*W' $m; and set big 1
            set -l cls (__surround_cls $__surround_chars[$cur] $big)
            test $cls != n; or return 1
            set -l a $cur
            set -l b $cur
            while test $a -gt 1; and test (__surround_cls $__surround_chars[(math $a - 1)] $big) = $cls
                set a (math $a - 1)
            end
            while test $b -lt $n; and test (__surround_cls $__surround_chars[(math $b + 1)] $big) = $cls
                set b (math $b + 1)
            end
            if string match -q -- 'a*' $m
                # aw: add the trailing spaces, or the leading ones if there are none (a space run takes the next word)
                if test $cls = s
                    set -l nx (math $b + 1)
                    if test $nx -le $n; and test (__surround_cls $__surround_chars[$nx] $big) != n
                        set -l c2 (__surround_cls $__surround_chars[$nx] $big)
                        while test $b -lt $n; and test (__surround_cls $__surround_chars[(math $b + 1)] $big) = $c2
                            set b (math $b + 1)
                        end
                    end
                else if test $b -lt $n; and test (__surround_cls $__surround_chars[(math $b + 1)] $big) = s
                    while test $b -lt $n; and test (__surround_cls $__surround_chars[(math $b + 1)] $big) = s
                        set b (math $b + 1)
                    end
                else
                    while test $a -gt 1; and test (__surround_cls $__surround_chars[(math $a - 1)] $big) = s
                        set a (math $a - 1)
                    end
                end
            end
            printf '%s\n' $a $b
        case '*'
            return 1
    end
end

# Prompts. Instead of `read`, which redraws the prompt line, the command line itself becomes the input
# field: stash the buffer, let the user type, put it back.

# usage: __surround_ask <count> <function> [args...]; runs <function> args... answers... once <count> answers are in
function __surround_ask
    set -g __surround_ask_n $argv[1]
    set -g __surround_ask_fn $argv[2]
    set -e argv[1 2]
    set -g __surround_ask_args $argv
    set -g __surround_ask_got
    set -g __surround_saved_buf (commandline -b | string collect)
    set -g __surround_saved_cur (commandline -C)
    commandline -r -- ''
    set -g fish_bind_mode surround_input
end

function __surround_ask_restore
    commandline -r -- $__surround_saved_buf
    commandline -C $__surround_saved_cur
    set -g fish_bind_mode default
end

function __surround_ask_done
    set -a __surround_ask_got (commandline -b | string collect)
    if test (count $__surround_ask_got) -lt $__surround_ask_n
        commandline -r -- ''
        return
    end
    __surround_ask_restore
    set -l fn $__surround_ask_fn
    set -l args $__surround_ask_args $__surround_ask_got
    set -e __surround_ask_n __surround_ask_fn __surround_ask_args __surround_ask_got __surround_saved_buf __surround_saved_cur
    $fn $args
    commandline -f end-undo-group
end

function __surround_ask_cancel
    __surround_ask_restore
    commandline -f end-undo-group
    set -e __surround_ask_n __surround_ask_fn __surround_ask_args __surround_ask_got __surround_saved_buf __surround_saved_cur
end

# usage: __surround_add_run <first> <last> <char> [prompt answers...]
function __surround_add_run
    set -l d (__surround_delims $argv[3..-1]); or return
    __surround_apply $argv[1] (math $argv[1] - 1) (math $argv[2] + 1) $argv[2] $d
end

# usage: __surround_add <first> <last> <char>; asks for what the delimiters need, then adds them
function __surround_add
    set -l n (__surround_needs $argv[3])
    if test $n -gt 0
        __surround_ask $n __surround_add_run $argv
    else
        __surround_add_run $argv
    end
end

# usage: __surround_delete <char>
function __surround_delete
    __surround_load
    set -l s (__surround_select $argv[1]); or return
    set s (__surround_trim $argv[1] $s)
    __surround_apply $s[1] $s[2] $s[3] $s[4] '' ''
end

# usage: __surround_change_run <target> <new> [prompt answers...]
# <new> is empty for t, T and f targets: they take their replacement from the prompt
function __surround_change_run
    set -l target (__surround_alias $argv[1])
    set -l new $argv[2]
    set -e argv[1 2]
    __surround_load
    set -l s (__surround_select $target); or return
    if test -n "$new"
        set -l d (__surround_delims $new $argv); or return
        set s (__surround_trim $target $s)
        __surround_apply $s[1] $s[2] $s[3] $s[4] $d
        return
    end
    set -l d (__surround_delims t $argv[1])
    switch $target
        case t
            set -l name (string join '' -- $__surround_chars[$s[1]..$s[2]] | string match -rg '^<([^\s<>]*)')
            __surround_apply (math $s[1] + 1) (math $s[1] + (string length -- "$name")) (math $s[3] + 2) (math $s[4] - 1) (string replace -r '^<(.*)>$' '$1' -- $d[1]) (string replace -r '^</(.*)>$' '$1' -- $d[2])
        case T
            __surround_apply (math $s[1] + 1) (math $s[2] - 1) (math $s[3] + 2) (math $s[4] - 1) (string replace -r '^<(.*)>$' '$1' -- $d[1]) (string replace -r '^</(.*)>$' '$1' -- $d[2])
        case f
            set -l w $s[2]
            while test $w -gt $s[1]; and string match -qr -- '^[[:alnum:]_]$' $__surround_chars[(math $w - 1)]
                set w (math $w - 1)
            end
            __surround_apply $w (math $s[2] - 1) (math $s[4] + 1) $s[4] $argv[1] ''
    end
end

# usage: __surround_change <target> <new>
function __surround_change
    set -l n (__surround_needs $argv[2])
    if test $n -gt 0
        __surround_ask $n __surround_change_run $argv
    else
        __surround_change_run $argv
    end
end

# step 1 of cs: remember the target, then wait for the new char (or the prompt for t, T and f)
function __surround_change_target
    if contains -- $argv[1] t T f
        __surround_ask 1 __surround_change_run $argv[1] ''
    else
        set -g __surround_op c2 $argv[1]
        set -g fish_bind_mode surround_key
    end
end

# usage: __surround_ys <motion> <char>
function __surround_ys
    __surround_load
    set -l r (__surround_motion $argv[1]); or return
    __surround_add $r $argv[2]
end

# Waiting for a char uses a bind mode with a catch-all binding that lets fish insert the key into the
# buffer, where __surround_key picks it up and undoes the insertion. That takes any key without
# binding each one, and ignores non-printing keys such as Escape.

function __surround_begin
    # one undo step per action: the group spans the captured keys, prompts and the edit itself
    commandline -f begin-undo-group
    set -g __surround_op $argv
    # the selection must be captured now; typing a key would replace it
    test $argv[1] = v; and set -g __surround_op v (math (commandline -B) + 1) (commandline -E)
    set -g fish_bind_mode surround_key
end

function __surround_snap
    set -g __surround_len (string length -- (commandline -b | string collect))
end

# prints the key self-insert just added; returns 1 if it didn't add a printable one
function __surround_key
    set -l buf (commandline -b | string collect)
    test (string length -- $buf) -eq (math $__surround_len + 1); or return 1
    set -l c (commandline -C)
    set -l k (string sub -s $c -l 1 -- $buf)
    commandline -r -- (string sub -l (math $c - 1) -- $buf | string collect)(string sub -s (math $c + 1) -- $buf | string collect)
    commandline -C (math $c - 1)
    string match -qr -- '^[[:print:]]$' $k; or return 1
    printf '%s\n' $k
end

function __surround_step
    set -l k (__surround_key)
    set -l op $__surround_op
    set -e __surround_op
    set -g fish_bind_mode default
    test -n "$k"; or begin
        commandline -f end-undo-group
        return
    end
    switch $op[1]
        case d
            __surround_delete $k
        case c
            __surround_change_target $k
        case c2
            __surround_change $op[2] $k
        case y
            __surround_ys $op[2] $k
        case v
            __surround_add $op[2] $op[3] $k
    end
    # still waiting for a second key or a prompt answer: keep the group open
    test "$fish_bind_mode" = default; and commandline -f end-undo-group
end

function __surround_bindings
    bind -M default d,s '__surround_begin d' repaint-mode
    bind -M default c,s '__surround_begin c' repaint-mode
    bind -M visual S '__surround_begin v' end-selection repaint-mode
    for m in 'i,w iw' 'i,W iW' 'a,w aw' 'a,W aW' '$ $' 's ss'
        set -l p (string split ' ' -- $m)
        bind -M default y,s,$p[1] "__surround_begin y "(string escape -- $p[2]) repaint-mode
    end
    bind -M surround_key '' __surround_snap self-insert __surround_step repaint-mode

    bind -M surround_input '' self-insert
    bind -M surround_input enter __surround_ask_done repaint-mode
    bind -M surround_input ctrl-j __surround_ask_done repaint-mode
    bind -M surround_input escape __surround_ask_cancel repaint-mode
    bind -M surround_input ctrl-c __surround_ask_cancel repaint-mode
    bind -M surround_input backspace backward-delete-char
    bind -M surround_input ctrl-h backward-delete-char
    bind -M surround_input ctrl-w backward-kill-word
    bind -M surround_input ctrl-u backward-kill-line
    bind -M surround_input left backward-char
    bind -M surround_input right forward-char
end
