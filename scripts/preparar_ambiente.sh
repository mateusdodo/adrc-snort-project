#!/bin/bash

# ==============================================================================
# SCRIPT DE PREPARAÇÃO DO AMBIENTE DE ANÁLISE ESTATÍSTICA
# Este script instala as dependências necessárias via APT (evitando falta de RAM)
# e executa a sua análise estatística.
# ==============================================================================

echo "========================================================="
echo "   A PREPARAR O AMBIENTE DE ANÁLISE (A INSTALAR BIBLIOTECAS) "
echo "========================================================="

# Atualiza a lista de pacotes do sistema
echo "🔄 A atualizar repositórios de pacotes (apt update)..."
sudo apt-get update -y

# Instala as versões pré-compiladas estáveis para o Debian/Ubuntu
echo "📥 A instalar bibliotecas Python necessárias para gráficos..."
sudo apt-get install -y python3-pandas python3-matplotlib python3-seaborn python3-scipy python3-tabulate

echo -e "\n========================================================="
echo "   A EXECUTAR A ANÁLISE ESTATÍSTICA"
echo "========================================================="

# Verifica se o arquivo analise.sh existe e o executa com python3
if [ -f "analise.sh" ]; then
    echo "📊 A executar o seu script analise.sh com o interpretador Python3..."
    python3 analise.sh
elif [ -f "gerar_graficos.py" ]; then
    echo "📊 A executar gerar_graficos.py..."
    python3 gerar_graficos.py
elif [ -f "analisar_resultados.py" ]; then
    echo "📊 A executar analisar_resultados.py..."
    python3 analisar_resultados.py
else
    echo "❌ Erro: Não foi possível localizar o seu script de análise."
    echo "Certifique-se de que o script Python está na mesma pasta que este arquivo."
fi
