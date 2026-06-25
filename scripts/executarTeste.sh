#!/bin/bash
CENARIO=$1
mkdir -p resultados_$CENARIO
echo "Iniciando 30 replicações para: $CENARIO"

for i in {1..30}
do
    echo "[$(date +%H:%M:%S)] Execução $i de 30..."
    
    sudo pkill iperf3 2>/dev/null
    
    echo "[$(date +%H:%M:%S)] Disparando Ping..."
    ping -c 10 -n 192.168.1.20 > resultados_$CENARIO/ping_$i.txt &
    
    echo "[$(date +%H:%M:%S)] Iniciando Iperf3 (aguardando 10s)..."
    iperf3 -c 192.168.1.20 -t 10 -P 10 --json -4 > resultados_$CENARIO/iperf_$i.json
    
    echo "[$(date +%H:%M:%S)] Finalizado. Aguardando processos..."
    wait
done

echo "Testes concluídos!"
