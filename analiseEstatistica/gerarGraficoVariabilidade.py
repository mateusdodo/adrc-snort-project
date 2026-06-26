import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import glob
import re
import os

sns.set_theme(style="whitegrid")
plt.rcParams.update({'font.size': 12, 'figure.titlesize': 16})

arquivosCsv = glob.glob("dados_*.csv")
registrosDados = []

for arquivoLeitura in arquivosCsv:
    matchRegex = re.match(r"dados_([A-Za-z0-9]+)_Carga([A-Za-z0-9]+)_Porta(\d+)\.csv", arquivoLeitura)
    if matchRegex:
        regraSnort, cargaTráfego, portaServico = matchRegex.group(1), matchRegex.group(2), matchRegex.group(3)
        if cargaTráfego == "Max":
            try:
                dfTemporario = pd.read_csv(arquivoLeitura).dropna()
                stdVazao = dfTemporario['vazao_mbps'].std()
                meanVazao = dfTemporario['vazao_mbps'].mean()
                
                registrosDados.append({
                    'cenario': regraSnort,
                    'porta': f"porta {portaServico}",
                    'desvioPadraoVazao': stdVazao,
                    'vazaoMedia': meanVazao
                })
            except Exception as e:
                pass

dfVariabilidade = pd.DataFrame(registrosDados)
ordemCenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
dfVariabilidade['cenario'] = pd.Categorical(dfVariabilidade['cenario'], categories=ordemCenarios, ordered=True)
dfVariabilidade = dfVariabilidade.sort_values('cenario')

plt.figure(figsize=(10, 6))
sns.barplot(
    data=dfVariabilidade,
    x='cenario',
    y='desvioPadraoVazao',
    hue='porta',
    palette="muted",
    edgecolor="black"
)

plt.title("variabilidade das medicoes: desvio padrao da vazao", pad=15)
plt.ylabel("desvio padrao da vazao (mbps)")
plt.xlabel("politicas de seguranca do snort")
plt.tight_layout()
plt.savefig("comparativo_variabilidade.png", dpi=300)
print("grafico de variabilidade gerado")