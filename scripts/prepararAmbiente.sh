#!/bin/bash

echo "atualizando repositorios"
sudo apt-get update -y

echo "instalando dependencias"
sudo apt-get install -y python3-pandas python3-matplotlib python3-seaborn python3-scipy python3-tabulate

echo "executando analise"
if [ -f "analise.sh" ]; then
    python3 analise.sh
fi