# SUDOKRYPT

A simple, terminal-based puzzle game that combines elements of Sudoku and Mastermind. The game is played on a 5x5 grid with irregular, colored regions. The objective is to deduce the correct sequence of numbers (1 through 5) for each row, with the constraint that each number must be unique within its row, column, and colored region.

![sudokrypt](https://i.ibb.co/7J6GzDvB/sudokrypt.jpg)

## Gameplay

The game presents you with a 5x5 grid where some numbers are pre-filled as clues. You have **12 total guesses** to solve the entire puzzle.

### Fog of War

A key feature of SUDOKRYPT is its "Fog of War" mechanic.
*   The colored regions for all future (unsolved) rows are hidden, concealing critical information.
*   However, the regions for the **current row you are solving** are revealed.
*   This makes cracking each vector a unique challenge where you must use the newly revealed region layout to your advantage. As you solve rows, the full board is gradually unveiled.

### Scoring: Data Recovery

Your goal is not just to win, but to win with the highest score possible.
*   **High Score:** The game tracks your `MAX RECOVERY`, your single best score.
*   **Round Score:** When you win, you are scored on your `DATA RECOVERED`.
*   **Formula:** The score is calculated based on the number of guesses you have left. The formula is **(Guesses Left)³ * 100**, which means the score grows exponentially the fewer guesses you use. A perfect game (5 guesses used) yields a score of **51,200 KB**.

### Core Loop

1.  **Objective**: Guess the 5-digit number sequence for the currently selected row (indicated by `V#`).
2.  **Input**: Enter a 5-digit sequence (e.g., `12345`).
3.  **Feedback**: After each guess, the game provides feedback in a "Mastermind" style: `SIGNAL X/5` indicates that `X` digits in your guess are in the correct position.
4.  **Winning**: Successfully stabilize all five vectors to bypass the SUDOKRYPT. Your `MAX RECOVERY` score will be updated if you set a new record.

## Installation & How to Play

No installation is required to play! Simply run the script from your terminal.

First, make sure the script is executable:

```bash
chmod +x sudokrypt.sh
```

Then, run the game:

```bash
./sudokrypt.sh
```

### Create a Global Alias

For easier access, you can add an alias to your shell's configuration file (`.bashrc`, `.zshrc`, `.profile`, etc.). This will allow you to run the game from any directory.

1.  Open your shell's configuration file in a text editor. For example:
    ```bash
    nano ~/.zshrc
    ```
2.  Add the following line, replacing `"/path/to/sudokrypt.sh"` with the actual absolute path to the script. Including `/bin/bash` ensures the script is executed with the correct interpreter.

    ```bash
    alias sudokrypt="/bin/bash /path/to/sudokrypt.sh"
    ```

    You can get the absolute path by navigating to the `sudokrypt` directory and running the `pwd` command.

3.  Save the file and reload your shell's configuration:
    ```bash
    source ~/.zshrc
    ```
4.  Now you can play from anywhere by simply typing:
    ```bash
    sudokrypt
    ```
