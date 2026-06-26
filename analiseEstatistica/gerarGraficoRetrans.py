import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_theme(style="whitegrid")
plt.rcParams.update({'font.size': 12, 'figure.titlesize': 16})

dadosUnificados = {
    'cenario': [
        'Baseline', 'Baseline', 
        'Médio', 'Médio', 
        'Padrão', 'Padrão', 
        'Alto', 'Alto', 
        'Exaustivo', 'Exaustivo'
    ],
    'porta': [
        'porta 5201', 'porta 80', 
        'porta 5201', 'porta 80', 
        'porta 5201', 'porta 80', 
        'porta 5201', 'porta 80', 
        'porta 5201', 'porta 80'
    ],
    'mediaRetransmissoes': [
        569.4, 547.8,
        509.3, 518.2,
        619.2, 381.2,
        503.3, 400.4,
        572.0, 422.5
    ]
}

dfTcp = pd.DataFrame(dadosUnificados)

ordemCenarios = ["Baseline", "Médio", "Padrão", "Alto", "Exaustivo"]
dfTcp['cenario'] = pd.Categorical(dfTcp['cenario'], categories=ordemCenarios, ordered=True)
dfTcp = dfTcp.sort_values('cenario')

plt.figure(figsize=(10, 6))
sns.barplot(
    data=dfTcp,
    x='cenario',
    y='mediaRetransmissoes',
    hue='porta',
    palette="muted",
    edgecolor="black"
)

plt.title("estabilidade do fluxo: media de retransmissoes tcp", pad=15)
plt.ylabel("contagem media de retransmissoes")
plt.xlabel("politicas de seguranca do snort")
plt.legend(title="servico / porta")

plt.tight_layout()
plt.savefig("resultado_retransmissoes_tcp.png", dpi=300)
print("grafico de retransmissoes gerado")