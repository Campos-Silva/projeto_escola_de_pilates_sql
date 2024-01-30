-- TOP 5 PRODUTOS COMPRADOS NOS ÚLTIMOS 3 MESES - DESCRICAO, VALOR


CREATE OR REPLACE VIEW VW_TOP_5_PRODUTOS_VENDIDOS AS
    SELECT 
		P.NOME AS 'DESCRIÇÃO',
        SUM(V.QUANTIDADE) AS `QUANTIDADE`,
        SUM(V.VALOR_DA_VENDA) AS `VALOR TOTAL(R$)`
    FROM
        TB_VENDAS_PRODUTOS V
            INNER JOIN
        TB_PRODUTOS  P USING (ID_PRODUTO)
			INNER JOIN TB_VENDAS V_2 USING (ID_VENDA)
	WHERE V_2.DATA_VENDA >= DATE_SUB(CURDATE(),INTERVAL 3 MONTH)
	GROUP BY P.NOME
    ORDER BY `QUANTIDADE` DESC, `VALOR TOTAL(R$)` DESC
    LIMIT 5;
    
SELECT * FROM VW_TOP_5_PRODUTOS_VENDIDOS;


-- CRIANDO RELATÓRIO TOP 5 FATURAMENTO POR CLIENTES DOS ÚLTIMOS 3 MESES

SELECT CONCAT(C.NOME, ' ', C.SOBRENOME) AS 'NOME DO CLIENTE',
        TIMESTAMPDIFF(YEAR, C.DATA_NASCIMENTO, CURDATE()) AS 'IDADE',
        C.GENERO,
        CC.BAIRRO,
        DP.DESCRICAO_PLANO,
        SUM(V.VALOR + RP.VALOR_PAGO) AS `VALOR GASTO`
        FROM TB_VENDAS V 
		INNER JOIN TB_CONTRATOS_PLANOS CP ON V.ID_CLIENTE = CP.ID_CLIENTE 
        INNER JOIN TB_REGISTRO_INDIVIDUAL_DE_PAGAMENTO_DO_PLANO RP ON CP.ID_CONTRATO = RP.ID_CONTRATO_DO_PLANO
        INNER JOIN TB_CLIENTES C ON V.ID_CLIENTE = C.ID_CLIENTE
        INNER JOIN TB_CONTATO_CLIENTE CC ON C.ID_CLIENTE = CC.ID_CLIENTE
        INNER JOIN (SELECT ID_PLANO, DESCRICAO_PLANO FROM TB_CONTRATOS_PLANOS INNER JOIN TB_TIPOS_DE_PLANOS USING (ID_PLANO)) DP ON DP.ID_PLANO = CP.ID_PLANO
	GROUP BY C.ID_CLIENTE, CC.BAIRRO, DP.DESCRICAO_PLANO
    ORDER BY `VALOR GASTO` DESC LIMIT 5;


CREATE OR REPLACE VIEW VW_TOP_5_CONSUMIDORES AS 
SELECT CONCAT(C.NOME, ' ', C.SOBRENOME) AS 'NOME DO CLIENTE',
        TIMESTAMPDIFF(YEAR, C.DATA_NASCIMENTO, CURDATE()) AS 'IDADE',
        C.GENERO,
        CC.BAIRRO,
        DP.DESCRICAO_PLANO,
        SUM(V.VALOR + RP.VALOR_PAGO) AS `VALOR GASTO`
        FROM TB_VENDAS V 
		INNER JOIN TB_CONTRATOS_PLANOS CP ON V.ID_CLIENTE = CP.ID_CLIENTE 
        INNER JOIN TB_REGISTRO_INDIVIDUAL_DE_PAGAMENTO_DO_PLANO RP ON CP.ID_CONTRATO = RP.ID_CONTRATO_DO_PLANO
        INNER JOIN TB_CLIENTES C ON V.ID_CLIENTE = C.ID_CLIENTE
        INNER JOIN TB_CONTATO_CLIENTE CC ON C.ID_CLIENTE = CC.ID_CLIENTE
        INNER JOIN (SELECT ID_PLANO, DESCRICAO_PLANO FROM TB_CONTRATOS_PLANOS INNER JOIN TB_TIPOS_DE_PLANOS USING (ID_PLANO)) DP ON DP.ID_PLANO = CP.ID_PLANO
	GROUP BY C.ID_CLIENTE, CC.BAIRRO, DP.DESCRICAO_PLANO
    ORDER BY `VALOR GASTO` DESC LIMIT 5;
;
    
SELECT * FROM VW_TOP_5_CONSUMIDORES;

-- ANÁLISE DE DEMANDA DAS AULAS - QTD DE AGENDAMENTOS POR AULA - DESCRICAO, QTD AGENDAMENTOS, INSTRUTOR

CREATE OR REPLACE VIEW VW_QTD_AGENDAMENTOS_POR_AULA AS
	SELECT
        AU.NOME_AULA AS `AULA`, -- TB_AULAS
        CONCAT(NA.NOME,' ',NA.SOBRENOME) AS `INSTRUTOR`, -- TB_INSTRUTORES
        COUNT(AG.ID_AGENDAMENTO) AS `QTD_AGENDAMENTOS`-- TB_AGENDAMENTOS
	FROM
		TB_AGENDAMENTOS AG
	INNER JOIN
		(SELECT ID_AGENDA, NOME_AULA FROM TB_AULAS INNER JOIN TB_AGENDA USING (ID_AULA)) AU USING (ID_AGENDA)
	INNER JOIN
		(SELECT T1.ID_AGENDA, T2.NOME, T2.SOBRENOME FROM TB_AULAS_INSTRUTORES 
        INNER JOIN TB_AGENDA T1 USING (ID_AULA)
        INNER JOIN TB_INSTRUTORES T2 USING (ID_INSTRUTOR)) NA ON NA.ID_AGENDA = AG.ID_AGENDA
	GROUP BY AULA, NOME, SOBRENOME
    ORDER BY QTD_AGENDAMENTOS DESC;
        
SELECT * FROM VW_QTD_AGENDAMENTOS_POR_AULA;

-- RELATÓRIO DA ANÁLISE DO PERFIL DOS CLIENTES CONFORME OBJETIVOS
SELECT OBJETIVOS_CLIENTE AS 'OBJETIVO DO CLIENTE',
	COUNT(ID_CLIENTE) AS `QUANTIDADE`,
    ROUND(AVG((PERCENTUAL_GORDURA)*100),2) AS 'MÉDIA DE % DE GORDURA'
	FROM TB_AVALIACAO_FISICA
	GROUP BY OBJETIVOS_CLIENTE
    ORDER BY `QUANTIDADE` DESC;

CREATE OR REPLACE VIEW VW_QTD_DE_OBJETIVO AS
SELECT OBJETIVOS_CLIENTE AS 'OBJETIVO DO CLIENTE',
	COUNT(ID_CLIENTE) AS `QUANTIDADE`,
    ROUND(AVG((PERCENTUAL_GORDURA)*100),2) AS 'MÉDIA DE % DE GORDURA'
	FROM TB_AVALIACAO_FISICA
	GROUP BY OBJETIVOS_CLIENTE
    ORDER BY `QUANTIDADE` DESC;
    
 SELECT * FROM VW_QTD_DE_OBJETIVO;    


-- ANÁLISE DE OCUPAÇÃO DAS AULAS - % DE FREQUÊNCIA NA AULA NAS ULTIMAS 4 SEMANAS - DESCRICAO, % OCUPAÇÃO
SELECT * FROM TB_AGENDAMENTOS;
SELECT * FROM TB_AGENDA;
SELECT * FROM TB_REGISTRO_DE_FREQUENCIA_NAS_AULAS;
SELECT * FROM TB_AULAS;

-- DIVIDENDO
SELECT
	COUNT(AG.ID_AGENDAMENTO),
    AU.NOME_AULA
FROM TB_REGISTRO_DE_FREQUENCIA_NAS_AULAS
INNER JOIN TB_AGENDAMENTOS AG USING (ID_AGENDAMENTO)
INNER JOIN TB_AGENDA A ON A.ID_AGENDA = AG.ID_AGENDA
INNER JOIN TB_AULAS AU ON AU.ID_AULA = A.ID_AULA
WHERE DATA_PARTICIPACAO >= DATE_SUB(CURDATE(),INTERVAL 1 WEEK)
GROUP BY AU.NOME_AULA;

-- DIVISOR
SELECT
	AU.NOME_AULA AS AULA,
	((AU.CAPACIDADE_ALUNO)*(COUNT(AG.ID_AGENDA))) AS `TOTAL`
FROM TB_AGENDA AG
INNER JOIN TB_AULAS AU USING (ID_AULA)
GROUP BY AU.NOME_AULA, AU.CAPACIDADE_ALUNO;

-- DIVIDENDO/DIVISOR

SELECT
	AU.NOME_AULA,
	100*ROUND(COUNT(AG.ID_AGENDAMENTO) / ((AU.CAPACIDADE_ALUNO)*4*(COUNT(AG.ID_AGENDA))),2) AS `% OCUPAÇÃO DAS ÚLTIMAS 4 SEMANAS`
FROM TB_REGISTRO_DE_FREQUENCIA_NAS_AULAS
INNER JOIN TB_AGENDAMENTOS AG USING (ID_AGENDAMENTO)
INNER JOIN TB_AGENDA A ON A.ID_AGENDA = AG.ID_AGENDA
INNER JOIN TB_AULAS AU ON AU.ID_AULA = A.ID_AULA
WHERE DATA_PARTICIPACAO >= DATE_SUB(CURDATE(),INTERVAL 4 WEEK)
GROUP BY AU.NOME_AULA, AU.CAPACIDADE_ALUNO;

-- VIEW
CREATE OR REPLACE VIEW VW_OCUPACAO_AULAS_4W AS
	SELECT
		AU.NOME_AULA AS 'NOME DA AULA',
		100*ROUND(COUNT(AG.ID_AGENDAMENTO) / ((AU.CAPACIDADE_ALUNO)*4*(COUNT(AG.ID_AGENDA))),2) AS `% OCUPAÇÃO DAS ÚLTIMAS 4 SEMANAS`
	FROM TB_REGISTRO_DE_FREQUENCIA_NAS_AULAS
	INNER JOIN TB_AGENDAMENTOS AG USING (ID_AGENDAMENTO)
	INNER JOIN TB_AGENDA A ON A.ID_AGENDA = AG.ID_AGENDA
	INNER JOIN TB_AULAS AU ON AU.ID_AULA = A.ID_AULA
	WHERE DATA_PARTICIPACAO >= DATE_SUB(CURDATE(),INTERVAL 4 WEEK)
	GROUP BY AU.NOME_AULA, AU.CAPACIDADE_ALUNO;
    
SELECT * FROM VW_OCUPACAO_AULAS_4W;
