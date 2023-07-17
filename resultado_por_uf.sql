-- Definição das Common Table Expressions (CTEs)

-- CTE voto_uf: Calcula informações sobre os votos por estado (UF).
with voto_uf as (
    select
        uf.uf as estado,  -- Seleciona o estado (UF).
        count(split_part(e.infoeleitor, ',', 2)) as aptos,  -- Conta o número de eleitores aptos no estado.
        (
            select
                count(*)
            from
                voto
            where
                split_part(voto.infoeleitor, ',', 2) = uf.uf
        ) as total,  -- Conta o total de votos no estado.
        (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000001')  -- Filtra votos da chapa 1.
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as chapa1,  -- Conta o número de votos para a chapa 1 no estado.
        (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000002')  -- Filtra votos da chapa 2.
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as chapa2,  -- Conta o número de votos para a chapa 2 no estado.
        (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000000')  -- Filtra votos em branco.
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as branco,  -- Conta o número de votos em branco no estado.
        (
            select
                count(*)
            from
                votoapurado
            where
                substring(voto, 1, 6) not in (
                    '000000',
                    '000001',
                    '000002'
                )  -- Filtra votos nulos.
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as nulo  -- Conta o número de votos nulos no estado.
    from
        uf  -- Tabela com informações sobre os estados (UF).
        left join eleitor e on uf.uf = split_part(infoeleitor, ',', 2)  -- Junta com a tabela eleitor para obter os eleitores aptos.
        and e.temimpedimento = false  -- Filtra eleitores sem impedimento para votar.
    group by
        uf.uf
    order by
        uf.uf
),

-- CTE data_inicio_fim: Obtém a data de início e fim da eleição.
data_inicio_fim as (
    select
        TO_CHAR(dataInicioEleicao, 'DD/MM/YYYY HH24:MI:SS') as inicio,  -- Converte a data de início para o formato desejado.
        TO_CHAR(dataFimEleicao, 'DD/MM/YYYY HH24:MI:SS') as fim  -- Converte a data de fim para o formato desejado.
    from
        parametroeleicaonet  -- Tabela com informações sobre os parâmetros da eleição.
),

-- CTE total_aptos: Conta o total de eleitores aptos para votar.
total_aptos as (
    select
        count(*) as total_aptos
    from
        eleitor
    where
        temimpedimento = false  -- Filtra eleitores sem impedimento para votar.
),

-- CTE total_votos: Conta o total de eleitores que efetivamente votaram.
total_votos as (
    select
        count(*) as total_votos
    from
        eleitor
    where
        votou = true  -- Filtra eleitores que votaram.
),

-- CTE dataatual: Obtém a data e hora atuais.
dataatual as (
    select
        to_char(current_timestamp, 'DD/MM/YYYY HH24:MI:SS')  -- Converte a data e hora atuais para o formato desejado.
),

-- CTE totais: Calcula somas dos votos das chapas 1 e 2, votos em branco, votos nulos e total de votos válidos.
totais as (
    select
        sum(chapa1) as tc1,
        sum(chapa2) as tc2,
        sum(branco) as tbranco,
        sum(nulo) as tnulo,
        sum (chapa1 + chapa2) as total_validos
    from
        voto_uf
)
  
-- Consulta principal: Combina as informações obtidas nas CTEs e realiza cálculos adicionais.
select
    voto_uf.estado,
    voto_uf.aptos,
    coalesce(
        (nullif (voto_uf.total, 0) / voto_uf.aptos :: float) * 100,
        0
    ) as percentage,
    coalesce(
        (nullif (totais.tc1, 0) / total_votos :: float) * 100,
        0
    ) as percentagetc1,
    coalesce(
        (nullif (totais.tc2, 0) / total_votos :: float) * 100,
        0
    ) as percentagetc2,
    coalesce(
        (nullif (totais.tbranco, 0) / total_votos :: float) * 100,
        0
    ) as percenttb,
    coalesce(
        (nullif (totais.tnulo, 0) / total_votos :: float) * 100,
        0
    ) as percenttn,
    coalesce(
        (nullif (totais.tc1, 0) / totais.total_validos :: float) * 100,
        0
    ) as percentvaltc1,
    coalesce(
        (nullif (totais.tc2, 0) / totais.total_validos :: float) * 100,
        0
    ) as percentvaltc2,
    voto_uf.chapa1,
    voto_uf.chapa2,
    voto_uf.branco,
    voto_uf.nulo,
    data_inicio_fim.*,
    total_aptos.*,
    total_votos.*,
    (total_votos.total_votos / total_aptos.total_aptos :: float) * 100 as percentual_participacao,
    dataatual,
    totais.tc1,
    totais.tc2,
    totais.tbranco,
    totais.tnulo,
    totais.total_validos
from
    voto_uf,
    data_inicio_fim,
    total_aptos,
    total_votos,
    dataatual,
    totais;
