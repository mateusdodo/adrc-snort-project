#!/bin/bash
serverIp="192.168.1.20"
replicacoes=30
duracao=30 

regras=("Baseline" "Padrao" "Medio" "Alto" "Exaustivo")
cargas=("Max" "10M")
portas=(5201 80)

echo "iniciando experimento"

for regra in "${regras[@]}"; do
    echo "configurar /etc/snort/snort.conf para: $regra"
    echo "iniciar snort inline e iperf3 nas portas 5201 e 80 no servidor"
    echo "pressione enter para continuar..."
    read -r
    
    for carga in "${cargas[@]}"; do
        for porta in "${portas[@]}"; do
            
            arquivoSaida="dados_${regra}_Carga${carga}_Porta${porta}.csv"
            echo "rodada,vazao_mbps,retransmissoes,rtt_ms" > "$arquivoSaida"
            
            echo "cenario: $regra | carga: $carga | porta: $porta"
            
            miniRtt=$(ping -c 3 "$serverIp" | tail -n 1 | awk -F '/' '{print $5}')
            echo "rtt minimo: ${miniRtt} ms"
            
            if [ "$regra" == "Baseline" ]; then
                isErrado=$(awk -v rtt="$miniRtt" 'BEGIN {print (rtt > 4.0) ? 1 : 0}')
                if [ "$isErrado" -eq 1 ]; then
                    echo "aviso: rtt alto para baseline"
                fi
            else
                isBypass=$(awk -v rtt="$miniRtt" 'BEGIN {print (rtt < 2.5) ? 1 : 0}')
                if [ "$isBypass" -eq 1 ]; then
                    echo "erro: possivel bypass detectado"
                    echo "pressione enter para ignorar e continuar..."
                    read -r
                fi
            fi
            
            sumVazao=0
            for i in $(seq 1 "$replicacoes"); do
                echo -ne "replicacao $i/$replicacoes\r"
                
                banda=""
                if [ "$carga" == "10M" ]; then 
                    banda="-b 10M"
                fi
                
                tempJson="temp_${regra}_${carga}_${porta}.json"
                
                iperf3 -c "$serverIp" -p "$porta" $banda -t "$duracao" --json > "$tempJson"
                
                vazaoBps=$(jq '.end.sum_sent.bits_per_second // 0' "$tempJson")
                vazao=$(awk -v bps="$vazaoBps" 'BEGIN {print bps / 1000000}')
                retr=$(jq '.end.sum_sent.retransmits // 0' "$tempJson")
                
                rtt=$(ping -c 3 "$serverIp" | tail -n 1 | awk -F '/' '{print $5}')
                
                echo "$i,$vazao,$retr,$rtt" >> "$arquivoSaida"
                
                sumVazao=$(awk -v s="$sumVazao" -v v="$vazao" 'BEGIN {print s + v}')
                
                rm -f "$tempJson"
                sleep 1
            done
            
            mediaVazao=$(awk -v s="$sumVazao" -v r="$replicacoes" 'BEGIN {print s / r}')
            echo "cenario concluido. media: ${mediaVazao} mbps"
        done
    done
done

echo "experimento finalizado"