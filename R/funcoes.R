# Função 1: Leitura do cadastro -------------------------------------------

ler_cadastro <- function(caminho) {
  read_csv2(
    file = caminho,
    locale = locale(encoding = "ISO-8859-1"),
    col_types = cols(
      codigo = col_character(),
      nome = col_character(),
      natureza = col_character(),
      leitos = col_double()
    ),
    na = c("", "NA", "N/A")
  )
}


# Função 2: Leitura de um arquivo anual de internações --------------------

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


# Função 3: Empilhamento dos três arquivos anuais -------------------------

empilhar_internacoes <- function(arq_23, arq_24, arq_25) {
  # O ano vem do nome dado a cada caminho, e não do texto do caminho
  caminhos <- c(`2023` = arq_23, `2024` = arq_24, `2025` = arq_25)
  
  caminhos |>
    map(ler_internacao) |>
    list_rbind(names_to = "ano") |>
    mutate(ano = as.integer(ano))
}


# Função 4: Transformação longa, tratamento de NAs e junção ---------------

processar_internacoes <- function(tabela_empilhada, cadastro) {
  # Os arquivos usam os meses abreviados (jan, fev, ...); o fator guarda a
  # ordem do calendário e mostra o nome completo no relatório
  meses_nivel <- c(
    "jan", "fev", "mar", "abr", "mai", "jun",
    "jul", "ago", "set", "out", "nov", "dez"
  )
  meses_nome <- c(
    "janeiro", "fevereiro", "março", "abril", "maio", "junho",
    "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"
  )
  
  tabela_empilhada |>
    pivot_longer(
      cols = jan:dez,
      names_to = "mes",
      values_to = "internacoes"
    ) |>
    mutate(
      mes = factor(mes, levels = meses_nivel, labels = meses_nome),
      # Decisão sobre meses sem registro (Exercício 4 da Lista 03):
      # o mês ausente (NA) vira 0 internações, e a coluna `registrado`
      # guarda que ele não tinha registro. Isso reduz `medida_relativa`
      # das unidades com ausência, mas não altera as somas.
      registrado = !is.na(internacoes),
      internacoes = replace_na(internacoes, 0)
    ) |>
    left_join(cadastro, by = "codigo", relationship = "many-to-one") |>
    mutate(medida_relativa = internacoes / leitos)
}


# Função 5: Conferência das linhas, NA e soma por ano ---------------------

gerar_conferencia <- function(tabela_empilhada) {
  # Linhas de cada arquivo anual, contadas antes do formato longo
  linhas <- tabela_empilhada |>
    count(ano, name = "n_linhas")
  
  tabela_empilhada |>
    pivot_longer(
      cols = jan:dez,
      names_to = "mes",
      values_to = "internacoes"
    ) |>
    group_by(ano) |>
    summarise(
      meses_sem_registro = sum(is.na(internacoes)),
      soma_internacoes = sum(internacoes, na.rm = TRUE),
      .groups = "drop"
    ) |>
    left_join(linhas, by = "ano") |>
    # A ordem das colunas é a que o relatório.qmd usa em col.names
    select(ano, n_linhas, meses_sem_registro, soma_internacoes)
}


# Função 6: Resumo por unidade --------------------------------------------

# Atenção: soma os três anos (2023 a 2025) de cada unidade.
gerar_resumo_unidade <- function(tabela_completa) {
  tabela_completa |>
    group_by(codigo, nome, natureza) |>
    summarise(
      meses_registro = sum(registrado),
      total_ano = sum(internacoes),
      media_relativa = mean(medida_relativa, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(media_relativa))
}


# Função 7: Resumo por categoria ------------------------------------------

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


# Função 8: Tabela de apresentação por categoria e ano --------------------

gerar_tabela_apresentacao <- function(tabela_completa) {
  tabela_completa |>
    group_by(natureza, ano) |>
    summarise(total_anual = sum(internacoes), .groups = "drop") |>
    pivot_wider(
      names_from = ano,
      values_from = total_anual
    )
}


# Função 9: Média da medida relativa por ano e mês ------------------------

gerar_sazonalidade_ano_mes <- function(tabela_completa) {
  tabela_completa |>
    group_by(ano, mes) |>
    summarise(
      media_mensal = mean(medida_relativa, na.rm = TRUE),
      .groups = "drop"
    )
}


# Função 10: Média da medida relativa por mês -----------------------------

gerar_resumo_mes <- function(tabela_completa) {
  tabela_completa |>
    group_by(mes) |>
    summarise(
      media = mean(medida_relativa, na.rm = TRUE),
      .groups = "drop"
    )
}


# Função 11: Indicadores por ano ------------------------------------------

gerar_resumo_ano <- function(tabela_completa) {
  tabela_completa |>
    group_by(ano) |>
    summarise(
      unidades = n_distinct(codigo),
      meses_sem_registro = sum(!registrado),
      total_internacoes = sum(internacoes),
      media_relativa = mean(medida_relativa, na.rm = TRUE),
      .groups = "drop"
    )
}