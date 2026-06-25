#!/bin/bash

# ==============================================================================
# EXPERIMENTO AVANÇADO: Avaliação de Sobrecarga (Overhead) do IDS/IPS Snort
# Matriz Experimental: Níveis de Regras (Padrão ao Exaustivo) x 2 Cargas x 2 Portas x 30 Réplicas
# Nota: Baseline omitida neste script para proteger os arquivos CSV já coletados.
# ==============================================================================

SERVER_IP="192.168.1.20"
REPLICACOES=30
DURACAO=30 # Segundos por rodada para garantir Estado Estacionário

# Fatores do Experimento (Iniciando diretamente do cenário Padrão)
REGRAS=("Padrao" "Medio" "Alto" "Exaustivo")
CARGAS=("Max" "10M")
PORTAS=(5201 80)

echo "========================================================="
echo "   INICIANDO MATRIZ EXPERIMENTAL COMPLETA (IDS/IPS)      "
echo "        (Etapa 2: Cenários Ativos - Regras em DPI)        "
echo "========================================================="

# O laço de REGRAS fica no topo para você só alterar o snort.conf 4 vezes no total
for REGRA in "${REGRAS[@]}"; do
    
    echo -e "\n#########################################################"
    echo " 📢 SOLICITAÇÃO DE CONFIGURAÇÃO DO AMBIENTE"
    echo " -> 1. Vá até a VM do Snort:"
    echo "       - Configure o arquivo /etc/snort/snort.conf para: [$REGRA]"
    echo "       - Inicialize o Snort Inline (sudo snort -A console -q ...)"
    echo " "
    echo " -> 2. Vá até a VM do Servidor e garanta que AMBOS estão ativos:"
    echo "       - Terminal 1: sudo iperf3 -s -p 5201"
    echo "       - Terminal 2: sudo iperf3 -s -p 80"
    echo "#########################################################"
    echo "Após o Snort iniciar e o Servidor estar ouvindo nas duas portas, pressione [ENTER] aqui..."
    read -r
    
    for CARGA in "${CARGAS[@]}"; do
        for PORTA in "${PORTAS[@]}"; do
            
            # Inicialização e cabeçalho do arquivo CSV de saída
            ARQUIVO_SAIDA="dados_${REGRA}_Carga${CARGA}_Porta${PORTA}.csv"
            echo "rodada,vazao_mbps,retransmissoes,rtt_ms" > "$ARQUIVO_SAIDA"
            
            echo "--------------------------------------------------------"
            echo " 📊 EXECUTANDO CENÁRIO ATUAL:"
            echo "    • Complexidade do IDS : $REGRA"
            echo "    • Carga de Trabalho   : $CARGA"
            echo "    • Porta do Serviço    : $PORTA"
            echo "--------------------------------------------------------"
            
            # --- MINITESTE DE COERÊNCIA ANTES DAS RÉPLICAS ---
            echo "⏱️  Rodando miniteste de validação de latência do canal..."
            MINI_RTT=$(ping -c 3 "$SERVER_IP" | tail -n 1 | awk -F '/' '{print $5}')
            echo "    -> RTT instantâneo medido: ${MINI_RTT} ms"
            
            # Lógica de validação baseada no tempo mínimo de bypass físico (0.85 ms)
            IS_BYPASS=$(awk -v rtt="$MINI_RTT" 'BEGIN {print (rtt < 0.85) ? 1 : 0}')
            if [ "$IS_BYPASS" -eq 1 ]; then
                echo -e "\n❌ [ERRO CRÍTICO: INCONGRUÊNCIA DE DADOS DETECTADA]"
                echo "    O nível atual é '$REGRA', mas a latência foi de apenas ${MINI_RTT} ms."
                echo "    O tráfego está dando BYPASS no Snort (Kernel assumiu ou o processo caiu)."
                echo "    Aborte o script (Ctrl+C), ajuste a VM do Snort e reinicie."
                echo "--------------------------------------------------------"
                echo "Se você deseja ignorar este aviso e forçar a execução, pressione [ENTER]..."
                read -r
            else
                echo "✅ Miniteste concluído: Comportamento do IDS condizente com o cenário inline."
            fi
            
            # --- EXECUÇÃO DAS 30 RÉPLICAS ESTATÍSTICAS ---
            SUM_VAZAO=0
            for i in $(seq 1 "$REPLICACOES"); do
                echo -ne "   -> Processando Replicação $i/$REPLICACOES...\r"
                
                # Ajuste de banda dinâmica
                BANDA=""
                if [ "$CARGA" == "10M" ]; then 
                    BANDA="-b 10M"
                fi
                
                TEMP_JSON="temp_${REGRA}_${CARGA}_${PORTA}.json"
                
                # Dispara o iperf3 coletando em JSON estruturado
                iperf3 -c "$SERVER_IP" -p "$PORTA" $BANDA -t "$DURACAO" --json > "$TEMP_JSON"
                
                # Extração matemática segura (Evita a string 'receiver')
                VAZAO_BPS=$(jq '.end.sum_sent.bits_per_second // 0' "$TEMP_JSON")
                VAZAO=$(awk -v bps="$VAZAO_BPS" 'BEGIN {print bps / 1000000}')
                RETR=$(jq '.end.sum_sent.retransmits // 0' "$TEMP_JSON")
                
                # Coleta o RTT sob estresse de carga
                RTT=$(ping -c 3 "$SERVER_IP" | tail -n 1 | awk -F '/' '{print $5}')
                
                # Escrita no arquivo de dados definitivo
                echo "$i,$VAZAO,$RETR,$RTT" >> "$ARQUIVO_SAIDA"
                
                # Acumulador simples para o sumário de tela
                SUM_VAZAO=$(awk -v s="$SUM_VAZAO" -v v="$VAZAO" 'BEGIN {print s + v}')
                
                rm -f "$TEMP_JSON"
                sleep 1 # Resfriamento térmico/transiente do hypervisor
            done
            
            # Média rápida para conferência visual do aluno
            MEDIA_VAZAO=$(awk -v s="$SUM_VAZAO" -v r="$REPLICACOES" 'BEGIN {print s / r}')
            echo -e "\n   ✅ Cenário Concluído! Arquivo gerado: $ARQUIVO_SAIDA"
            echo "   📊 Média preliminar de Vazão calculada: ${MEDIA_VAZAO} Mbps"
            echo "--------------------------------------------------------"
            
        done
    done
done

echo "========================================================="
echo " EXPERIMENTO FINALIZADO: Todos os CSVs gerados com sucesso."
echo "========================================================="

