# Relatório Consolidado de Comparação

## Objetivo

Este documento consolida os resultados da comparação entre a execução de um script em R e a execução pela ESA TOOL, usando a mesma base de dados e a mesma sequência de análise.

## Metodologia resumida

Foram comparados os seguintes artefatos gerados em ambos os ambientes:

- Série original
- Estatísticas descritivas
- Série transformada
- Série diferenciada
- ACF
- PACF
- Métricas e parâmetros do modelo
- Resíduos
- Previsões
- Tempo de execução

Para as comparações numéricas, foram usados os indicadores:

- Diferença máxima absoluta
- MAE
- RMSE

## Resultados consolidados

### 1. Série original

- Número de observações: 1051 em ambos os ambientes
- Datas iguais: sim
- Diferença máxima absoluta: 0
- MAE: 0
- RMSE: 0

Conclusão: a base carregada foi consistente entre os dois ambientes.

### 2. Estatísticas descritivas

| Métrica          |     Valor manual |        Valor ESA | Diferença absoluta |
| ---------------- | ---------------: | ---------------: | -----------------: |
| Média            | 2.00133206470029 | 2.00133206470029 |                  0 |
| Mediana          |                0 |                0 |                  0 |
| Mínimo           |                0 |                0 |                  0 |
| Máximo           |             56.2 |             56.2 |                  0 |
| Desvio padrão    | 5.94918466883604 | 5.94918466883604 |                  0 |
| Variância        | 35.3927982239137 | 35.3927982239137 |                  0 |
| Primeiro quartil |                0 |                0 |                  0 |
| Terceiro quartil |              0.6 |              0.6 |                  0 |

Conclusão: não houve diferença nas estatísticas descritivas.

### 3. Série transformada

- Diferença máxima absoluta: 0
- MAE: 0
- RMSE: 0

Conclusão: a transformação aplicada produziu o mesmo resultado numérico nos dois fluxos.

### 4. Série diferenciada

| Coluna | Diferença máxima absoluta | MAE | RMSE |
| ------ | ------------------------: | --: | ---: |
| diff_1 |                         0 |   0 |    0 |
| diff_2 |                         0 |   0 |    0 |

Conclusão: a diferenciação está alinhada entre os ambientes.

### 5. ACF e PACF

ACF:

- Diferença máxima absoluta: 0
- MAE: 0
- RMSE: 0

PACF:

- Diferença máxima absoluta: 0
- MAE: 0
- RMSE: 0

Conclusão: as estruturas de autocorrelação e autocorrelação parcial são equivalentes.

### 6. Métricas e parâmetros do modelo

| Parâmetro |      Valor manual |         Valor ESA | Diferença absoluta |
| --------- | ----------------: | ----------------: | -----------------: |
| AIC       |  6603.29923783709 |  6595.17332828609 |    8.1259095510004 |
| BIC       |   6623.1292273206 |  6610.04296461554 |   13.0862627050601 |
| logLik    | -3297.64961891855 | -3294.58666414304 |   3.06295477551021 |
| sigma2    |  31.1213754251326 |   31.049078393428 | 0.0722970317046006 |

Observação: os coeficientes não estão perfeitamente alinhados entre os arquivos, o que indica que a especificação efetivamente ajustada não foi exatamente a mesma nos dois lados.

Conclusão: os ajustes estão próximos em termos de qualidade global, mas não representam uma correspondência 1:1 de parâmetros.

### 7. Resíduos

- Diferença máxima absoluta: 5.09762730525097
- MAE: 0.558948637182776
- RMSE: 0.787156332343774
- Média da diferença: 0.0541187967653227
- Desvio padrão da diferença: 0.785667593592341

Conclusão: os resíduos mostram discrepância moderada, compatível com a diferença observada na especificação do modelo.

### 8. Previsões

- Diferença máxima absoluta: 1.95285241967172
- MAE: 1.63585093314192
- RMSE: 1.65893412103192

Conclusão: as previsões também apresentam divergência, compatível com o observado nos resíduos e na especificação do modelo.

### 9. Tempo de execução

- tempo manual: 0.0342898368835449 segundos
- tempo ESA TOOL: 0.582623720169067 segundos

Conclusão: a execução pura dos comandos é mais rápida no ambiente manual, mas a diferença de tempo é pequena em termos absolutos e pode ser justificada pela sobrecarga da ferramenta e diferença de ambiente (command line vs docker).

## Síntese para o TCC

Os resultados numéricos da base, das estatísticas descritivas, da transformação, da diferenciação e das medidas de autocorrelação apresentaram equivalência exata entre a execução manual e a ESA TOOL, com diferença máxima absoluta igual a zero em todos esses blocos.

A principal divergência apareceu na etapa de modelagem e nos resíduos, o que sugere diferença na especificação efetivamente ajustada em cada ambiente. Por isso, a conclusão mais segura para o trabalho é afirmar que a ESA TOOL reproduz corretamente o tratamento e a exploração da série, mas não necessariamente a modelagem, que depende de parâmetros e decisões de ajuste que podem variar entre os ambientes.

## Arquivos de apoio

- [Comparação da série original](./resultados_comparacao/comparacao_final/comparacao_serie_original.csv)
- [Comparação das estatísticas descritivas](./resultados_comparacao/comparacao_final/comparacao_estatisticas_descritivas.csv)
- [Comparação da série transformada](./resultados_comparacao/comparacao_final/comparacao_serie_transformada.csv)
- [Comparação da série diferenciada](./resultados_comparacao/comparacao_final/comparacao_serie_diferenciada.csv)
- [Comparação da ACF](./resultados_comparacao/comparacao_final/comparacao_acf.csv)
- [Comparação da PACF](./resultados_comparacao/comparacao_final/comparacao_pacf.csv)
- [Comparação das métricas do modelo](./resultados_comparacao/comparacao_final/comparacao_metricas_modelo.csv)
- [Comparação dos resíduos](./resultados_comparacao/comparacao_final/comparacao_residuos.csv)
- [Comparação do tempo de execução](./resultados_comparacao/comparacao_final/comparacao_tempo_execucao.csv)
