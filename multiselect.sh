#!/bin/bash
#####################################################################################################################
#
# R5: Update 22/11/2021: EML
#   - Menu display issue when exceeding the screen size
#   - Restrict the selection to the last 40 files
# R6: Update 23/11/2021: EML
#   - Automatically determine the screen size to ensure proper display
#   - Display a compatible menu accordingly
#   - Add left/right arrows for navigating a multi-column menu with configurable columns
# R7: Update 24/11/2021: EML
#   - Bug fix for supporting any version of Bash
#   - For version < 4.3: unknown "local -n" option ==> function xxx_43m
#   - For version > 4.3: recognized "local -n" option ==> function xxx_43p
#   - Option to select all or none
# R8: Update 24/11/2021: EML
#   - Fix checkwinsize
#   - Fix window positioning
#
#
# SOURCES:
#   [source URLs]
#
#####################################################################################################################
export black='\e[0;30m'
export dark_gray='\e[1;30m'
export dark_red='\e[1;31m'
export red='\e[0;31m'
export magenta='\e[1;31m'
export dark_green='\e[0;32m'
export light_green='\e[1;32m'
export orange='\e[0;33m'
export yellow='\e[1;33m'
export dark_blue='\e[0;34m'
export light_blue='\e[1;34m'
export dark_purple='\e[0;35m'
export light_purple='\e[1;35m'
export dark_cyan='\e[0;36m'
export light_cyan='\e[1;36m'
export light_grey='\e[0;37m'
export white='\e[1;37m'
export default='\e[0;m'

# function checkwinsize {
#     local __items=$1
#     local __lines=$2
#     local __err=$3

#     if [ "$__items" -ge "$__lines" ]; then
#         echo "The size of your window does not allow the menu to be displayed correctly..."
#         return 1
#     else
#         echo "The size of your window is $__lines lines, compatible with the menu of $__items items..."
#         return 0
#     fi
# }

function multiselect_43p {
    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on()   { printf "%b" "$ESC[?25h"; }
    cursor_blink_off()  { printf "%b" "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }

    local return_value=$1
    local colmax=$2
    local offset=$3
    local -n options=$4
    local -n defaults=$5
    local title=$6
    local LINES=$(tput lines)
    local COLS=$(tput cols)

    clear

    # checkwinsize $(( ${#options[@]}/$colmax )) $LINES
    # err=$(checkwinsize $(( ${#options[@]}/colmax )) $(( LINES - 2)))

    # if [[ ! $err == 0 ]]; then
    #     echo "The size of your window is $LINES lines, incompatible with the menu of ${#_list[@]} items..."
    #     cursor_to "$lastrow"
    #     exit
    # fi

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    cursor_to $(( LINES - 2 ))
    printf "_%.s" $(seq "$COLS")
    echo -e "$bleuclair / $title / | $dark_green select : key [space] | (un)select all : key ([n])[a] | move : arrow up/down/left/right or keys k/j/l/h | validation : [enter] $default\n" | column 

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local lastcol=$(get_cursor_col)
    local startrow=1
    local startcol=1

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = "h" ]]; then echo left; fi;
        if [[ $key = "l" ]]; then echo right; fi;
        if [[ $key = "a" ]]; then echo all; fi;
        if [[ $key = "n" ]]; then echo none; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
            if [[ $key = [C || $key = l ]]; then echo right; fi;
            if [[ $key = [D || $key = h ]]; then echo left;  fi;
        fi
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    toggle_option_multicol() {
        local option_row=$1
        local option_col=$2

        if [[ $option_row -eq -10 ]] && [[ $option_row -eq -10 ]]; then
            for ((option=0; option<${#selected[@]}; option++)); do
                selected[option]=true
            done
        else
            if [[ $option_row -eq -100 ]] && [[ $option_row -eq -100 ]]; then
                for ((option=0; option<${#selected[@]}; option++)); do
                    selected[option]=false
                done
            else
                option=$(( option_col + option_row * colmax ))

                if [[ ${selected[option]} == true ]]; then
                    selected[option]=false
                else
                    selected[option]=true
                fi
            fi
        fi
    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$(( curr_col + curr_row * colmax ))

        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[1;32m✔\e[0m]"
            fi

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local active_row=0
    local active_col=0

    while true; do
        print_options_multicol $active_col $active_row

        # user key control
        case $(key_input) in
            space)  
                    toggle_option_multicol $active_row $active_col
                    ;;
            enter)  
                    print_options_multicol -1 -1
                    break
                    ;;
            up)     
                    ((active_row--))
                    if [ $active_row -lt 0 ]; then 
                        active_row=0
                    fi;;
            down)   
                    ((active_row++))
                    if [ $active_row -ge $(( ${#options[@]} / colmax )) ]; then 
                        active_row=$(( ${#options[@]} / colmax ))
                    fi
                    ;;
            left)   
                    ((active_col=active_col - 1))
                    if [ $active_col -lt 0 ]; then 
                        active_col=0; 
                    fi
                    ;;
            right)  
                    ((active_col=active_col + 1))
                    if [ $active_col -ge "$colmax" ]; then 
                        active_col=$(( colmax - 1 ))
                    fi
                    ;;
            all)    
                    toggle_option_multicol -10 -10
                    ;;
            none)   
                    toggle_option_multicol -100 -100
                    ;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    eval "$return_value"='("${selected[@]}")'
    clear
}

function multiselect_43m {
    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }

    local return_value=$1
    local colmax=$2
    local offset=$3
    local size=$4
    shift 4

    local options=("$@")
    shift "$size"

    for i in $(seq 0 "$size"); do
        unset "options[$(( i + size ))]"
    done

    local defaults=("$@")
    shift "$size"

    unset "defaults[$size]"

    local title="$@"

    local LINES=$(tput lines)
    local COLS=$(tput cols)

    clear

    # checkwinsize $(( ${#options[@]}/$colmax )) $LINES
    # echo ${#options[@]}/$colmax
    # exit

    # err=$(checkwinsize $(( ${#options[@]}/colmax )) $(( LINES - 2)))
    # if [[ ! $err == 0 ]]; then
    #     echo "La taille de votre fenêtre est de $LINES lignes, incompatible avec le menu de ${#_list[@]} items..."
    #     cursor_to "$lastrow"
    #     exit
    # fi

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    cursor_to $(( LINES - 2 ))
    printf "_%.s" $(seq "$COLS")
    echo -e "$bleuclair / $title / | $dark_green select : key [space] | (un)select all : key ([n])[a] | move : arrow up/down/left/right or keys k/j/l/h | validation : [enter] $default\n" | column 

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local lastcol=$(get_cursor_col)
    local startrow=1
    local startcol=1

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = "h" ]]; then echo left; fi;
        if [[ $key = "l" ]]; then echo right; fi;
        if [[ $key = "a" ]]; then echo all; fi;
        if [[ $key = "n" ]]; then echo none; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
            if [[ $key = [C || $key = l ]]; then echo right; fi;
            if [[ $key = [D || $key = h ]]; then echo left;  fi;
        fi
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    toggle_option_multicol() {
        local option_row=$1
        local option_col=$2

        if [[ $option_row -eq -10 ]] && [[ $option_row -eq -10 ]]; then
            for ((option=0; option<${#selected[@]}; option++)); do
                selected[option]=true
            done
        else
            if [[ $option_row -eq -100 ]] && [[ $option_row -eq -100 ]]; then
                for ((option=0; option<${#selected[@]}; option++)); do
                    selected[option]=false
                done
            else
                option=$(( option_col + option_row * colmax ))

                if [[ ${selected[option]} == true ]]; then
                    selected[option]=false
                else
                    selected[option]=true
                fi
            fi
        fi
    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$(( curr_col + curr_row * colmax ))

        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[1;32m✔\e[0m]"
            fi

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row

        # user key control
        case $(key_input) in
            space)  toggle_option_multicol $active_row $active_col;;
            enter)  print_options_multicol -1 -1; break;;
            up)     ((active_row--))
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++))
                    if [ $active_row -ge $(( ${#options[@]} / colmax )) ]; then active_row=$(( ${#options[@]} / colmax )); fi;;
            left)   ((active_col=active_col - 1))
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)  ((active_col=active_col + 1))
                    if [ $active_col -ge "$colmax" ]; then active_col=$(( colmax - 1 )); fi;;
            all)    toggle_option_multicol -10 -10;;
            none)   toggle_option_multicol -100 -100;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    eval "$return_value"='("${selected[@]}")'
    clear
}

LINES=$( tput lines )
COLS=$( tput cols )

clear

for ((i=0; i<256; i++)); do
    _list[i]="Choice $i"
    _preselection_list[i]=false
done

colmax=7
offset=$(( COLS / colmax ))

VERSION=$(echo "$BASH_VERSION" | awk -F\( '{print $1}' | awk -F. '{print $1"."$2}')

if [ $(echo "$VERSION >= 4.3" | bc -l) -eq 1 ]; then
    multiselect_43p result $colmax $offset _list _preselection_list "CHOICE OF REPOSITORY" 
else
    multiselect_43m result $colmax $offset ${#_list[@]} "${_list[@]}" "${_preselection_list[@]}" "CHOICE OF REPOSITORY" 
fi

idx=0
dbg=1
status=1
for option in "${_list[@]}"; do
    if  [[ ${result[idx]} == true ]]; then
        if [ $dbg -eq 0 ]; then
                echo -e "$option\t=> ${result[idx]}"
        fi
        TARGET=$(echo $TARGET ${option})
        status=0
    fi  
        ((idx++))
done

if [ $status -eq 0 ] ; then
    echo -e "$dark_green Selection of items:\n$light_green $TARGET $default"
else
    echo -e "$dark_green No items selected... $default"
    exit
fi

while true; do
    case `key_input` in
            enter)  break;;
        esac
done

clear