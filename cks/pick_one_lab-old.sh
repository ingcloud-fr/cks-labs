#!/bin/bash

set -e

# 📘 Aide
if [[ "$1" == "--help" ]]; then
  echo "Usage: $0 [LEVEL]"
  echo
  echo "Randomly pick a lab from the current directory."
  echo "Labs must follow the format: DOMAIN-LEVEL-Title"
  echo "  e.g. CH-BEG-..., SCS-INT-..., SH-EXP-..."
  echo
  echo "Arguments:"
  echo "  LEVEL   Maximum difficulty level to include (BEG, INT, ADV, EXP)"
  echo "          Default is EXP (includes all labs)"
  echo
  echo "Example:"
  echo "  $0 ADV       # picks a random lab from BEG, INT, or ADV"
  echo "  $0           # picks a lab from all levels"
  exit 0
fi

# Niveau maximum autorisé (par défaut = EXP)
MAX_LEVEL="${1:-EXP}"

# Ordre des niveaux
LEVELS=("BEG" "INT" "ADV" "EXP")

# Vérifie si le niveau donné est valide
if [[ ! " ${LEVELS[*]} " =~ " $MAX_LEVEL " ]]; then
  echo "❌ Invalid level: $MAX_LEVEL"
  echo "Run with --help for usage."
  exit 1
fi

# Trouver l'indice du niveau max
LIMIT_INDEX=3
for i in "${!LEVELS[@]}"; do
  if [[ "${LEVELS[$i]}" == "$MAX_LEVEL" ]]; then
    LIMIT_INDEX=$i
    break
  fi
done

# Filtrer tous les dossiers qui ont un niveau autorisé comme 2ᵉ champ
LABS=()
for dir in */; do
  dir="${dir%/}"  # remove trailing slash
  # Extraire le champ niveau depuis le nom du dossier (2ᵉ bloc après le 1er '-')
  LEVEL_PART=$(echo "$dir" | cut -d '-' -f2)
  for i in $(seq 0 $LIMIT_INDEX); do
    if [[ "$LEVEL_PART" == "${LEVELS[$i]}" ]]; then
      LABS+=("$dir")
    fi
  done
done

if [ ${#LABS[@]} -eq 0 ]; then
  echo "❌ No labs found for level <= $MAX_LEVEL"
  exit 1
fi

# Choix aléatoire
RND=$RANDOM
IDX=$((RND % ${#LABS[@]}))

echo "🎲 RANDOM = $RND"
echo "📦 Found ${#LABS[@]} lab(s) matching level <= $MAX_LEVEL"
echo "🎯 Selected lab: ${LABS[$IDX]}"
cd "${LABS[$IDX]}"

# Affiche le README.txt
if [ -f README.txt ]; then
  echo
  echo "📘 README.txt:"
  echo "----------------------------------------"
  cat README.txt
  echo "----------------------------------------"
else
  echo "⚠️ No README.txt found in ${LABS[$IDX]}"
fi

echo
echo "💡 To start this lab, run:"
echo "cd ${LABS[$IDX]} && ./deploy.sh"
echo ""
