-- Análise Exploratória (EDA)

# Overview
select * from stg_cafe;

# Período dos dados
select min(`Transaction Date`), max(`Transaction Date`) from stg_cafe;

# Quantidade vendidade em média de cada produto
select item, avg(quantity) from stg_cafe group by item order by 2 desc;
-- Em média, clientes compram aproximadamente 3 unidades de cada produto.

# Produtos mais vendidos e que trouxeram mais receita
select Item, `Price Per Unit`, sum(quantity)as Qnt_Sold, sum(`Total Spent`) as Receipt
from stg_cafe 
group by 1,2 
order by receipt desc;
-- A Salada trouxe a maior receita no período sendo o quarto produto que mais vendeu.
-- Enquanto o Suco foi o mais vendido trazendo a quarta maior receita.

# Métodos de Pagamento mais utilizados pelo local de compra/consumo.
select location, `Payment Method`, count(`Payment Method`) as Payment_Method_Counts
from stg_cafe 
group by 1, 2 
order by 1,3 desc;
-- 37,8% das compras 'In-Store' são pagas em dinheiro vivo.
-- Enquanto 38,44% das compras 'Takeaway' são pagas via carteira digital.

# Meses que trouxeram maior faturamento.
select month(`Transaction Date`)as month_,sum(Quantity)as qnt_sold,sum(`Total Spent`) as receita 
from stg_cafe 
group by 1 
order by 3 desc; 
-- junho, julho, e outubro foram os meses com maior venda e trouxeram as maiores receitas.

# Dias que trazem mais faturamento
with cte as (
	select day(`Transaction Date`)as day_,sum(Quantity)as qnt_sold,sum(`Total Spent`) as receipt 
	from stg_cafe 
	group by 1
	order by 3 desc
), cte2 as (
	select *,avg(receipt)over() as avg_receipt 
    from cte
)
select *, ((receipt/avg_receipt-1)*100) as `rcp/avg_rcp` 
from cte2 
order by `rcp/avg_rcp` desc;
-- Nos dias 16, as receitas são em média 85.87% superiores às médias diárias.

