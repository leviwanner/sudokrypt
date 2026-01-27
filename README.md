# SUDOKRYPT

A simple, terminal-based puzzle game that combines elements of Sudoku and Mastermind. The game is played on a 5x5 grid with irregular, colored regions. The objective is to deduce the correct sequence of numbers (1 through 5) for each row, with the constraint that each number must be unique within its row, column, and colored region.

![sudokrypt](https://i.ibb.co/7J6GzDvB/sudokrypt.jpg)

## Gameplay

The game presents you with a 5x5 grid where some numbers are pre-filled as clues. Each of the five rows is a "vector" that you must stabilize.

1.  **Objective**: Guess the 5-digit number sequence for the currently selected row (indicated by `V#`).
2.  **Input**: Enter a 5-digit sequence (e.g., `12345`).
3.  **Feedback**: After each guess, the game provides feedback in a "Mastermind" style:
    - `SIGNAL X/5` indicates that `X` digits in your guess are correct and in the right position.
4.  **Winning a Row**: When you guess the sequence for a row correctly, the game will confirm that the "vector is stable," and you will automatically move to the next row.
5.  **Losing**: You have a limited number of **total guesses** to solve the entire puzzle. If you exceed this limit, the game ends, and the full solution is revealed.
6.  **Winning the Game**: Successfully stabilize all five vectors to bypass the SUDOKRYPT and win the game. Your win count will be tracked locally.

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
2.  Add the following line, replacing `"/path/to/sudokrypt.sh"` with the actual absolute path to the script:

    ```bash
    alias sudokrypt="/path/to/sudokrypt.sh"
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
