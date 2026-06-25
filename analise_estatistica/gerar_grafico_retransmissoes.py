import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Configuração do tema idêntica ao seu padrão
sns.set_theme(style="whitegrid")
plt.rcParams.update({'font.size': 12, 'figure.titlesize': 16})

# 1. Estruturação dos dados da tabela diretamente em um DataFrame
dados = {
    'Cenário': [
        'Baseline', 'Baseline', 
        'Médio', 'Médio', 
        'Padrão', 'Padrão', 
        'Alto', 'Alto', 
        'Exaustivo', 'Exaustivo'
    ],
    'Porta': [
        'Porta 5201', 'Porta 80', 
        'Porta 5201', 'Porta 80', 
        'Porta 5201', 'Porta 80', 
        'Porta 5201', 'Porta 80', 
        'Porta 5201', 'Porta 80'
    ],
    'Média de Retransmissões': [
        569.4, 547.8,  # Baseline
        509.3, 518.2,  # Médio
        619.2, 381.2,  # Padrão
        503.3, 400.4,  # Alto
        572.0, 422.5   # Exaustivo
    ]
}

df_tcp = pd.DataFrame(dados)

# 2. Ordenação categórica dos cenários para o eixo X
ordem = ["Baseline", "Médio", "Padrão", "Alto", "Exaustivo"]
df_tcp['Cenário'] = pd.Categorical(df_tcp['Cenário'], categories=ordem, ordered=True)
df_tcp = df_tcp.sort_values('Cenário')

# 3. Criação da figura e plotagem do gráfico
plt.figure(figsize=(10, 6))
sns.barplot(
    data=df_tcp,
    x='Cenário',
    y='Média de Retransmissões',
    hue='Porta',
    palette="muted",
    edgecolor="black"
)

# Customização de títulos e legendas
plt.title("Estabilidade do Fluxo: Média de Retransmissões Segmentos TCP\n(Impacto de Concorrência sob Carga Máxima)", pad=15)
plt.ylabel("Contagem Média de Retransmissões")
plt.xlabel("Políticas de Segurança do Snort")
plt.legend(title="Serviço / Porta")

# Ajuste fino e salvamento da imagem
plt.tight_layout()
plt.savefig("resultado_retransmissoes_tcp.png", dpi=300)
print("💾 Gráfico resultado_retransmissoes_tcp.png gerado com sucesso!")
