#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
==============================================================================
SESSÃO DE PROCESSAMENTO ESTATÍSTICO - OVERHEAD DO IDS/IPS SNORT
Este script lê de forma dinâmica todos os arquivos 'dados_*.csv' gerados no 
experimento, calcula as médias, desvios-padrão e intervalos de confiança (95%),
e plota gráficos com qualidade de publicação científica.
==============================================================================
"""

import os
import re
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Configuração visual premium para publicação acadêmica
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

def calcular_intervalo_confianca(dados, confianca=0.95):
    """Calcula a margem de erro para o intervalo de confiança desejado."""
    n = len(dados)
    if n < 2:
        return 0.0
    sem = stats.sem(dados)
    margem = sem * stats.t.ppf((1 + confianca) / 2.0, n - 1)
    return margem

def carregar_e_processar_dados():
    """Varre o diretório em busca dos CSVs de resultados e consolida as estatísticas."""
    padrao_arquivo = r"dados_([A-Za-z0-9]+)_Carga([A-Za-z0-9]+)_Porta(\d+)\.csv"
    arquivos = glob.glob("dados_*.csv")
    
    if not arquivos:
        print("❌ Nenhum arquivo do tipo 'dados_*.csv' foi encontrado no diretório atual.")
        print("Aguarde a finalização do experimento.sh antes de rodar este script.")
        return None

    registros = []
    
    for arq in arquivos:
        match = re.match(padrao_arquivo, arq)
        if match:
            regra = match.group(1)
            carga = match.group(2)
            porta = match.group(3)
            
            try:
                df = pd.read_csv(arq)
                # Garante que não há linhas vazias ou strings perdidas
                df = df.apply(pd.to_numeric, errors='coerce').dropna()
                
                n = len(df)
                if n == 0:
                    continue
                    
                # Métricas de Vazão (Mbps)
                vazao_media = df['vazao_mbps'].mean()
                vazao_std = df['vazao_mbps'].std()
                vazao_ic = calcular_intervalo_confianca(df['vazao_mbps'])
                
                # Métricas de Retransmissões
                retr_media = df['retransmissoes'].mean()
                retr_ic = calcular_intervalo_confianca(df['retransmissoes'])
                
                # Métricas de RTT (ms)
                rtt_medio = df['rtt_ms'].mean()
                rtt_ic = calcular_intervalo_confianca(df['rtt_ms'])
                
                registros.append({
                    'Cenário': regra,
                    'Carga': carga,
                    'Porta': f"Porta {porta}",
                    'Vazao_Media': vazao_media,
                    'Vazao_Std': vazao_std,
                    'Vazao_IC': vazao_ic,
                    'Retr_Media': retr_media,
                    'Retr_IC': retr_ic,
                    'RTT_Medio': rtt_medio,
                    'RTT_IC': rtt_ic
                })
            except Exception as e:
                print(f"⚠️ Erro ao ler o arquivo {arq}: {e}")
                
    return pd.DataFrame(registros)

def plotar_grafico_vazao(df):
    """Gera o gráfico comparativo de Vazão com barras de erro (Intervalo de Confiança)."""
    # Filtra apenas a carga Máxima (Max) para simplificar a visualização do gargalo principal
    df_max = df[df['Carga'] == 'Max'].copy()
    
    # Ordena os cenários conforme a progressão de complexidade experimental
    ordem_cenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    df_max['Cenário'] = pd.Categorical(df_max['Cenário'], categories=ordem_cenarios, ordered=True)
    df_max = df_max.sort_values('Cenário')
    
    plt.figure(figsize=(10, 6))
    
    # Paleta de cores sofisticada (Azul para controle, Vermelho/Laranja para DPI)
    cores = {"Porta 5201": "#1f77b4", "Porta 80": "#d62728"}
    
    # Plot das barras
    ax = sns.barplot(
        data=df_max, 
        x='Cenário', 
        y='Vazao_Media', 
        hue='Porta',
        palette=cores,
        edgecolor='black',
        linewidth=1.2
    )
    
    # Adiciona as barras de erro manuais baseadas no Intervalo de Confiança real calculado
    num_cenarios = len(ordem_cenarios)
    largura_barra = 0.4
    
    for i, porta_nome in enumerate(["Porta 5201", "Porta 80"]):
        df_sub = df_max[df_max['Porta'] == porta_nome]
        offsets = np.arange(num_cenarios) + (i - 0.5) * largura_barra
        
        # Desenha a barra de erro customizada para cada cenário encontrado
        for idx, cenario in enumerate(ordem_cenarios):
            row = df_sub[df_sub['Cenário'] == cenario]
            if not row.empty:
                media = row['Vazao_Media'].values[0]
                ic = row['Vazao_IC'].values[0]
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

    plt.title("Impacto da Complexidade do IDS/IPS na Vazão Útil (Throughput)", pad=20)
    plt.ylabel("Vazão Média de Transmissão (Mbps)")
    plt.xlabel("Políticas de Segurança do Snort (Escala de Complexidade)")
    plt.ylim(0, df_max['Vazao_Media'].max() * 1.2)
    plt.legend(title="Serviço Analisado", loc="upper right")
    
    plt.tight_layout()
    plt.savefig("resultado_vazao_degradacao.png", dpi=300)
    print("💾 Gráfico de Vazão salvo como 'resultado_vazao_degradacao.png'")
    plt.close()

def plotar_grafico_latencia(df):
    """Gera o gráfico comparativo de latência (RTT) média sob estresse."""
    df_max = df[df['Carga'] == 'Max'].copy()
    ordem_cenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    df_max['Cenário'] = pd.Categorical(df_max['Cenário'], categories=ordem_cenarios, ordered=True)
    df_max = df_max.sort_values('Cenário')
    
    plt.figure(figsize=(10, 6))
    
    ax = sns.barplot(
        data=df_max,
        x='Cenário',
        y='RTT_Medio',
        hue='Porta',
        palette="YlOrRd",
        edgecolor='black',
        linewidth=1.2
    )
    
    plt.title("Elevação da Latência (RTT) sob Carga Máxima de Trabalho", pad=20)
    plt.ylabel("RTT Médio do Canal (ms)")
    plt.xlabel("Políticas de Segurança do Snort")
    plt.legend(title="Serviço Analisado", loc="upper left")
    
    plt.tight_layout()
    plt.savefig("resultado_latencia_rtt.png", dpi=300)
    print("💾 Gráfico de Latência salvo como 'resultado_latencia_rtt.png'")
    plt.close()

def exportar_tabela_latex_markdown(df):
    """Gera e salva tabelas resumidas formatadas para o relatório acadêmico."""
    df_max = df[df['Carga'] == 'Max'].copy()
    ordem_cenarios = ["Baseline", "Medio", "Padrao", "Alto", "Exaustivo"]
    df_max['Cenário'] = pd.Categorical(df_max['Cenário'], categories=ordem_cenarios, ordered=True)
    df_max = df_max.sort_values(['Porta', 'Cenário'])
    
    # Cria uma visualização limpa combinando as métricas e seus respectivos ICs
    df_max['Vazão (Mbps)'] = df_max.apply(lambda r: f"{r['Vazao_Media']:.2f} ± {r['Vazao_IC']:.2f}", axis=1)
    df_max['RTT (ms)'] = df_max.apply(lambda r: f"{r['RTT_Medio']:.3f} ± {r['RTT_IC']:.3f}", axis=1)
    df_max['Retransmissões'] = df_max.apply(lambda r: f"{r['Retr_Media']:.1f}", axis=1)
    
    tabela_final = df_max[['Porta', 'Cenário', 'Vazão (Mbps)', 'RTT (ms)', 'Retransmissões']]
    
    # Exporta para Markdown
    tabela_final.to_markdown("tabela_resultados_formatada.md", index=False)
    print("💾 Tabela em Markdown salva como 'tabela_resultados_formatada.md'")
    
    # Exporta para LaTeX
    with open("tabela_resultados_latex.tex", "w") as f:
        f.write(tabela_final.to_latex(index=False, caption="Resumo Estatístico Comparativo do Impacto de Políticas do Snort no Testbed", label="tab:resultado_snort"))
    print("💾 Tabela em LaTeX salva como 'tabela_resultados_latex.tex'")

def main():
    print("\n" + "="*80)
    print("  PROCESSADOR ESTATÍSTICO DO EXPERIMENTO SNORT")
    print("="*80)
    
    df = carregar_e_processar_dados()
    if df is not None:
        plotar_grafico_vazao(df)
        plotar_grafico_latencia(df)
        exportar_tabela_latex_markdown(df)
        print("\n🎉 Processamento estatístico concluído com sucesso!")
        print("Os arquivos gerados estão prontos para serem inseridos no seu TCC/Artigo.\n")

if __name__ == "__main__":
    main()
