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


# Função 3: Empilhamento dos três arquivos anuais --------

empilhar_internacoes <- function(arq_23, arq_24, arq_25) {
  caminhos <- c(arq_23, arq_24, arq_25)
  names(caminhos) <- caminhos
  
  caminhos |>
    map(~ ler_internacao(.x)) |>
    list_rbind(names_to = "origem") |>
    mutate(
      ano = parse_number(origem)
    ) |>
    select(-origem)
}


# Função 4: Transformação longa, tratamento de NAs e junção ---------------

processar_internacoes <- function(tabela_empilhada, cadastro){
meses_nivel <- c("janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro")
  
  tabela_completa <- tabela_empilhada |>
    pivot_longer(
      cols = janeiro:dezembro,
      names_to = "mes",
      values_to = "internacoes"
    ) |>
    mutate(
      mes = factor(mes, levels = meses_nivel),
      registrado = !is.na(internacoes),
      internacoes = replace_na(internacoes, 0)
    ) |>
    left_join(cadastro, by = "codigo", relationship = "many-to-one") |>
    mutate(medida_relativa = internacoes / leitos)
  
  return(tabela_completa)
}


# Função 5: Conferência das linhas, NA e soma por ano ---------------------

gerar_conferencia <- function(tabela_empilhada) {
  # Métricas de conferência por ano
  resumo_conferencia <- tabela_empilhada |>
    pivot_longer(
      cols = janeiro:dezembro, 
      names_to = "mes", 
      values_to = "internacoes") |>
    group_by(ano) |>
    summarise(
      n_linhas = n(),
      meses_sem_registro = sum(is.na(internacoes)),
      soma_internacoes = sum(internacoes, na.rm = TRUE),
      .groups = "drop"
    )
  
  return(resumo_conferencia)
}


# Função 6: Resumo por unidade --------------------------------------------

gerar_resumo_unidade <- function(tabela_completa) {
  tabela_completa |>
    group_by(codigo, nome, natureza) |>
    summarise(
      meses_registro = sum(registrado),
      total_ano = sum(internacoes),
      media_relativa = mean(medida_relativa),
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
