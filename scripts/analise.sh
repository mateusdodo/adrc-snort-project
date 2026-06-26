#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

sns.set_theme(style="whitegrid")
plt.rcParams.update({
    'font.size': 12,
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 11,
    'ytick.labelsize': 11,
    'legend.fontsize': 11,
    'figure.titlesize': 18,
    'font.family': 'sans-serif'
})

def calcularIntervaloConfianca(dados, confianca=0.95):
    n = len(dados)
    if n < 2:
        return 0.0
    sem = stats.sem(dados)
    margem = sem * stats.t.ppf((1 + confianca) / 2.0, n - 1)
    return margem

def carregarEProcessarDados():
    padraoArquivo = r"dados_([A-Za-z0-9]+)_Carga([A-Za-z0-9]+)_Porta(\d+)\.csv"
    arquivos = glob.glob("dados_*.csv")
    
    if not arquivos:
        print("nenhum arquivo encontrado")
        return None

    registros = []
    
    for arq in arquivos:
        match = re.match(padraoArquivo, arq)
        if match:
            regra = match.group(1)
            carga = match.group(2)
            porta = match.group(3)
            
            try:
                df = pd.read_csv(arq)
                df = df.apply(pd.to_numeric, errors='coerce').dropna()
                
                n = len(df)
                if n == 0:
                    continue
                    
                vazaoMedia = df['vazao_mbps'].mean()
                vazaoStd = df['vazao_mbps'].std()
                vazaoIc = calcularIntervaloConfianca(df['vazao_mbps'])
                
                retrMedia = df['retransmissoes'].mean()
                retrIc = calcularIntervaloConfianca(df['retransmissoes'])
                
                rttMedio = df['rtt_ms'].mean()
                rttIc = calcularIntervaloConfianca(df['rtt_ms'])
                
                registros.append({
                    'cenario': regra,
                    'carga': carga,
                    'porta': f"porta {porta}",
                    'vazaoMedia': vazaoMedia,
                    'vazaoStd': vazaoStd,
                    'vazaoIc': vazaoIc,
                    'retrMedia': retrMedia,
                    'retrIc': retrIc,
                    'rttMedio': rttMedio,
                    'rttIc': rttIc
                })
            except Exception as e:
                print(f"erro ao ler arquivo {arq}: {e}")
                
    return pd.DataFrame(registros)

def plotarGraficoVazao(df):
    dfMax = df[df['carga'] == 'Max'].copy()
    ordemCenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    dfMax['cenario'] = pd.Categorical(dfMax['cenario'], categories=ordemCenarios, ordered=True)
    dfMax = dfMax.sort_values('cenario')
    
    plt.figure(figsize=(10, 6))
    cores = {"porta 5201": "#1f77b4", "porta 80": "#d62728"}
    
    ax = sns.barplot(
        data=dfMax, 
        x='cenario', 
        y='vazaoMedia', 
        hue='porta',
        palette=cores,
        edgecolor='black',
        linewidth=1.2
    )
    
    numCenarios = len(ordemCenarios)
    larguraBarra = 0.4
    
    for i, portaNome in enumerate(["porta 5201", "porta 80"]):
        dfSub = dfMax[dfMax['porta'] == portaNome]
        offsets = np.arange(numCenarios) + (i - 0.5) * larguraBarra
        
        for idx, cenario in enumerate(ordemCenarios):
            row = dfSub[dfSub['cenario'] == cenario]
            if not row.empty:
                media = row['vazaoMedia'].values[0]
                ic = row['vazaoIc'].values[0]
                plt.errorbar(
                    x=offsets[idx],
                    y=media,
                    yerr=ic,
                    fmt='none',
                    c='black',
                    capsize=5,
                    capthick=1.5,
                    elinewidth=1.5
                )

    plt.title("impacto da complexidade do ids/ips na vazão útil", pad=20)
    plt.ylabel("vazão média de transmissão (mbps)")
    plt.xlabel("políticas de segurança do snort")
    plt.ylim(0, dfMax['vazaoMedia'].max() * 1.2)
    plt.legend(title="serviço analisado", loc="upper right")
    plt.tight_layout()
    plt.savefig("resultado_vazao_degradacao.png", dpi=300)
    plt.close()

def plotarGraficoLatencia(df):
    dfMax = df[df['carga'] == 'Max'].copy()
    ordemCenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    dfMax['cenario'] = pd.Categorical(dfMax['cenario'], categories=ordemCenarios, ordered=True)
    dfMax = dfMax.sort_values('cenario')
    
    plt.figure(figsize=(10, 6))
    ax = sns.barplot(
        data=dfMax,
        x='cenario',
        y='rttMedio',
        hue='porta',
        palette="YlOrRd",
        edgecolor='black',
        linewidth=1.2
    )
    
    plt.title("elevação da latência (rtt) sob carga máxima", pad=20)
    plt.ylabel("rtt médio do canal (ms)")
    plt.xlabel("políticas de segurança do snort")
    plt.legend(title="serviço analisado", loc="upper left")
    plt.tight_layout()
    plt.savefig("resultado_latencia_rtt.png", dpi=300)
    plt.close()

def exportarTabelaLatexMarkdown(df):
    dfMax = df[df['carga'] == 'Max'].copy()
    ordemCenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    dfMax['cenario'] = pd.Categorical(dfMax['cenario'], categories=ordemCenarios, ordered=True)
    dfMax = dfMax.sort_values(['porta', 'cenario'])
    
    dfMax['vazão (mbps)'] = dfMax.apply(lambda r: f"{r['vazaoMedia']:.2f} ± {r['vazaoIc']:.2f}", axis=1)
    dfMax['rtt (ms)'] = dfMax.apply(lambda r: f"{r['rttMedio']:.3f} ± {r['rttIc']:.3f}", axis=1)
    dfMax['retransmissões'] = dfMax.apply(lambda r: f"{r['retrMedia']:.1f}", axis=1)
    
    tabelaFinal = dfMax[['porta', 'cenario', 'vazão (mbps)', 'rtt (ms)', 'retransmissões']]
    tabelaFinal.to_markdown("tabela_resultados_formatada.md", index=False)
    
    with open("tabela_resultados_latex.tex", "w") as f:
        f.write(tabelaFinal.to_latex(index=False, caption="resumo estatístico do impacto do snort", label="tab:resultado_snort"))

def main():
    df = carregarEProcessarDados()
    if df is not None:
        plotarGraficoVazao(df)
        plotarGraficoLatencia(df)
        exportarTabelaLatexMarkdown(df)

if __name__ == "__main__":
    main()