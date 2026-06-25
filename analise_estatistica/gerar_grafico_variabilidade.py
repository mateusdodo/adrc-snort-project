import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import glob
import re
import os

sns.set_theme(style="whitegrid")
plt.rcParams.update({'font.size': 12, 'figure.titlesize': 16})

# Varre os arquivos CSV
arquivos = glob.glob("dados_*.csv")
registros = []

for arq in arquivos:
    match = re.match(r"dados_([A-Za-z0-9]+)_Carga([A-Za-z0-9]+)_Porta(\d+)\.csv", arq)
    if match:
        regra, carga, porta = match.group(1), match.group(2), match.group(3)
        if carga == "Max":  # Foco na variabilidade sob estresse máximo
            try:
                df = pd.read_csv(arq).dropna()
                std_vazao = df['vazao_mbps'].std()
                mean_vazao = df['vazao_mbps'].mean()
                
                registros.append({
                    'Cenário': regra,
                    'Porta': f"Porta {porta}",
                    'Desvio_Padrao_Vazao': std_vazao,
                    'Vazao_Media': mean_vazao
                })
            except Exception as e:
                pass

df_var = pd.DataFrame(registros)
ordem = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
df_var['Cenário'] = pd.Categorical(df_var['Cenário'], categories=ordem, ordered=True)
df_var = df_var.sort_values('Cenário')

# Plotando o gráfico de Desvio Padrão
plt.figure(figsize=(10, 6))
sns.barplot(
    data=df_var,
    x='Cenário',
    y='Desvio_Padrao_Vazao',
    hue='Porta',
    palette="muted",
    edgecolor="black"
)

plt.title("Variabilidade das Medições: Desvio Padrão da Vazão Útil\n(Rigor Estatístico sob Carga Máxima)", pad=15)
plt.ylabel("Desvio Padrão da Vazão (Mbps)")
plt.xlabel("Políticas de Segurança do Snort")
plt.tight_layout()
plt.savefig("comparativo_variabilidade.png", dpi=300)
print("💾 Gráfico comparativo_variabilidade.png gerado com sucesso!")

