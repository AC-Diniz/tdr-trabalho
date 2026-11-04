------------------------------------------------------------------------

editor_options: markdown: wrap: 72 ---

# Trabalho Intermediário - TDR

## Sobre o projeto

O projeto faz a análise baseada nos dados sobre internações nos hospitais de uma região de Saúde Unidade de observação: hospital

O objetivo é implementar o fluxo de análise reprodutível em R, utilizando o pacote `targets`para o gerenciamento de dependências do pipeline, `renv`para criar o ambiente de pacotes, Quarto para a renderização do relatório final e o GitHub para a integração contínua.

### Arquivos

Para este projeto, foram utilizados os arquivos `internacoes_2023.csv`, `internacoes_2024.csv` e `internacoes_2025.csv`, que contêm os registros do número de internações ao longo do ano. Cada planilha apresenta uma linha por unidade e uma coluna por mês do ano.A coluna codigo identifica a unidade, e as colunas jan a dez trazem o valor medido: internações no mês. Mês sem registro aparece como "-". Além desses, foi utilizado também o `cadastro.csv`, que registra o código e nome dos hospitais, número de leitos e a natureza. Ele tem uma linha por unidade, com as colunas: codigo: identificador da unidade, o mesmo das medições nome: nome da unidade natureza: categoria - Público, Filantrópico ou Privado leitos: porte - leitos de internação

## Estrutura do projeto

- `_targets.R`: Script de configuração e definição do pipeline de dados e relatórios;
- `R/`: pasta com as funções utilizadas no projeto;
- `relatorio.qmd`: documento Quarto que gera o relatório final;
- `rev.lock` e `.Rprofile`: arquivos de controle de versões e dependências do ambiente R;
- `.github/workflows/relatorio.yaml`: integração contínua no GitHub Actions;
- `.lintr`: configurações do estilo do projeto

## Pré-requisitos

Para a executar o projeto localmente, precisa de:

- R (versão 4.x ou superior); 
- Linux/ WSL Ubuntu (recomendado); 
- Dependências de sistemas (para a compilação do pacotes e renderização)

``` 
sudo apt-get update
sudo apt-get install -y cmake libglpk-dev libuv1-dev libml2-dev make pandoc
```
## Como reproduzir o projeto
1. Clonar o repositório no ramo correto (`trabalho`):

```
git clone -b trabalho [https://github.com/AC-Diniz/tdr-trabalho.git](https://github.com/AC-Diniz/tdr-trabalho.git)
cd tdr-trabalho
```
2. Restaurar o ambiente de pacotes com o `renv`:
Abra o R na raiz do projeto e execute:

```
renv::restore(prompt = FALSE)
```
3. Executar a pipeline completa com o `targets`:
```
targets::tar_make()
```
## Declaração do uso de LLMs
Para auxiliar no desenvolvimento desse trabalho, utilizei a IA Gemini.
Ela foi utilizada na configuração e resolução dos erros do WSL (correção do problema ao utilizar o `renv::status()`), estruturação do .lintr e README. Além de ser usada para me auxiliar na criação das funções com base na lista 3 e suporte na sincronização com o `renv`

### Como os resultados foram testados
Os códigos foram executados localmente por meio do `renv::restore()` e `targets::tar_make()`, e validados através da aprovação na integração contínua do GitHub Actions.

