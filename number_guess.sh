#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Pedir el nombre de usuario
echo "Enter your username:"
read USERNAME

# Buscar al usuario en la base de datos
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

# Si el usuario no existe
if [[ -z $USER_ID ]]
then
  # Nuevo usuario
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insertar el nuevo usuario en la base de datos
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  
  # Recuperar el user_id del nuevo usuario
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Usuario existente
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generar el número aleatorio entre 1 y 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Inicializar el contador de intentos
TRIES=0

# Pedir al usuario que adivine el número
echo "Guess the secret number between 1 and 1000:"
while true
do
  read GUESS

  # Comprobar si la entrada es un número entero
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    ((TRIES++))
    # Comparar la suposición con el número secreto
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
      break
    fi
  fi
done

# Actualizar el número de juegos jugados
UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID")

# Si es el mejor juego del usuario o es el primer juego, actualizar el mejor juego
if [[ -z $BEST_GAME || $TRIES -lt $BEST_GAME ]]
then
  UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $TRIES WHERE user_id = $USER_ID")
fi

# Insertar el resultado del juego en la tabla games
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $TRIES)")
