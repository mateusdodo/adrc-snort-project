#!/bin/bash
for cenario in Baseline Medio Alto; do
    echo "Processando $cenario..."
    echo "rodada,vazao_mbps,retransmissoes,rtt_ms" > dados_${cenario}.csv
    
    for i in {1..30}; do
        # Vazão e Retransmissões do JSON (usa bits_per_second enviado se recebido falhar)
        VAZAO=$(jq '.end.sum_sent.bits_per_second // 0' resultados_${cenario}/iperf_$i.json | awk '{print $1 / 1000000}')
        RETR=$(jq '.end.sum_sent.retransmits // 0' resultados_${cenario}/iperf_$i.json)
        
        # RTT Médio do Ping
        RTT=$(grep "rtt" resultados_${cenario}/ping_$i.txt | cut -d '=' -f 2 | cut -d '/' -f 2)
        
        echo "$i,$VAZAO,$RETR,${RTT:-0}" >> dados_${cenario}.csv
    done
done
echo "Concluído! Arquivos dados_Baseline.csv, dados_Medio.csv e dados_Alto.csv gerados."
