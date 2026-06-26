
# avaliacao de desempenho do ips snort em modo inline (daq afpacket)

este repositorio contem a suite de automacao experimental, os conjuntos de dados brutos consolidados e os scripts de processamento estatistico referentes ao impacto de rede (overhead) gerado pelo snort operando como ips ativo (inline).

---

# 1. introducao e problema central

o objetivo central deste trabalho e quantificar a degradacao de desempenho provocada pelas rotinas de inspecao de assinaturas do snort ips em ambiente controlado de alta carga. avalia-se como a variacao da complexidade de regras de seguranca e o desvio para analisadores de protocolo de camada 7 influenciam o debito util (vazao), a latencia do canal (rtt) e a perda de segmentos (retransmissoes tcp).

---

# 2. arquitetura do testbed (cenario de emulacao)

a infraestrutura experimental foi implementada por meio de emulacao de sistemas utilizando o hypervisor virtualbox com sistemas operacionais reais.

text
[ vm cliente ] ======= (rede interna 1) ======> [ vm snort ips ] ======> (rede interna 2) =======> [ vm servidor ]
(192.168.1.10)                                 (sem ip / promiscuo)                               (192.168.1.20)
                                                interface enp0s8 | enp0s9



isolacao estrita do kernel
--------------------------

a ponte de rede padrao do kernel do linux foi eliminada. as interfaces virtuais da vm snort foram limpas e colocadas em modo promiscuo. a comunicacao ocorre com o processo do snort ativo em espaco de usuario, capturando pacotes na interface `enp0s8` atraves do driver daq `afpacket` e injetando-os na interface `enp0s9` de forma sequencial.

3\. metodologia cientifica e variaveis
======================================

o projeto foi desenhado com base em um design experimental fatorial:

$$\text{fator 1 (5 niveis)} \times \text{fator 2 (2 niveis)} \times \text{fator 3 (2 niveis)}$$

fator 1: complexidade das politicas de seguranca (variavel independente)
------------------------------------------------------------------------

-   **baseline:** 0 regras ativas (apenas o overhead do driver daq).

-   **medio:** 363 regras (protocolos basicos e filtragem de rede basica).

-   **padrao:** 3.384 regras (distribuicao padrao do ids).

-   **alto:** 842 regras focadas em dpi pesada (assinaturas regex de injecao sql, php e web).

-   **exaustivo:** ~3.400 regras consolidadas sem redundancias (estresse maximo do sistema).

fator 2: porta do servico (controle vs camada 7)
------------------------------------------------

-   **porta 5201:** trafego generico (sem processamento de protocolo http).

-   **porta 80:** trafego interpretado como http, forcando o desvio para o pre-processador httpinspect.

fator 3: carga de trabalho
--------------------------

-   **carga controlada (10m):** limitada de forma estavel em $10\text{ mbps}$.

-   **carga maxima (max):** saturacao fisica livre do canal de transmissao.

replicas e rigor estatistico
----------------------------

foram coletadas 30 replicas independentes ($n = 30$) para cada cenario com duracao de 30 segundos por rodada, totalizando 600 rodadas. os dados foram validados utilizando calculos de media amostral e intervalos de confianca (ic) de $95\%$ baseados na distribuicao t de student:

$$ic = \bar{x} \pm t \cdot \frac{s}{\sqrt{n}}$$

| **simbolo** | **descricao** |
| --- | --- |
| $ic$ | intervalo de confianca |
| $\bar{x}$ | media amostral |
| $t$ | valor critico da distribuicao t de student |
| $s$ | desvio padrao amostral |
| $n$ | tamanho da amostra ($n = 30$) |

4\. resumo de dados consolidados (carga maxima)
===============================================

tabela comparativa da analise estatistica extraida de forma automatizada a partir dos dados do experimento.

| **porta** | **cenario** | **vazao (mbps)** | **rtt (ms)** | **retransmissoes** | **estabilidade** |
| --- | --- | --- | --- | --- | --- |
| porta 5201 | baseline | $37.68 \pm 1.95$ | $1.258 \pm 0.391$ | 569.4 | alta |
| porta 5201 | medio | $32.80 \pm 1.61$ | $1.219 \pm 0.180$ | 509.3 | alta |
| porta 5201 | padrao | $30.58 \pm 1.30$ | $1.277 \pm 0.236$ | 619.2 | variavel |
| porta 5201 | alto | $33.54 \pm 1.56$ | $1.884 \pm 0.875$ | 503.3 | media |
| porta 5201 | exaustivo | $31.08 \pm 2.29$ | $1.146 \pm 0.084$ | 572.0 | saturacao |
| porta 80 | baseline | $32.79 \pm 1.72$ | $1.231 \pm 0.297$ | 547.8 | alta |
| porta 80 | medio | $23.55 \pm 0.61$ | $1.085 \pm 0.091$ | 518.2 | critica |
| porta 80 | padrao | $27.68 \pm 0.93$ | $1.189 \pm 0.134$ | 381.2 | variavel |
| porta 80 | alto | $26.01 \pm 0.60$ | $1.586 \pm 0.791$ | 400.4 | media |
| porta 80 | exaustivo | $28.75 \pm 0.77$ | $1.185 \pm 0.041$ | 422.5 | saturacao |

5\. principais achados cientificos
==================================

o custo base do modo inline
---------------------------

na baseline sem regras, a vazao maxima estabiliza em $37.68\text{ mbps}$ por limitacao fisica de cpu. o processo de copia de pacotes do kernel-space para o user-space via daq afpacket consome a thread unica do snort, limitando o barramento nativo da vm.

o paradoxo do cenario medio na porta 80
---------------------------------------

o cenario medio na porta 80 apresentou o menor desempenho ($23.55\text{ mbps}$). o payload gerado colidiu em falso positivo continuo com a assinatura de overflow do mod_jrun. o custo computacional de gravar alertas em disco gerou um gargalo de i/o, travando as filas de rede e forcando a reducao da janela de transmissao tcp.

sobrecarga de latencia em dpi (cenario alto)
--------------------------------------------

o cenario alto registrou o maior rtt do estudo ($1.88\text{ ms}$). regras baseadas em expressoes regulares complexas (pcre) exigem processamento intensivo de busca de strings, retendo o pacote em buffers de memoria por mais tempo.

6\. ferramentas utilizadas
==========================

-   **iperf3:** geracao de estresse de banda e medicao de vazao/retransmissoes em json.

-   **ping:** medicao de latencia bidirecional ativa em milissegundos.

-   **python:** automacao estatistica de intervalos de confianca e plotagem de graficos com pandas, seaborn, scipy e matplotlib.

-   **bash scripts:** automacao de replicas e isolacao de interfaces.

estrutura do repositorio
------------------------

-   `analiseEstatistica/`: scripts em python para geracao de graficos de variabilidade e comportamento.

-   `dadosConsolidados/`: arquivos csv contendo as metricas extraidas apos o processamento das replicas.

-   `figuras/`: graficos gerados de latencia, vazao e retransmissoes tcp.

-   `relatorios/`: tabelas de resultados formatadas em markdown e codigo estruturado em latex.

-   `scripts/`: automacoes em bash shell utilizadas para preparar o ambiente, executar os testes e consolidar os logs.
