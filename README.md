# Plano de Validação Técnica: ESA TOOL vs. Ambiente R

## Objetivo

Comparar tecnicamente os resultados gerados pela **ESA TOOL** com os resultados obtidos por meio da execução manual das mesmas rotinas no ambiente **R**.

A comparação deve considerar dois aspectos principais:

1. **Consistência dos resultados numéricos** produzidos.
2. **Tempo necessário** para executar o mesmo fluxo de análise em cada ambiente.

A avaliação será conduzida em ambiente controlado, utilizando a mesma base de dados, os mesmos parâmetros e as mesmas etapas de análise.

---

## Estrutura de Pastas

Crie a seguinte estrutura de diretórios para organizar o estudo:

```text
resultados_comparacao/
├── r_manual/
├── esa_tool/
└── comparacao_final/

```

- `r_manual/`: Armazena os arquivos gerados pelo script manual em R.
- `esa_tool/`: Armazena os arquivos exportados ou gerados pela ESA TOOL.
- `comparacao_final/`: Armazena os resultados da comparação e validação entre os dois ambientes.

---

## Etapas a Comparar

As seguintes etapas devem ser executadas de forma idêntica nos dois ambientes:

1. Carregamento da base de dados.
2. Cálculo das estatísticas descritivas.
3. Aplicação de transformações (se houver).
4. Aplicação de diferenciação (se houver).
5. Cálculo da ACF (Função de Autocorrelação).
6. Cálculo da PACF (Função de Autocorrelação Parcial).
7. Ajuste do modelo estatístico.
8. Extração dos resíduos.
9. Geração das previsões.
10. Medição do tempo de execução/interação.

---

## Arquivos CSV a Gerar

Cada ambiente deve gerar arquivos com os mesmos nomes e estruturas descritos abaixo.

### 1. Série Original (`serie_original.csv`)

- **Colunas:** `indice`, `data`, `valor`
- **Objetivo:** Validar se os dois ambientes carregaram exatamente os mesmos dados.
- **Comparações:** Número de linhas, igualdade das datas, diferença máxima absoluta entre valores, MAE e RMSE.

### 2. Estatísticas Descritivas (`estatisticas_descritivas.csv`)

- **Colunas:** `metrica`, `valor`
- **Métricas sugeridas:** `media`, `mediana`, `minimo`, `maximo`, `desvio_padrao`, `variancia`, `primeiro_quartil`, `terceiro_quartil`.
- **Comparações:** Diferença absoluta por métrica e diferença relativa percentual (quando aplicável).

### 3. Série Transformada (`serie_transformada.csv`)

- **Colunas:** `indice`, `data`, `valor_original`, `valor_transformado`
- **Transformações possíveis:** Logaritmo natural, raiz quadrada, raiz cúbica ou outra transformação usada na ESA TOOL.
- **Comparações:** Diferença máxima absoluta, MAE e RMSE.
- > **Observação:** Se for usada a transformação logarítmica, registrar exatamente a regra utilizada (ex: `log(x)`, `log1p(x)` ou `log(x + constante)`).

### 4. Série Diferenciada (`serie_diferenciada.csv`)

- **Colunas:** `indice`, `data`, `valor_diferenciado` (ou `diff_1` e `diff_2` caso sejam usadas primeira e segunda diferenciação).
- **Comparações:** Número de observações, alinhamento dos índices, diferença máxima absoluta, MAE e RMSE.
- > **Observação:** A diferenciação reduz o tamanho da série. Por isso, os índices devem ser alinhados corretamente antes de iniciar a comparação.

### 5. ACF (`acf.csv`)

- **Colunas:** `lag`, `acf`
- **Comparações:** Diferença máxima absoluta por defasagem, MAE e RMSE.
- > **Observações:** Usar o mesmo número de defasagens (lags) nos dois ambientes e conferir se o lag 0 está presente em ambos. Se um ambiente incluir o lag 0 e o outro não, padronize antes da comparação.

### 6. PACF (`pacf.csv`)

- **Colunas:** `lag`, `pacf`
- **Comparações:** Diferença máxima absoluta por defasagem, MAE e RMSE.
- > **Observação:** A PACF geralmente começa no lag 1. Certifique-se de padronizar essa estrutura nos dois ambientes.

### 7. Métricas e Parâmetros do Modelo (`metricas_modelo.csv`)

- **Colunas:** `parametro`, `valor`
- **Exemplos por modelo:**
- _ARIMA:_ `ar1`, `ar2`, `ma1`, `ma2`, `sigma2`, `aic`, `bic`, `logLik`
- _Holt-Winters:_ `alpha`, `beta`, `gamma`
- _ARCH/GARCH:_ `omega`, `alpha1`, `beta1`

- **Comparações:** Diferença absoluta dos coeficientes e diferenças de AIC, BIC, logLik e $\sigma^2$ (se aplicável).

### 8. Resíduos (`residuos.csv`)

- **Colunas:** `indice`, `data`, `residuo`
- **Comparações:** Diferença máxima absoluta, MAE, RMSE, média e desvio padrão dos resíduos.
- > **Dica:** Também é possível calcular a ACF/PACF dos resíduos e compará-las separadamente.

### 9. Previsões (`previsoes.csv`)

- **Colunas:** `horizonte`, `data`, `previsto`, `limite_inferior`, `limite_superior` (caso a ESA TOOL não gere intervalos de confiança, utilize apenas `horizonte`, `data`, `previsto`).
- **Comparações:** Diferença máxima absoluta dos valores previstos, MAE, RMSE e diferença dos limites (inferiores e superiores), se houver.

### 10. Tempo de Execução (`tempo_execucao.csv`)

- **Colunas:** `ambiente`, `execucao`, `tempo_interacao_seg`, `tempo_processamento_seg`, `tempo_total_seg`

#### Exemplo de registros do arquivo:

| ambiente   | execucao | tempo_interacao_seg | tempo_processamento_seg | tempo_total_seg |
| ---------- | -------- | ------------------- | ----------------------- | --------------- |
| `r_manual` | 1        | 120.4               | 2.1                     | 122.5           |
| `r_manual` | 2        | 115.0               | 2.0                     | 117.0           |
| `r_manual` | 3        | 118.3               | 2.2                     | 120.5           |
| `esa_tool` | 1        | 35.2                | 1.8                     | 37.0            |
| `esa_tool` | 2        | 33.7                | 1.9                     | 35.6            |
| `esa_tool` | 3        | 34.5                | 1.7                     | 36.2            |

- **Comparações:** Média, mínimo, máximo, desvio padrão, redução absoluta de tempo e redução percentual de tempo.
- **Fórmula da redução percentual:**

$$\text{redução\_percentual} = \frac{\text{tempo\_r\_manual} - \text{tempo\_esa\_tool}}{\text{tempo\_r\_manual}} \times 100$$

---

## Métricas de Comparação Numérica

Para a comparação dos vetores numéricos entre os ambientes, as seguintes fórmulas devem ser aplicadas:

- **Diferença Máxima Absoluta:**

$$\max(|x_{\text{esa\_tool}} - x_{\text{r\_manual}}|)$$

- **MAE (Erro Médio Absoluto):**

$$\text{mean}(|x_{\text{esa\_tool}} - x_{\text{r\_manual}}|)$$

- **RMSE (Raiz do Erro Quadrático Médio):**

$$\sqrt{\text{mean}((x_{\text{esa\_tool}} - x_{\text{r\_manual}})^2)}$$

- **Diferença Relativa Percentual:**

$$\frac{|x_{\text{esa\_tool}} - x_{\text{r\_manual}}|}{|x_{\text{r\_manual}}|} \times 100$$

_(Nota: Utilizar a diferença relativa apenas quando o valor de referência em R não for zero)._

---

## Critério de Equivalência

Para determinar se os ambientes produzem o mesmo resultado prático, adota-se a seguinte tolerância numérica:

$$\text{tolerância} = 1 \times 10^{-4} \quad (1e-4)$$

- **Critério:** Se a **Diferença Máxima Absoluta** for menor ou igual a $1e-4$, os resultados serão formalmente considerados **equivalentes**.
