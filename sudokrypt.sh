#!/bin/bash

# ==============================================================================
# SUDOKRYPT: INTERACTIVE GAME (Final)
# Features: Irregular Regions, Unique Solutions, Game Loop, Full Reveal on Loss
# Author: Levi Wanner
# Date: January 25, 2026
# ==============================================================================

# Configuration
SIZE=5
TOTAL_CELLS=$((SIZE * SIZE))

# File path to store the score
SCORE_FILE="$HOME/.sudokrypt_score"

# Game State
SELECTED_ROW=0
GUESSES_USED=1
MAX_GUESSES=12
declare -a GAME_MSG=()

# Colors
COLORS=("\033[41m" "\033[42m" "\033[43m" "\033[44m" "\033[45m")
BOLD="\033[1m"
UNDERLINE="\033[4m"
RESET="\033[0m"
BLACK_TEXT="\033[30m"
RED_TEXT="\033[31m"
GREEN_TEXT="\033[32m"
ORANGE_TEXT="\033[33m"
BLUE_TEXT="\033[34m"
PURPLE_TEXT="\033[35m"
RED_BG="${COLORS[0]}"
GREEN_BG="${COLORS[1]}"
ORANGE_BG="${COLORS[2]}"
BLUE_BG="${COLORS[3]}"
PURPLE_BG="${COLORS[4]}"

# Global Arrays
declare -a regions
declare -a solution
declare -a puzzle
declare -a reg_counts
declare -a clues_per_region

# Check if file exists, read it. If not, start at 0.
if [[ -f "$SCORE_FILE" ]]; then
    high_score=$(cat "$SCORE_FILE")
else
    high_score=0
fi

# ==============================================================================
# 1. GENERATOR CORE
# ==============================================================================

# add_to_frontier: Adds neighboring cells to the frontier for region growing.
add_to_frontier() {
    local idx=$1; local r_id=$2
    local row=$((idx / SIZE)); local col=$((idx % SIZE))
    [[ $row -gt 0 ]] && frontier+=("$((idx - SIZE)):$r_id")
    [[ $row -lt $((SIZE - 1)) ]] && frontier+=("$((idx + SIZE)):$r_id")
    [[ $col -gt 0 ]] && frontier+=("$((idx - 1)):$r_id")
    [[ $col -lt $((SIZE - 1)) ]] && frontier+=("$((idx + 1)):$r_id")
}

# generate_map: Creates the irregular Sudoku regions using a region-growing algorithm.
generate_map() {
    while true; do
        for ((i=0; i<TOTAL_CELLS; i++)); do regions[$i]=-1; done
        for ((i=0; i<5; i++)); do reg_counts[$i]=0; done
        local frontier=()
        for ((r_id=0; r_id<5; r_id++)); do
            while true; do
                local s=$((RANDOM % TOTAL_CELLS))
                if [[ ${regions[$s]} -eq -1 ]]; then
                    regions[$s]=$r_id; reg_counts[$r_id]=1
                    add_to_frontier $s $r_id; break
                fi
            done
        done
        local filled=5
        while [[ $filled -lt $TOTAL_CELLS && ${#frontier[@]} -gt 0 ]]; do
            local f_idx=$((RANDOM % ${#frontier[@]}))
            local pick=${frontier[$f_idx]}
            local new_frontier=()
            for ((i=0; i<${#frontier[@]}; i++)); do [[ $i -ne $f_idx ]] && new_frontier+=("${frontier[$i]}"); done
            frontier=("${new_frontier[@]}")
            local c_idx=${pick%:*}
            local r_id=${pick#*:}
            if [[ ${regions[$c_idx]} -eq -1 && ${reg_counts[$r_id]} -lt 5 ]]; then
                regions[$c_idx]=$r_id; ((reg_counts[$r_id]++)); ((filled++))
                add_to_frontier $c_idx $r_id
            fi
        done
        [[ $filled -eq 25 ]] && break
    done
}

# is_safe_solution: Checks if a number can be safely placed in the solution board.
is_safe_solution() {
    local idx=$1; local num=$2
    local r=$((idx / SIZE)); local c=$((idx % SIZE)); local reg=${regions[$idx]}
    for ((i=0; i<SIZE; i++)); do
        [[ ${solution[$((r * SIZE + i))]} -eq $num ]] && return 1
        [[ ${solution[$((i * SIZE + c))]} -eq $num ]] && return 1
    done
    for ((i=0; i<TOTAL_CELLS; i++)); do
        [[ ${regions[$i]} -eq $reg && ${solution[$i]} -eq $num ]] && return 1
    done
    return 0
}

# is_safe_puzzle: Checks if a number can be safely placed in the puzzle board.
is_safe_puzzle() {
    local idx=$1; local num=$2
    local r=$((idx / SIZE)); local c=$((idx % SIZE)); local reg=${regions[$idx]}
    for ((i=0; i<SIZE; i++)); do
        [[ ${puzzle[$((r * SIZE + i))]} -eq $num ]] && return 1
        [[ ${puzzle[$((i * SIZE + c))]} -eq $num ]] && return 1
    done
    for ((i=0; i<TOTAL_CELLS; i++)); do
        [[ ${regions[$i]} -eq $reg && ${puzzle[$i]} -eq $num ]] && return 1
    done
    return 0
}

# solve_full_board: Solves the Sudoku puzzle using a backtracking algorithm.
solve_full_board() {
    local idx=$1
    [[ $idx -eq $TOTAL_CELLS ]] && return 0
    local nums=(1 2 3 4 5)
    # Shuffle numbers
    for ((i=0; i<5; i++)); do 
        local j=$((RANDOM % 5))
        local t=${nums[$i]}
        nums[$i]=${nums[$j]}
        nums[$j]=$t
    done
    for n in "${nums[@]}"; do
        if is_safe_solution $idx $n; then
            solution[$idx]=$n
            if solve_full_board $((idx + 1)); then return 0; fi
            solution[$idx]=0 # backtrack
        fi
    done
    return 1
}

# count_solutions: Counts the number of solutions for a given puzzle state.
count_solutions() {
    local idx=$1
    # Stop if more than one solution is found
    [[ $solution_count -gt 1 ]] && return 
    
    if [[ $idx -eq $TOTAL_CELLS ]]; then
        ((solution_count++))
        return
    fi
    
    if [[ ${puzzle[$idx]} -ne 0 ]]; then
        count_solutions $((idx + 1))
        return
    fi
    
    for n in 1 2 3 4 5; do
        if is_safe_puzzle $idx $n; then
            puzzle[$idx]=$n
            count_solutions $((idx + 1))
            puzzle[$idx]=0 # backtrack
        fi
    done
}

# create_puzzle: Creates a puzzle with a unique solution by removing cells from a full board.
create_puzzle() {
    for ((i=0; i<TOTAL_CELLS; i++)); do puzzle[$i]=${solution[$i]}; done
    for ((i=0; i<5; i++)); do clues_per_region[$i]=5; done
    local indices=(); for ((i=0; i<TOTAL_CELLS; i++)); do indices+=($i); done
    for ((i=0; i<TOTAL_CELLS; i++)); do local j=$((RANDOM % TOTAL_CELLS)); local tmp=${indices[$i]}; indices[$i]=${indices[$j]}; indices[$j]=$tmp; done

    for idx in "${indices[@]}"; do
        local r_id=${regions[$idx]}
        if [[ ${clues_per_region[$r_id]} -le 1 ]]; then continue; fi
        local backup=${puzzle[$idx]}
        puzzle[$idx]=0
        ((clues_per_region[$r_id]--))
        solution_count=0
        count_solutions 0
        if [[ $solution_count -ne 1 ]]; then puzzle[$idx]=$backup; ((clues_per_region[$r_id]++)); fi
    done
}

# ==============================================================================
# 2. RENDERER
# ==============================================================================

# print_header: Prints the stylized game header with the BYPASSED count.
print_header() {
    local total_wins=$1
    echo -e "${PURPLE_TEXT}       ▌  ${RESET}${BLUE_TEXT}▌       ▗  ${RESET}"
    echo -e "${PURPLE_TEXT}  ▞▘▌▌▞▌▞▖${RESET}${BLUE_TEXT}▙▘▛▘▌▌▛▖▜▘ ${RESET}"
    echo -e "${PURPLE_TEXT}  ▟▘▚▘▚▌▚▘${RESET}${BLUE_TEXT}▛▖▌ ▚▌▙▘▐▖ ${RESET}"
    echo -e "${BLUE_TEXT}              ▄▘▌${RESET}v1.0"
    echo -e "────────────────────────"
    echo -e "MAX RECOVERY: $high_score KB"
    echo -e "────────────────────────"
}

# print_puzzle: Renders the Sudoku puzzle grid, including the current selection and game state.
print_puzzle() {
    local top_sel="╔══╤═══╤═══╤═══╤═══╤═══╗"
    local bot_sel="╚══╧═══╧═══╧═══╧═══╧═══╝"
    local top_norm="┌──┬───┬───┬───┬───┬───┐"
    local mid_norm="├──┼───┼───┼───┼───┼───┤"
    local bot_norm="└──┴───┴───┴───┴───┴───┘"

    print_header "$total_wins"
    if [[ $SELECTED_ROW -eq 0 ]]; then echo "$top_sel"; else echo "$top_norm"; fi

    for ((r=0; r<SIZE; r++)); do
        local left_edge="│"; local inner_sep="│"; local right_edge="│"
        
        # If row is selected (and game is ongoing), use bold borders
        if [[ $r -eq $SELECTED_ROW && $SELECTED_ROW -lt 5 ]]; then
            left_edge="║"; right_edge="║"
        fi

        printf "%sV%d%s" "$left_edge" "$((r+1))" "$inner_sep"

        for ((c=0; c<SIZE; c++)); do
            local idx=$((r * SIZE + c))
            local r_id=${regions[$idx]}
            local val=${puzzle[$idx]}
            local current_sep="$inner_sep"
            [[ $c -eq $((SIZE - 1)) ]] && current_sep="$right_edge"

            # Fog of War Logic
            if [[ $r -le $SELECTED_ROW || $SELECTED_ROW -eq 5 ]]; then
                # Solved rows or game over: show region colors
                if [[ "$val" -eq "0" ]]; then
                    printf "${COLORS[$r_id]}   ${RESET}%s" "$current_sep"
                else
                    printf "${COLORS[$r_id]}${BLACK_TEXT} %d ${RESET}%s" "$val" "$current_sep"
                fi
            else
                # Unsolved rows: hide region colors
                if [[ "$val" -eq "0" ]]; then
                    printf "   %s" "$current_sep"
                else
                    printf " %d %s" "$val" "$current_sep"
                fi
            fi
        done
        echo ""
        
        if [[ $r -eq $SELECTED_ROW && $SELECTED_ROW -lt 5 ]]; then
            echo "$bot_sel"
        elif [[ $r -lt $((SIZE - 1)) ]]; then
            if [[ $((r + 1)) -eq $SELECTED_ROW && $SELECTED_ROW -lt 5 ]]; then
                echo "$top_sel"
            else
                echo "$mid_norm"
            fi
        else
            echo "$bot_norm"
        fi
    done
}

# ==============================================================================
# 3. GAME LOGIC
# ==============================================================================

# get_hints: Calculates the number of correct digits in the correct position.
get_hints() {
    local guess=$1
    local solution_row=$2
    correct_pos=0
    
    # First pass: count correct positions
    for ((i=0; i<SIZE; i++)); do
        if [[ "${guess:$i:1}" == "${solution_row:$i:1}" ]]; then
            ((correct_pos++))
        fi
    done
}

# print_start_screen: Displays the initial header and system briefing.
print_start_screen() {
    clear
    print_header "$high_score"
    echo -e "${PURPLE_TEXT}[SYSTEM BRIEFING]${RESET}"
    echo ""
    echo -e "INPUT FORMAT: ${UNDERLINE}#####${RESET}"
    echo -e "GUESS ${UNDERLINE}5${RESET} NUMBERS ${UNDERLINE}(1-5)${RESET}"
    echo -e "UNIQUE IN EACH OF THE:"
    echo -e "ROWS, COLUMNS, REGIONS."
    echo -e "${BLUE_TEXT}[i]${RESET} REGIONS = ${RED_TEXT}■${RESET} ${GREEN_TEXT}■${RESET} ${ORANGE_TEXT}■${RESET} ${BLUE_TEXT}■${RESET} ${PURPLE_TEXT}■${RESET}"
    echo ""
    echo -e "SIGNAL X/5 REVEAL HOW"
    echo -e "MANY DIGITS ARE IN"
    echo -e "THE CORRECT POSITION."
    echo ""
    echo -e "${UNDERLINE}${MAX_GUESSES}${RESET} TRIES OR LOCKOUT."
    echo -e "────────────────────────"
    read -p "$(echo -e "${ORANGE_TEXT}[ENTER]${RESET} TO INITIALIZE")"
}

# add_game_msg: Adds a message to the game message history.
add_game_msg() {
    local new_msg=$1
    GAME_MSG+=("$new_msg")
    if [[ ${#GAME_MSG[@]} -gt 3 ]]; then
        GAME_MSG=("${GAME_MSG[@]:$(( ${#GAME_MSG[@]} - 3 ))}")
    fi
}

# play_game: Main game logic.
play_game() {
    # Hide Cursor
    tput civis

    # Print Start Screen
    print_start_screen
    clear
    
    # Generate Game
    print_header "$high_score"
    echo -e "BOOTING REMOTE DRIVE..."
    while true; do
        generate_map
        for ((i=0; i<TOTAL_CELLS; i++)); do solution[$i]=0; done
        if solve_full_board 0; then
            create_puzzle
            solution_count=0
            count_solutions 0
            if [[ $solution_count -eq 1 ]]; then break; fi
        fi
    done

    # Restore Cursor
    tput cnorm

    # Game Loop
    while [[ $SELECTED_ROW -lt 5 && $GUESSES_USED -le $MAX_GUESSES ]]; do
        clear
        print_puzzle
        
        # Print Status Message
        if [[ ${#GAME_MSG[@]} -gt 0 ]]; then
            for msg in "${GAME_MSG[@]}"; do
                echo -e "$msg"
            done
        fi

        # Prompt
        read -p "$(echo -e "${BOLD}V$((SELECTED_ROW+1)) ($GUESSES_USED / $MAX_GUESSES): ${RESET}")" user_input

        # 1. Validation: Length 5, Digits 1-5
        if [[ ! $user_input =~ ^[1-5]{5}$ ]]; then
            add_game_msg "${RED_TEXT}SYNTAX ERR: USE 1-5${RESET}"
            continue
        fi

        # 2. Check Logic
        local correct_str=""
        for ((c=0; c<SIZE; c++)); do
            correct_str+="${solution[$((SELECTED_ROW * SIZE + c))]}"
        done

        get_hints "$user_input" "$correct_str"

        if [[ "$correct_pos" -eq "$SIZE" ]]; then
            # CORRECT!
            add_game_msg "${GREEN_TEXT}VECTOR $((SELECTED_ROW + 1)) STABLE: $user_input${RESET}"
            
            # Reveal the row in the visual board
            for ((c=0; c<SIZE; c++)); do
                puzzle[$((SELECTED_ROW * SIZE + c))]=${solution[$((SELECTED_ROW * SIZE + c))]}
            done
            
            ((SELECTED_ROW++))
            ((GUESSES_USED++))
        else
            # INCORRECT - Show Mastermind hints
            add_game_msg "${RED_TEXT}SIGNAL $correct_pos/5 FAIL: $user_input${RESET}"
            ((GUESSES_USED++))
        fi
    done

    # End Game State
    clear
    if [[ $SELECTED_ROW -eq 5 ]]; then
        # UPDATED SCORE
        # ┌──────┬─────────────────┬────────────┐
        # │ Used │ Left │ Formula  │ Score (KB) │
        # ├──────┼──────┼──────────┼────────────┤
        # │ 5    │ 8    │ 8³ * 100 │ 51200      │
        # │ 6    │ 7    │ 7³ * 100 │ 34300      │
        # │ 7    │ 6    │ 6³ * 100 │ 21600      │
        # │ 8    │ 5    │ 5³ * 100 │ 12500      │
        # │ 9    │ 4    │ 4³ * 100 │ 6400       │
        # │ 10   │ 3    │ 3³ * 100 │ 2700       │
        # │ 11   │ 2    │ 2³ * 100 │ 800        │
        # │ 12   │ 1    │ 1³ * 100 │ 100        │
        # └─────────────┴──────────┴────────────┘
        local current_score=$(( (MAX_GUESSES - GUESSES_USED + 1) * (MAX_GUESSES - GUESSES_USED + 1) * (MAX_GUESSES - GUESSES_USED + 1) * 100 ))
        if [[ $current_score -gt $high_score ]]; then
            high_score=$current_score
            echo "$high_score" > "$SCORE_FILE"
        fi
        print_puzzle
        echo -e "${GREEN_BG}${BLACK_TEXT}[SUDOKRYPT BYPASSED]${RESET}"
        echo -e "DATA RECOVERED: $current_score KB"
    else
        # REVEAL SOLUTION ON LOSS
        # 1. Fill the puzzle with the solution
        for ((i=0; i<TOTAL_CELLS; i++)); do puzzle[$i]=${solution[$i]}; done
        # 2. Deselect rows (set to 5 so no row is highlighted)
        SELECTED_ROW=5
        
        print_puzzle
        echo -e "${RED_BG}${BLACK_TEXT}[LOCAL DRIVE WIPED]${RESET}"
        echo -e "RECOVERY KEY ATTACHED"
    fi
}

# Run
play_game