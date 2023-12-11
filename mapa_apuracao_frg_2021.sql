with duplas as (
    select
        1 as ordem,
        v2.eleicao,
        idchapa,
        c.nome,
        count(v.id) filter (
            where
                v2.eleicao = 0
        ) as assistido,
        count(v.id) filter (
            where
                v2.eleicao = 1
        ) as participante,
        count(v.id) as total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
        inner join votoapurado v2 on v2.id = v.idvoto
    where
        c.diretorio = 0
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome,
        v2.eleicao
),
duplas2 as (
    select
        1 as ordem,
        idchapa,
        c.nome,
        count(v.id) filter (
            where
                v2.eleicao = 0
        ) as assistido,
        count(v.id) filter (
            where
                v2.eleicao = 1
        ) as participante,
        count(v.id) as total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
        inner join votoapurado v2 on v2.id = v.idvoto
    where
        c.diretorio = 0
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome
),
seguridade as (
    select
        1 as ordem,
        idchapa,
        c.nome,
        count(v.id) as total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
    where
        c.diretorio = 2
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome
    order by
        total desc
    limit
        1
), ouvidoria as (
    select
        1 as ordem,
        idchapa,
        c.nome,
        count(v.id) as total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
    where
        c.diretorio = 1
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome
    order by
        total desc
    limit
        1
), dupla_mais_votada_participante as (
    select
        duplas.idchapa as participante_idchapa,
        duplas.nome as participante_chapa,
        c.participantes :: jsonb -> 0 ->> 'nome' as participante_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as participante_titular_cargo,
        c.participantes :: jsonb -> 1 ->> 'nome' as participante_suplente_nome,
        c.participantes :: jsonb -> 1 ->> 'cargo' as participante_suplente_cargo,
        duplas.participante as participante_quantidade
    from
        duplas
        inner join chapa c on c.id = duplas.idchapa
    where
        duplas.eleicao = 1
    order by
        participante desc
    limit
        1
), dupla_mais_votada_assistidos as (
    select
        duplas.idchapa as assistido_idchapa,
        duplas.nome as assistido_chapa,
        c.participantes :: jsonb -> 0 ->> 'nome' as assistido_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as assistido_titular_cargo,
        c.participantes :: jsonb -> 1 ->> 'nome' as assistido_suplente_nome,
        c.participantes :: jsonb -> 1 ->> 'cargo' as assistido_suplente_cargo,
        duplas.assistido as assistido_quantidade
    from
        duplas
        inner join chapa c on c.id = duplas.idchapa
    where
        duplas.eleicao = 0
    order by
        assistido desc
    limit
        1
), dupla_mais_votada as (
    select
        duplas.idchapa as dupla_idchapa,
        duplas.nome as dupla_chapa,
        c.participantes :: jsonb -> 0 ->> 'nome' as dupla_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as dupla_titular_cargo,
        c.participantes :: jsonb -> 1 ->> 'nome' as dupla_suplente_nome,
        c.participantes :: jsonb -> 1 ->> 'cargo' as dupla_suplente_cargo,
        duplas.total as dupla_quantidade
    from
        duplas2 as duplas
        inner join chapa c on c.id = duplas.idchapa
    where
        duplas.idchapa <> (
            select
                participante_idchapa
            from
                dupla_mais_votada_participante
        )
        and duplas.idchapa <> (
            select
                assistido_idchapa
            from
                dupla_mais_votada_assistidos
        )
    order by
        total desc
    limit
        1
), seguridade_mais_votado as (
    select
        duplas.idchapa as seguridade_idchapa,
        duplas.nome as seguridade_chapa,
        c.participantes :: jsonb -> 0 ->> 'nome' as seguridade_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as seguridade_titular_cargo,
        duplas.total as seguridade_quantidade
    from
        seguridade as duplas
        inner join chapa c on c.id = duplas.idchapa
),
ouvidoria_mais_votado as (
    select
        duplas.idchapa as ouvidoria_idchapa,
        duplas.nome as ouvidoria_chapa,
        c.participantes :: jsonb -> 0 ->> 'nome' as ouvidoria_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as ouvidoria_titular_cargo,
        duplas.total as ouvidoria_quantidade
    from
        ouvidoria as duplas
        inner join chapa c on c.id = duplas.idchapa
)
select
    dmvp.*,
    dmva.*,
    dmv.*,
    smv.*,
    omv.*
from
    dupla_mais_votada_participante dmvp,
    dupla_mais_votada_assistidos dmva,
    dupla_mais_votada dmv,
    seguridade_mais_votado smv,
    ouvidoria_mais_votado omv;