-- Criar array agrupado 
-- Importar chapas apartir de tabela temporária
-- Usar para importar tabela chapa - eleicaonet
SELECT 
c.codigo as diretorio,
c."Nome da Chapa",
json_agg(
    json_build_object(
        'index',c.ordem,
        'nome',c."Nome do candidato",
        'cargo',c.cargo,
        'foto','https://eleicaonet-public.s3.sa-east-1.amazonaws.com/sbc/chapas/658794f654c906bd0988af7533348838.png'
)) as participantes,
ROW_NUMBER() OVER (PARTITION BY c.codigo) as ordem, --FALTA USAR A ORDEM AQUI, PORQUE PODE NÃO BATER
ROW_NUMBER() OVER (PARTITION BY c.codigo) as numero
into conferir_tratada
from conferir c
group by c.codigo, c."Nome da Chapa"
