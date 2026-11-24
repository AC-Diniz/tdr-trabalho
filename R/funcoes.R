
# Carregando os pacotes ---------------------------------------------------
# pacotes do trabalho
library(readr)
library(targets)
library(tarchetypes)
library(quarto)
library(renv)
library(lintr)
# pacotes da análise (tidyverse)
library(dplyr)
library(tidyr)
library(purrr)
library(ggplot2)


# Função 1: Leitura do cadastro -------------------------------------------

ler_cadastro <- function(caminho) {
  read_csv2(
    file = caminho,
    locale = locale(encoding = "ISO-8859-1"),
    na = c("", "NA", "N/A")
  )
}


# Função 2: Leitura de uma arquivo anual de internações -------------------

ler_internacao <- function(caminho) {
  read_csv2(
    file = caminho,
    locale = locale(decimal_mark = "."),
    col_types = cols(
      codigo = col_character(),
      .default = col_double()
    ),
    na = c("", "NA", "-", "NAO_INFORMADO", "NAO-INFORMADO")
  )
}


# Função 3: Empilhamento, transformação longa, tratamento de NAs e --------

processar_internacoes <- function(arq_23, arq_24, arq_25, cadastro) {
  caminhos <- c(arq_23, arq_24, arq_25)
  names(caminhos) <- caminhos
  
  tabela_empilhada <- caminhos |>
    map(~ ler_internacao(.x)) |>
    list_rbind(names_to = "origem") |>
    mutate(
      ano = parse_number(origem)
    )
  
  meses_nivel <- c("jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez")
  
  tabela_completa <- tabela_empilhada |>
    select(-origem) |>
    pivot_longer(
      cols = jan:dez,
      names_to = "mes",
      values_to = "internacoes"
    ) |>
    mutate(
      mes = factor(mes, levels = meses_nivel),
      internacoes = replace_na(internacoes, 0)
    ) |>
    left_join(cadastro, by = "codigo", relationship = "many-to-many") |>
    mutate(medida_relativa = internacoes / leitos)
  
  return(tabela_completa)
}


# Função 4: Conferência das linhas, NA e soma por ano ---------------------

gerar_conferencia <- function(arq_23, arq_24, arq_25) {
  caminhos <- c(arq_23, arq_24, arq_25)
  names(caminhos) <- caminhos
  
  tabela_empilhada <- caminhos |>
    map(~ ler_internacao(.x)) |>
    list_rbind(names_to = "origem") |>
    mutate(ano = parse_number(origem))
  
  # Métricas de conferência por ano
  resumo_conferencia <- tabela_empilhada |>
    pivot_longer(cols = jan:dez, names_to = "mes", values_to = "internacoes") |>
    group_by(ano) |>
    summarise(
      n_linhas = n(),
      meses_sem_registro = sum(is.na(internacoes)),
      soma_internacoes = sum(internacoes, na.rm = TRUE),
      .groups = "drop"
    )
  
  return(resumo_conferencia)
}


# Função 5: Resumo por unidade --------------------------------------------

gerar_resumo_unidade <- function(tabela_completa) {
  tabela_completa |>
    group_by(codigo, nome, natureza) |>
    summarise(
      meses_registro = sum(internacoes >= 0),
      total_ano = sum(internacoes),
      media_relativa = mean(medida_relativa),
      .groups = "drop"
    ) |>
    arrange(desc(media_relativa))
}


# Função 6: Resumo por categoria ------------------------------------------

gerar_resumo_categoria <- function(resumo_unidade) {
  resumo_unidade |>
    group_by(natureza) |>
    summarise(
      n_unidades = n(),
      total_ano = sum(total_ano),
      media_relativa = mean(media_relativa),
      .groups = "drop"
    )
}


# Função 7: Tabela de apresentação por categoria e ano --------------------

gerar_tabela_apresentacao <- function(tabela_completa) {
  tabela_completa |>
    group_by(natureza, ano) |>
    summarise(total_anual = sum(internacoes), .groups = "drop") |>
    pivot_wider(
      names_from = ano,
      values_from = total_anual
    )
}
