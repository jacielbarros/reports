SELECT i1.regional::jsonb->>'name' as diretorio, UPPER(i2.nome) AS candidato, i2.cargo_nome, i2.cargo_ordem,
(i2.documentos::jsonb->0)->>'url' AS foto,
(i2.documentos::jsonb->2)->>'url' AS curriculo
FROM inscricao i1
INNER JOIN inscrito i2 ON i1.id = i2.inscricaoid
group by i1.id,i2.nome, i2.cargo_nome, i2.cargo_ordem, foto, curriculo, diretorio 
order by i1.id, i2.cargo_ordem 
