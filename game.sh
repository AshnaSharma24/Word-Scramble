#!/bin/bash

# Word Scrabble Game

ALL_WORDS=(
  # Easy (3–5 letters)
  "bash" "book" "pen" "mango" "apple" "india" "chair" "glass" "grape" "peach" "linux" "kiwi" "tiger" 

  # Medium (6–7 letters)
  "ubuntu" "mirror" "banana" "rocket" "mexico" "wallet" "guitar" "laptop" "kernel" "circle" "canada" "python"

  # Hard (8+ letters)
  "terminal" "computer" "pineapple" "australia" "elephant" "notebook" "security" "keyboard" "mountains" "container" "database" "firewall"
)

SCORE=0
TEMPFILE=$(mktemp)
LEADERBOARD="leaderboard.txt"

# --- Welcome Screen ---
dialog --title "🎉 Welcome!" --msgbox "Welcome to the Word Scramble Game!" 6 40

# --- Instructions ---
dialog --title "📜 How to Play" --msgbox "Instructions:\n\n• You will see a scrambled word.\n• Try to guess the correct word.\n• Each correct answer gives you 10 points.\n• You can select difficulty and number of rounds.\n• Leaderboard is shown at the end." 12 50

# --- Ask to Play ---
dialog --yesno "Do you want to play the game?" 7 40
answer=$?
if [[ $answer -ne 0 ]]; then
    dialog --msgbox "Maybe next time! Goodbye!" 6 40
    clear
    rm -f "$TEMPFILE"
    exit 0
fi

# --- Username ---
dialog --title "Enter Name" --inputbox "Enter your name to start the Word Scramble Game:" 8 50 2>$TEMPFILE
USERNAME=$(<"$TEMPFILE")
if [[ -z "$USERNAME" ]]; then
    dialog --msgbox "Username cannot be empty. Exiting." 6 40
    clear
    rm -f "$TEMPFILE"
    exit 1
fi

# --- Difficulty Level ---
dialog --title "Select Difficulty" --menu "Choose level:" 12 40 3 \
1 Easy \
2 Medium \
3 Hard 2>$TEMPFILE
DIFFICULTY=$(<"$TEMPFILE")

# --- Filter words ---
case $DIFFICULTY in
  1) WORDS=($(for word in "${ALL_WORDS[@]}"; do [[ ${#word} -le 5 ]] && echo "$word"; done)) ;;
  2) WORDS=($(for word in "${ALL_WORDS[@]}"; do [[ ${#word} -ge 6 && ${#word} -le 7 ]] && echo "$word"; done)) ;;
  3) WORDS=($(for word in "${ALL_WORDS[@]}"; do [[ ${#word} -gt 7 ]] && echo "$word"; done)) ;;
esac

# --- Max Rounds ---
dialog --title "Game Rounds" --inputbox "How many rounds do you want to play?" 8 50 2>$TEMPFILE
MAX_ROUNDS=$(<"$TEMPFILE")
if ! [[ "$MAX_ROUNDS" =~ ^[0-9]+$ ]]; then
    dialog --msgbox "Invalid input. Defaulting to 5 rounds." 6 40
    MAX_ROUNDS=5
fi

# --- Scramble function ---
scramble_word() {
    echo "$1" | fold -w1 | shuf | tr -d '\n'
}

# --- Blank display function ---
blank_word() {
    echo "${1//?/_ }"
}

# --- Countdown function ---
countdown_timer() {
    for i in {3..1}; do
        dialog --infobox "Next word in $i..." 5 40
        sleep 1
    done
}

# --- Game Loop ---
ROUND=1
while (( ROUND <= MAX_ROUNDS )); do
    countdown_timer

    word=${WORDS[$RANDOM % ${#WORDS[@]}]}
    scrambled=$(scramble_word "$word")
    blanks=$(blank_word "$word")

    dialog --title "Round $ROUND" \
           --inputbox "Guess the word:\n\nScrambled: $scrambled\nBlanks: $blanks" 12 50 2>$TEMPFILE
    guess=$(<"$TEMPFILE")

    if [[ "$guess" == "$word" ]]; then
        dialog --msgbox "✅ Correct!" 6 30
        SCORE=$((SCORE + 10))
    else
        dialog --msgbox "❌ Incorrect! The word was: $word" 6 50
    fi

    # If not last round, ask to continue
    if (( ROUND < MAX_ROUNDS )); then
        dialog --yesno "Do you want to continue to next round?" 7 50
        answer=$?
        if [[ $answer -ne 0 ]]; then
            break
        fi
    fi

    ROUND=$((ROUND + 1))
done

# --- Final Score ---
dialog --title "Game Over" --msgbox "🎮 Thank you, $USERNAME!\nFinal score: $SCORE" 8 50

# --- Save to Leaderboard ---
echo "$USERNAME - $SCORE points" >> "$LEADERBOARD"

# --- Display Leaderboard ---
dialog --title "🏆 Leaderboard" --textbox "$LEADERBOARD" 20 60

# --- Cleanup ---
rm -f "$TEMPFILE"
clear
