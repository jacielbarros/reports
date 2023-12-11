-- CTE para calcular votos por chapa para o Conselho Fiscal de ATIVOS
with conselho_fiscal_ativos as (
    select
        1 as ordem,
        idchapa,
        c.nome as ativos_chapa_nome,
        c.participantes :: jsonb -> 0 ->> 'nome' as ativos_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as ativos_titular_cargo,
        c.participantes :: jsonb -> 1 ->> 'nome' as ativos_suplente_nome,
        c.participantes :: jsonb -> 1 ->> 'cargo' as ativos_suplente_cargo,
        count(v.id) as ativos_total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
        inner join votoapurado v2 on v2.id = v.idvoto
    where
        v2.eleicao = 0 -- Eleição para ATIVOS
        and c.diretorio = 0 -- Conselho Fiscal
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome,
        ativos_titular_nome,
        ativos_titular_cargo,
        ativos_suplente_nome,
        ativos_suplente_cargo
    order by
        ativos_total desc
    limit
        1
),
-- CTE para calcular votos por chapa para o Conselho Fiscal de ASSISTIDOS
conselho_fiscal_assistidos as (
    select
        1 as ordem,
        idchapa,
        c.nome as assistidos_chapa_nome,
        c.participantes :: jsonb -> 0 ->> 'nome' as assistidos_titular_nome,
        c.participantes :: jsonb -> 0 ->> 'cargo' as assistidos_titular_cargo,
        c.participantes :: jsonb -> 1 ->> 'nome' as assistidos_suplente_nome,
        c.participantes :: jsonb -> 1 ->> 'cargo' as assistidos_suplente_cargo,
        count(v.id) as assistidos_total
    from
        votoapuradoporchapa v
        inner join chapa c on c.id = v.idchapa
        inner join votoapurado v2 on v2.id = v.idvoto
    where
        v2.eleicao = 1 -- Eleição para ASSISTIDOS
        and c.diretorio = 1 -- Conselho Fiscal
        and c.numero not in (0, 99)
    group by
        v.idchapa,
        c.nome,
        assistidos_titular_nome,
        assistidos_titular_cargo,
        assistidos_suplente_nome,
        assistidos_suplente_cargo
    order by
        assistidos_total desc
    limit
        1
)
-- Seleção final combinando os resultados das CTEs
select
    cfa.ativos_chapa_nome,
    cfa.ativos_titular_nome,
    cfa.ativos_titular_cargo,
    cfa.ativos_suplente_nome,
    cfa.ativos_suplente_cargo,
    cfa.ativos_total,
    cfas.assistidos_chapa_nome,
    cfas.assistidos_titular_nome,
    cfas.assistidos_titular_cargo,
    cfas.assistidos_suplente_nome,
    cfas.assistidos_suplente_cargo,
    cfas.assistidos_total
from
    conselho_fiscal_ativos cfa,
    conselho_fiscal_assistidos cfas;
