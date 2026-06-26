#!/usr/bin/env Rscript
# Script para comparar os CSVs gerados por r_manual e esa_tool

args <- commandArgs(trailingOnly = TRUE)
dir_manual <- ifelse(length(args) >= 1, args[1], "resultados_comparacao/r_manual")
dir_esa <- ifelse(length(args) >= 2, args[2], "resultados_comparacao/esa_tool")
out_dir <- ifelse(length(args) >= 3, args[3], "resultados_comparacao/comparacao_final")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tolerancia <- 1e-4

mae <- function(x) mean(abs(x), na.rm = TRUE)
rmse <- function(x) sqrt(mean((x)^2, na.rm = TRUE))

read_csv_safe <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(read.csv(path, stringsAsFactors = FALSE), error = function(e) NULL)
}

# 1. serie_original
man_orig <- read_csv_safe(file.path(dir_manual, "serie_original.csv"))
esa_orig <- read_csv_safe(file.path(dir_esa, "serie_original.csv"))
res_summary <- list()
if (!is.null(man_orig) && !is.null(esa_orig)) {
  n_man <- nrow(man_orig)
  n_esa <- nrow(esa_orig)
  dates_equal <- FALSE
  if ("data" %in% names(man_orig) && "data" %in% names(esa_orig)) {
    dates_equal <- all(as.character(man_orig$data) == as.character(esa_orig$data))
  }
  val_diff <- NA
  if ("valor" %in% names(man_orig) && "valor" %in% names(esa_orig)) {
    m <- min(n_man, n_esa)
    diffs <- esa_orig$valor[1:m] - man_orig$valor[1:m]
    val_diff <- c(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs))
  }
  res_summary$serie_original <- list(n_man = n_man, n_esa = n_esa, dates_equal = dates_equal, valor_diff = val_diff)
  write.csv(data.frame(t(unlist(res_summary$serie_original))), file = file.path(out_dir, "comparacao_serie_original.csv"), row.names = FALSE)
}

# 2. estatisticas_descritivas
man_stats <- read_csv_safe(file.path(dir_manual, "estatisticas_descritivas.csv"))
esa_stats <- read_csv_safe(file.path(dir_esa, "estatisticas_descritivas.csv"))
if (!is.null(man_stats) && !is.null(esa_stats)) {
  merged <- merge(man_stats, esa_stats, by = "metrica", suffixes = c("_man","_esa"), all = TRUE)
  merged$diff_abs <- abs(merged$valor_esa - merged$valor_man)
  merged$diff_rel_percent <- with(merged, ifelse(abs(valor_man) > 0, (abs(valor_esa - valor_man)/abs(valor_man))*100, NA))
  write.csv(merged, file = file.path(out_dir, "comparacao_estatisticas_descritivas.csv"), row.names = FALSE)
}

compare_numeric_by_index <- function(file_man, file_esa, out_name, key = "indice") {
  man <- read_csv_safe(file_man)
  esa <- read_csv_safe(file_esa)
  if (is.null(man) || is.null(esa)) return(NULL)
  merged <- merge(man, esa, by = key, suffixes = c("_man","_esa"))
  numeric_cols <- intersect(names(merged), grep("_man$|_esa$", names(merged), value = TRUE))
  # identify pairs
  metrics <- data.frame(column = character(0), max_abs = numeric(0), MAE = numeric(0), RMSE = numeric(0), stringsAsFactors = FALSE)
  # find base names
  bases <- unique(gsub("_(man|esa)$", "", numeric_cols))
  for (b in bases) {
    a <- merged[[paste0(b, "_asa")]]
    manv <- merged[[paste0(b, "_man")]]
    esav <- merged[[paste0(b, "_esa")]]
    if (!is.null(manv) && !is.null(esav)) {
      diffs <- esav - manv
      metrics <- rbind(metrics, data.frame(column = b, max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs), stringsAsFactors = FALSE))
    }
  }
  write.csv(metrics, file = file.path(out_dir, out_name), row.names = FALSE)
}

# 3. serie_transformada
man_tr <- read_csv_safe(file.path(dir_manual, "serie_transformada.csv"))
esa_tr <- read_csv_safe(file.path(dir_esa, "serie_transformada.csv"))
if (!is.null(man_tr) && !is.null(esa_tr)) {
  m <- min(nrow(man_tr), nrow(esa_tr))
  diffs <- esa_tr$valor_transformado[1:m] - man_tr$valor_transformado[1:m]
  df <- data.frame(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs))
  write.csv(df, file = file.path(out_dir, "comparacao_serie_transformada.csv"), row.names = FALSE)
}

# 4. serie_diferenciada
man_diff <- read_csv_safe(file.path(dir_manual, "serie_diferenciada.csv"))
esa_diff <- read_csv_safe(file.path(dir_esa, "serie_diferenciada.csv"))
if (!is.null(man_diff) && !is.null(esa_diff)) {
  # compare available numeric diff columns
  common <- intersect(names(man_diff), names(esa_diff))
  cols <- setdiff(common, c("indice","data"))
  out <- data.frame(col = cols, max_abs = NA, MAE = NA, RMSE = NA, stringsAsFactors = FALSE)
  for (i in seq_along(cols)) {
    c <- cols[i]
    m <- min(nrow(man_diff), nrow(esa_diff))
    diffs <- esa_diff[[c]][1:m] - man_diff[[c]][1:m]
    out$max_abs[i] <- max(abs(diffs), na.rm = TRUE)
    out$MAE[i] <- mae(diffs)
    out$RMSE[i] <- rmse(diffs)
  }
  write.csv(out, file = file.path(out_dir, "comparacao_serie_diferenciada.csv"), row.names = FALSE)
}

# 5. acf
man_acf <- read_csv_safe(file.path(dir_manual, "acf.csv"))
esa_acf <- read_csv_safe(file.path(dir_esa, "acf.csv"))
if (!is.null(man_acf) && !is.null(esa_acf)) {
  m <- merge(man_acf, esa_acf, by = "lag", suffixes = c("_man","_esa"))
  diffs <- m$acf_esa - m$acf_man
  write.csv(data.frame(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs)), file = file.path(out_dir, "comparacao_acf.csv"), row.names = FALSE)
}

# 6. pacf
man_pacf <- read_csv_safe(file.path(dir_manual, "pacf.csv"))
esa_pacf <- read_csv_safe(file.path(dir_esa, "pacf.csv"))
if (!is.null(man_pacf) && !is.null(esa_pacf)) {
  m <- merge(man_pacf, esa_pacf, by = "lag", suffixes = c("_man","_esa"))
  diffs <- m$pacf_esa - m$pacf_man
  write.csv(data.frame(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs)), file = file.path(out_dir, "comparacao_pacf.csv"), row.names = FALSE)
}

# 7. metricas_modelo
man_metrics <- read_csv_safe(file.path(dir_manual, "metricas_modelo.csv"))
esa_metrics <- read_csv_safe(file.path(dir_esa, "metricas_modelo.csv"))
if (!is.null(man_metrics) && !is.null(esa_metrics)) {
  m <- merge(man_metrics, esa_metrics, by = "parametro", suffixes = c("_man","_esa"), all = TRUE)
  m$diff_abs <- abs(m$valor_esa - m$valor_man)
  write.csv(m, file = file.path(out_dir, "comparacao_metricas_modelo.csv"), row.names = FALSE)
}

# 8. residuos
man_res <- read_csv_safe(file.path(dir_manual, "residuos.csv"))
esa_res <- read_csv_safe(file.path(dir_esa, "residuos.csv"))
if (!is.null(man_res) && !is.null(esa_res)) {
  m <- merge(man_res, esa_res, by = "indice", suffixes = c("_man","_esa"))
  diffs <- m$residuo_esa - m$residuo_man
  write.csv(data.frame(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs), media_diff = mean(diffs, na.rm = TRUE), sd_diff = sd(diffs, na.rm = TRUE)), file = file.path(out_dir, "comparacao_residuos.csv"), row.names = FALSE)
}

# 9. previsoes
man_pred <- read_csv_safe(file.path(dir_manual, "previsoes.csv"))
esa_pred <- read_csv_safe(file.path(dir_esa, "previsoes.csv"))
if (!is.null(man_pred) && !is.null(esa_pred)) {
  common <- intersect(names(man_pred), names(esa_pred))
  # compare previsto
  m <- merge(man_pred, esa_pred, by = intersect(c("horizonte","data"), names(man_pred)), suffixes = c("_man","_esa"))
  if (nrow(m) > 0 && "previsto_man" %in% names(m)) {
    diffs <- m$previsto_esa - m$previsto_man
    out <- data.frame(max_abs = max(abs(diffs), na.rm = TRUE), MAE = mae(diffs), RMSE = rmse(diffs))
    write.csv(out, file = file.path(out_dir, "comparacao_previsoes.csv"), row.names = FALSE)
  }
}

# 10. tempo_execucao
man_time <- read_csv_safe(file.path(dir_manual, "tempo_execucao.csv"))
esa_time <- read_csv_safe(file.path(dir_esa, "tempo_execucao.csv"))
if (!is.null(man_time) && !is.null(esa_time)) {
  # comparar tempo_total_seg para execucao 1
  m <- merge(man_time, esa_time, by = "execucao", suffixes = c("_man","_esa"))
  if (nrow(m) > 0) {
    m$reducao_abs <- m$tempo_total_seg_man - m$tempo_total_seg_esa
    m$reducao_percent <- (m$reducao_abs / m$tempo_total_seg_man) * 100
    write.csv(m, file = file.path(out_dir, "comparacao_tempo_execucao.csv"), row.names = FALSE)
  }
}

cat("Comparação escrita em:", normalizePath(out_dir), "\n")
