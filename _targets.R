
# Carregando os pacotes ---------------------------------------------------

library(targets)
library(tarchetypes)


# Carregando as funções do R/ ---------------------------------------------

source("R/funcoes.R")

# Declarando os pacotes que as funções usam
tar_option_set(
  packages = c("readr", "dplyr", "tidyr", "purrr")
)

list(
  # Alvos de arquivos
  tar_target(arq_cadastro, "dados/cadastro.csv", format = "file"),
  tar_target(arq_2023, "dados/internacoes_2023.csv", format = "file"),
  tar_target(arq_2024, "dados/internacoes_2024.csv", format = "file"),
  tar_target(arq_2025, "dados/internacoes_2025.csv", format = "file"),
  
  # Leitura do cadastro
  tar_target(cadastro, ler_cadastro(arq_cadastro)),
  
  # Tabela completa (empilahda e unida ao cadastro)
  tar_target(tabela_completa, processar_internacoes(arq_2023, arq_2024, arq_2025, cadastro)),
  
  # Comparando com o LEIAME.txt
  tar_target(conferencia, gerar_conferencia(arq_2023, arq_2024, arq_2025)),
  
  # Resumos e tabelas de análise
  tar_target(resumo_unidade, gerar_resumo_unidade(tabela_completa)),
  tar_target(resumo_categoria, gerar_resumo_categoria(resumo_unidade)),
  tar_target(tabela_apresentacao, gerar_tabela_apresentacao(tabela_completa)),
  
  # Renderização
  tar_quarto(relatorio, "relatorio.qmd")
)

