#!/usr/bin/env Rscript
# Script para gerar os CSVs de "r_manual" conforme especificação em description.txt

args <- commandArgs(trailingOnly = TRUE)
input_csv <- ifelse(length(args) >= 1, args[1], "pluvio 06-23 to 06-26.csv")
out_dir <- ifelse(length(args) >= 2, args[2], "resultados_comparacao/r_manual")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

start_time_total <- Sys.time()

cat("Lendo:", input_csv, "\n")
# tentar detectar separador comum: primeiro tenta read.csv (vírgula), se falhar ou resultar em 1 coluna tenta ';'
df <- tryCatch(read.csv(input_csv, stringsAsFactors = FALSE), error = function(e) NULL)
if (is.null(df) || ncol(df) == 1) {
  df <- tryCatch(read.csv(input_csv, stringsAsFactors = FALSE, sep = ";"), error = function(e) NULL)
}
if (is.null(df) || ncol(df) == 0) stop("Não foi possível ler o arquivo de entrada.")

# Detectar coluna de data (data, date, Data) e coluna de valor (primeira numérica)
col_names <- tolower(names(df))
date_col <- which(col_names %in% c("data", "date"))
if(length(date_col) == 0) date_col <- which(sapply(df, function(x) all(grepl("^\\d{4}-\\d{2}-\\d{2}|\\d{2}/\\d{2}/\\d{4}", as.character(x)))))
date_col <- if(length(date_col) > 0) date_col[1] else NA

num_cols <- which(sapply(df, is.numeric))
value_col <- if(length(num_cols) >= 1) num_cols[1] else NA
if(is.na(value_col)){
  # tentar converter 2a coluna
  if(ncol(df) >= 2) {
    df[[2]] <- suppressWarnings(as.numeric(df[[2]]))
    if(any(!is.na(df[[2]]))) value_col <- 2
  }
}
if(is.na(value_col)) stop("Não foi possível identificar a coluna de valores numéricos.")

indice <- seq_len(nrow(df))
data_col_vals <- if(!is.na(date_col)) df[[date_col]] else rep(NA, nrow(df))
valor <- as.numeric(df[[value_col]])

proc_start <- Sys.time()

# 1. Série Original
serie_original <- data.frame(indice = indice, data = data_col_vals, valor = valor, stringsAsFactors = FALSE)
write.csv(serie_original, file = file.path(out_dir, "serie_original.csv"), row.names = FALSE)

# 2. Estatísticas descritivas
estatisticas <- data.frame(
  metrica = c("media","mediana","minimo","maximo","desvio_padrao","variancia","primeiro_quartil","terceiro_quartil"),
  valor = c(mean(valor, na.rm = TRUE), median(valor, na.rm = TRUE), min(valor, na.rm = TRUE), max(valor, na.rm = TRUE), sd(valor, na.rm = TRUE), var(valor, na.rm = TRUE), quantile(valor, probs = 0.25, na.rm = TRUE), quantile(valor, probs = 0.75, na.rm = TRUE))
)
write.csv(estatisticas, file = file.path(out_dir, "estatisticas_descritivas.csv"), row.names = FALSE)

# 3. Série Transformada (usamos log1p por segurança)
transformacao_nome <- "log1p"
valor_transformado <- log1p(valor)
serie_transformada <- data.frame(indice = indice, data = data_col_vals, valor_original = valor, valor_transformado = valor_transformado)
write.csv(serie_transformada, file = file.path(out_dir, "serie_transformada.csv"), row.names = FALSE)
writeLines(paste0("transformacao: ", transformacao_nome), con = file.path(out_dir, "transformacao.txt"))

# 4. Série Diferenciada
diff_1 <- c(NA, diff(valor))
diff_2 <- c(NA, NA, diff(diff(valor)))
serie_diferenciada <- data.frame(indice = indice, data = data_col_vals, diff_1 = diff_1, diff_2 = diff_2)
write.csv(serie_diferenciada, file = file.path(out_dir, "serie_diferenciada.csv"), row.names = FALSE)

# 5. ACF
lag_max <- 20
acf_res <- acf(valor, plot = FALSE, na.action = na.pass, lag.max = lag_max)
acf_df <- data.frame(lag = acf_res$lag[,1,1], acf = acf_res$acf[,1,1])
write.csv(acf_df, file = file.path(out_dir, "acf.csv"), row.names = FALSE)

# 6. PACF
pacf_res <- pacf(valor, plot = FALSE, na.action = na.pass, lag.max = lag_max)
pacf_df <- data.frame(lag = pacf_res$lag, pacf = pacf_res$acf)
write.csv(pacf_df, file = file.path(out_dir, "pacf.csv"), row.names = FALSE)

# 7. Ajuste de modelo: tentar usar forecast::auto.arima se disponível, senão usar arima(1,0,1)
use_forecast <- requireNamespace("forecast", quietly = TRUE)
model <- NULL
if(use_forecast){
  library(forecast)
  model <- tryCatch(auto.arima(valor), error = function(e) NULL)
}
if(is.null(model)){
  # fallback simples: arima(1,0,1)
  model <- tryCatch(arima(valor, order = c(1,0,1)), error = function(e) NULL)
}

metricas <- data.frame(parametro = character(0), valor = numeric(0), stringsAsFactors = FALSE)
if(!is.null(model)){
  coefs <- coefficients(model)
  if(length(coefs) > 0){
    metricas <- rbind(metricas, data.frame(parametro = names(coefs), valor = as.numeric(coefs), stringsAsFactors = FALSE))
  }
  # AIC / BIC / logLik / sigma2
  aicv <- tryCatch(AIC(model), error = function(e) NA)
  bicv <- tryCatch(BIC(model), error = function(e) NA)
  loglikv <- tryCatch(logLik(model), error = function(e) NA)
  sigma2v <- tryCatch(var(residuals(model), na.rm = TRUE), error = function(e) NA)
  metricas <- rbind(metricas, data.frame(parametro = c("aic","bic","logLik","sigma2"), valor = c(as.numeric(aicv), as.numeric(bicv), as.numeric(loglikv), as.numeric(sigma2v)), stringsAsFactors = FALSE))
}
write.csv(metricas, file = file.path(out_dir, "metricas_modelo.csv"), row.names = FALSE)

# 8. Resíduos
residuos <- rep(NA, length(valor))
if(!is.null(model)){
  residuos_raw <- residuals(model)
  # residuals may be shorter; align at the end
  len_r <- length(residuos_raw)
  residuos[(length(residuos) - len_r + 1):length(residuos)] <- residuos_raw
  residuos_df <- data.frame(indice = indice, data = data_col_vals, residuo = residuos)
  write.csv(residuos_df, file = file.path(out_dir, "residuos.csv"), row.names = FALSE)
} else {
  residuos_df <- data.frame(indice = indice, data = data_col_vals, residuo = residuos)
  write.csv(residuos_df, file = file.path(out_dir, "residuos.csv"), row.names = FALSE)
}

# 9. Previsões (h = 10 por padrão)
h <- 10
previsao_df <- data.frame()
if(!is.null(model)){
  if(use_forecast){
    fcast <- forecast::forecast(model, h = h)
    dates_forecast <- seq_len(h)
    previsao_df <- data.frame(horizonte = seq_len(h), data = NA, previsto = as.numeric(fcast$mean), limite_inferior = as.numeric(fcast$lower[,2]), limite_superior = as.numeric(fcast$upper[,2]))
  } else {
    pr <- predict(model, n.ahead = h)
    previsto <- as.numeric(pr$pred)
    se <- as.numeric(pr$se)
    previsao_df <- data.frame(horizonte = seq_len(h), data = NA, previsto = previsto, limite_inferior = previsto - 1.96 * se, limite_superior = previsto + 1.96 * se)
  }
  write.csv(previsao_df, file = file.path(out_dir, "previsoes.csv"), row.names = FALSE)
} else {
  # escrever arquivo vazio com cabeçalho mínimo
  previsao_df <- data.frame(horizonte = integer(0), data = character(0), previsto = numeric(0), limite_inferior = numeric(0), limite_superior = numeric(0))
  write.csv(previsao_df, file = file.path(out_dir, "previsoes.csv"), row.names = FALSE)
}

proc_end <- Sys.time()

# 10. Tempo de execução
tempo_execucao <- data.frame(ambiente = "r_manual", execucao = 1, tempo_interacao_seg = NA, tempo_processamento_seg = as.numeric(difftime(proc_end, proc_start, units = "secs")), tempo_total_seg = as.numeric(difftime(Sys.time(), start_time_total, units = "secs")), stringsAsFactors = FALSE)
write.csv(tempo_execucao, file = file.path(out_dir, "tempo_execucao.csv"), row.names = FALSE)

cat("Arquivos gerados em:", normalizePath(out_dir), "\n")
