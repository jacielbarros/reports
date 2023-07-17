with voto_uf as (
    select
        uf.uf as estado,
        count(split_part(e.infoeleitor, ',', 2)) as aptos,
        (
            select
                count(*)
            from
                voto
            where
                split_part(voto.infoeleitor, ',', 2) = uf.uf
        ) as total,
        (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000001')
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as chapa1,
                (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000002')
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as chapa2,

                (
            select
                count(*)
            from
                votoapurado
            where
                (substring(voto, 1, 6) = '000000')
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as branco,
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
                )
                and split_part(votoapurado.infoeleitor, ',', 2) = uf.uf
        ) as nulo
    from
        uf
        left join eleitor e on uf.uf = split_part(infoeleitor, ',', 2)
        and e.temimpedimento = false
    group by
        uf.uf
    order by
        uf.uf
),
data_inicio_fim as (
    select
        TO_CHAR(dataInicioEleicao, 'DD/MM/YYYY HH24:MI:SS') as inicio,
        TO_CHAR(dataFimEleicao, 'DD/MM/YYYY HH24:MI:SS') as fim
    from
        parametroeleicaonet
),
total_aptos as (
    select
        count(*) as total_aptos
    from
        eleitor
    where
        temimpedimento = false
),
total_votos as (
    select
        count(*) as total_votos
    from
        eleitor
    where
        votou = true
),

dataatual as (
    select
        to_char(current_timestamp, 'DD/MM/YYYY HH24:MI:SS')
),
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
    ) as percentagetc2
    ,
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
    (
        total_votos.total_votos / total_aptos.total_aptos :: float
    ) * 100 as percentual_participacao,
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
