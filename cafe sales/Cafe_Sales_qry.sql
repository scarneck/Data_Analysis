# Projeto de limpeza de dados usando MySQL

-- Fiz o download do dataset 'Dirty Cafe Sales Dataset' do kaggle e irei realizar a limpeza dos dados pelo MySQL



# Criando uma database para importar o dataset.
-- drop database if exists cafe_sales;
create database cafe_sales;
use cafe_sales;


# Overview
describe dirty_cafe_sales;
select * from dirty_cafe_sales;

select item, count(item) as quantity from dirty_cafe_sales group by item order by quantity;
select `Payment Method`, count(`Payment Method`) as quantity from dirty_cafe_sales group by `Payment Method` order by quantity;
select location, count(location) as quantity from dirty_cafe_sales group by location order by quantity;
-- Muitos dados com erro, nulos e/ou desconhecidos

select `Transaction ID` ,count(`Transaction ID`) qnt from dirty_cafe_sales  group by `Transaction ID`  having qnt>1 order by qnt desc;
-- Nenhuma transação repetida


# Criando tabela stagging para realizar limpeza sem comprometer os dados crus
create table stg_cafe like dirty_cafe_sales;
insert into stg_cafe select * from dirty_cafe_sales;
select * from stg_cafe;

-- Produtos (com erros, blanks e desconhecidos)
select distinct item from stg_cafe;

-- Preços possíves (sem erros)
select distinct `Price Per Unit` from stg_cafe;

-- Sem quantidades nulas ou com valores perdidos
select distinct quantity from stg_cafe;

-- total gasto (precisa de correção)
select distinct `Total Spent` from stg_cafe;

-- Substituindo valores não numéricos por nulo
update stg_cafe set `Total Spent` = null where `Total Spent` in ('UNKNOWN', 'ERROR', '');
update stg_cafe set `Total Spent` = (`Price Per Unit` * Quantity) where `Total Spent` is null;
select distinct `Total Spent`from stg_cafe;

alter table stg_cafe modify column `Price Per Unit` decimal(10,2);
alter table stg_cafe modify column Quantity integer;
alter table stg_cafe modify column `Total Spent` decimal(10,2);

/* 
Produto: Preço da Unidade
coffee: 2
Cake: 3*
Cookie: 1
Salad: 5
Smoothie: 4*
Sandwich: 4*
Juice: 3*
Tea: 1.5
*/
-- Corrigindo a coluna item
update stg_cafe set Item = 'Coffee' where `Price Per Unit` =2;
update stg_cafe set Item = 'Cookie' where `Price Per Unit` =1;
update stg_cafe set Item = 'Salad' where `Price Per Unit`  =5;
update stg_cafe set Item = 'Tea' where `Price Per Unit`    =1.5;

-- Cake, smoothie, sandwich e juicy possuem preços que se assemelham.
-- Para lidar com eles podemos:
-- 1. Substituir parcela dos valores perdidos por cada um dos produtos;
-- 2. Deixar eles como Nulos ou 'Desconhecido';
-- 3. Simplesmente deletar eles.

-- No caso vou fazer a primeira opção para fins de prática.

# Substituindo valores nulos, desconhecidos e falso por possíveis correspondentes
with cte as(
	select `Transaction ID`, item,`Price Per Unit`, row_number() over(order by rand()) as rn, count(*)  over() as quant 
	from stg_cafe 
    where item in (null,'ERROR','UNKNOWN','') and `Price Per Unit`= 3
) 
update stg_cafe sc join cte  on sc.`Transaction ID` = cte.`Transaction ID` 
set sc.item = case 
	when cte.rn < cte.quant/2 then 'Cake' 
    else 'Juice' end;
-- Substituí a primeira metade para Cake e a outra para Juice.

with cte2 as(
	select `Transaction ID`, item, row_number() over(order by rand()) as rn, count(*) over() as quant
    from stg_cafe
    where item in (null,'ERROR','UNKNOWN','') and `Price Per Unit`= 4
)
update stg_cafe sc join cte2 on sc.`Transaction ID` = cte2.`Transaction ID` 
set sc.item= case 
	when cte2.rn< cte2.quant/2 then 'Smoothie'
	else 'Sandwich' end;
-- E agora substituí a primeira metade para Smoothie e a outra para Sandwich.


-- O processo não será diferente com os demais
select  `Transaction Date`, count(`Transaction Date`)as dates from stg_cafe group by `Transaction Date` order by dates desc;
select Location, count(location) as num_travels from stg_cafe group by location order by num_travels desc;
select `Payment Method`, count(`Payment Method`) as num_pay from stg_cafe group by `Payment Method` order  by num_pay desc ;

update stg_cafe set `Transaction Date` = null where `Transaction Date` in ('ERROR',  'UNKNOWN', '');
update stg_cafe set location  = null where location  in ('ERROR',  'UNKNOWN', '');
update stg_cafe set `Payment Method` = null where `Payment Method` in ('ERROR',  'UNKNOWN', '');

select `Transaction Date`, count(`Transaction Date`)as qnt from dirty_cafe_sales group by `Transaction Date` order by qnt desc;

-- 2023-06-16, 2023-07-21 são as datas com mais transações então irei colocar os erros nestas datas
with dt as (
	select `Transaction ID`,`Transaction Date`, row_number() over() as rn, count(*) over() as qnt
	from stg_cafe 
    where `Transaction Date` is null
)
update stg_cafe sc join dt on sc.`Transaction ID`= dt.`Transaction ID`
set sc.`Transaction Date`= case when dt.rn< dt.qnt/2 then '2023-06-16' else '2023-07-21' end;
-- coloquei metade dos dados perdidos como '2023-06-16' e a outra metade como '2023-07-21'


select location ,count(location) from dirty_cafe_sales group by location;

with loc as (
	select `Transaction ID`, location,row_number() over() as rn, count(*) over() as qnt 
    from stg_cafe
    where location is null
)
update stg_cafe sc join loc on sc.`Transaction ID` = loc.`Transaction ID`
set sc.location = case when loc.rn < loc.qnt/2 then 'Takeaway' else 'In-store' end;
-- coloquei parte como 'Takeaway' e parte como 'In-store'

select `Payment Method`, count(*)as pay from stg_cafe group by `Payment Method` order by pay desc;

with pay as(
	select `Transaction ID`, `Payment Method`, row_number() over() as rn, count(*) over()as qnt
    from stg_cafe
    where `Payment Method` is null
)
update stg_cafe sc join pay on sc.`Transaction ID` = pay.`Transaction ID`
set sc.`Payment Method` = case 
	when pay.rn < pay.qnt/3 then 'Digital Wallet' 
	when (pay.rn < pay.qnt*2/3 and pay.rn> pay.qnt/3) then 'Credit Card'
	else 'Cash' end;
-- dividi os dados perdidos em três e coloquei proporcionalmente 'Digital Wallet', 'Credit Card' e 'Cash'


# padronizar as datas das transações
select `Transaction Date`, str_to_date(trim(`Transaction Date`),'%Y-%m-%d')as newdate from stg_cafe;
update stg_cafe set `Transaction Date`= str_to_date(trim(`Transaction Date`),'%Y-%m-%d');
select * from stg_cafe;

### Com isso a limpeza está concluída e os dados estão prontos para uma possível Análise Exploratória (EDA).
