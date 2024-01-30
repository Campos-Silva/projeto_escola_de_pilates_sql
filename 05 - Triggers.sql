-- Triggers

-- 1) Trigger para inserção de dados em uma tabela de log ao ser inserido um novo dados na TB_AGENDAMENTOS.

SELECT * FROM TB_AGENDAMENTOS;

-- Criando uma tabela de LOG as triggers:
CREATE TABLE TB_LOGS(
	LOG_DATA TIMESTAMP NOT NULL,
    EVENTO VARCHAR(100) NOT NULL,
    DETALHES VARCHAR(300) NOT NULL,
    USUARIO VARCHAR(100) NOT NULL
);

DELIMITER //
CREATE TRIGGER TG_LOG_INSERT_EM_AGENDAMENTOS
	AFTER INSERT ON TB_AGENDAMENTOS 
		FOR EACH ROW
BEGIN
		INSERT INTO TB_LOGS(LOG_DATA, EVENTO, DETALHES, USUARIO)
        VALUES(CURRENT_TIMESTAMP(),
			   'Inserção em agendamentos',
				CONCAT(
						'A agenda para o cliente ',
						(SELECT NOME FROM TB_CLIENTES WHERE ID_CLIENTE = NEW.ID_CLIENTE),
						' foi criada com sucesso para a aula de ',
                        (SELECT AU.NOME_AULA FROM TB_AULAS AU INNER JOIN TB_AGENDA AG ON AU.ID_AULA = AG.ID_AULA WHERE AG.ID_AGENDA = NEW.ID_AGENDA), ' no dia da semana ',

						(SELECT DIA_SEMANA FROM TB_AGENDA WHERE ID_AGENDA = NEW.ID_AGENDA), ' as ',
						(SELECT HORA_INICIO FROM TB_AGENDA WHERE ID_AGENDA = NEW.ID_AGENDA)),
				USER());
END//

-- Fazendo experimentos:

INSERT INTO TB_AGENDAMENTOS(ID_CLIENTE, ID_AGENDA) VALUES (29, 3);

SELECT * FROM TB_AGENDAMENTOS;

SELECT * FROM TB_LOGS;



-- --------------------------------------------------------------------------------------------------------------



-- 2) Trigger para inserção de dados em uma tabela de log ao ser atualizado a tabela TB_AGENDAMENTOS.

DELIMITER //
CREATE TRIGGER TG_ATUALIZACAO_DE_AGENDAMENTO AFTER UPDATE ON TB_AGENDAMENTOS
FOR EACH ROW
BEGIN
	IF OLD.ID_AGENDA <> NEW.ID_AGENDA THEN
		INSERT INTO TB_LOGS(LOG_DATA, EVENTO, DETALHES, USUARIO) VALUES(
			CURRENT_TIMESTAMP(),
            'Atualização em agendamentos',
            CONCAT('A agenda do cliente ', 
				  (SELECT CONCAT(NOME, ' ', SOBRENOME) FROM TB_CLIENTES WHERE ID_CLIENTE = NEW.ID_CLIENTE), 
                  ' foi alterada de ',
                  (SELECT AU.NOME_AULA FROM TB_AULAS AU INNER JOIN TB_AGENDA AG ON AU.ID_AULA = AG.ID_AULA WHERE AG.ID_AGENDA = OLD.ID_AGENDA), ' no dia da semana ',
                  (SELECT DIA_SEMANA FROM TB_AGENDA WHERE ID_AGENDA = OLD.ID_AGENDA), ' as ',
                  (SELECT HORA_INICIO FROM TB_AGENDA WHERE ID_AGENDA = OLD.ID_AGENDA), ' para ', 
                  (SELECT AU.NOME_AULA FROM TB_AULAS AU INNER JOIN TB_AGENDA AG ON AU.ID_AULA = AG.ID_AULA WHERE AG.ID_AGENDA = NEW.ID_AGENDA), ' no dia da semana ',
                  (SELECT DIA_SEMANA FROM TB_AGENDA WHERE ID_AGENDA = NEW.ID_AGENDA), ' as ',
                  (SELECT HORA_INICIO FROM TB_AGENDA WHERE ID_AGENDA = NEW.ID_AGENDA)),
			USER());
	END IF;
END//

SELECT * FROM TB_AGENDAMENTOS;

UPDATE TB_AGENDAMENTOS SET ID_AGENDA = 15 WHERE ID_AGENDAMENTO = 25;

SELECT * FROM TB_LOGS;


-- --------------------------------------------------------------------------------------------------------------


-- 3) Trigger para diminuir a quantidade de produtos de um dado ID_PRODUTO quando houver uma nova venda em TB_VENDAS_PRODUTOS.


-- Criando uma stored procedure para realizar a subtração da quantidade de estoque de um dado produto em TB_VENDAS_PRODUTOS.
DELIMITER //

	CREATE PROCEDURE SP_ATUALIZACAO_ESTOQUE_PRODUTO(
													P_ID_VENDA BIGINT,
                                                    P_PRODUTO BIGINT)                                         
         BEGIN
         
         DECLARE V_QUANTIDADE BIGINT;
         
         
		 SELECT QUANTIDADE INTO V_QUANTIDADE FROM TB_VENDAS_PRODUTOS WHERE ID_VENDA = P_ID_VENDA AND ID_PRODUTO = P_PRODUTO;
         
			IF V_QUANTIDADE > 0 THEN
            
				UPDATE TB_PRODUTOS SET QUANTIDADE_DISPONIVEL = (QUANTIDADE_DISPONIVEL - V_QUANTIDADE) WHERE ID_PRODUTO = P_PRODUTO;
                
                END IF;
           
         END //
		

-- Testando a stored procedure:  
CALL SP_ATUALIZACAO_ESTOQUE_PRODUTO (1, 4);

-- Validando o resultado:
SELECT * FROM TB_PRODUTOS;

 SELECT * FROM TB_VENDAS_PRODUTOS;
 
-- Criando uma trigger para subtrair automaticamente a quantidade de produtos em TB_PRODUTOS assim que houver uma venda nova:
DELIMITER //

	CREATE TRIGGER TG_ATUALIZACAO_ESTOQUE_PRODUTO
    
    AFTER INSERT ON TB_VENDAS_PRODUTOS
    
    		FOR EACH ROW
BEGIN
		CALL SP_ATUALIZACAO_ESTOQUE_PRODUTO(
											NEW.ID_VENDA,
                                            NEW.ID_PRODUTO);
END//



-- Inserindo uma nova venda:
INSERT INTO TB_VENDAS(
							ID_CLIENTE,
                            DATA_VENDA,
                            VALOR,
                            ID_FORMA_PAGAMENTO)
								VALUES (1,
										CURDATE(),
										18.80,
                                        1);


INSERT INTO TB_VENDAS_PRODUTOS(
							ID_PRODUTO,
                            ID_VENDA,
                            QUANTIDADE,
                            VALOR_DA_VENDA)
								VALUES (1, 29, 1, 6.90),
									   (4, 29, 1, 11.90);
                                        
-- Validando o resultado:
SELECT * FROM TB_VENDAS;
              
SELECT * FROM TB_PRODUTOS;

SELECT * FROM TB_VENDAS_PRODUTOS;

-- --------------------------------------------------------------------------------------------------------------

-- 4) Criando a trigger que altera o status do contrato com pagamentos de status 12 pela rotina de atraso>5d para 'COM PENDENCIAS', chama a procedure que deleta os agendamentos e grava as LOGs do processo na TB_LOGS
DELIMITER //
CREATE TRIGGER TG_ALTERACAO_ST_PGMTO_PELA_ROTINA_AUTOMATICA AFTER UPDATE ON TB_REGISTRO_INDIVIDUAL_DE_PAGAMENTO_DO_PLANO
FOR EACH ROW

BEGIN

	DECLARE V_NOME VARCHAR(100) DEFAULT '';
    DECLARE V_DESCRICAO_OLD VARCHAR(100) DEFAULT '';
    DECLARE V_DESCRICAO_NEW VARCHAR(100) DEFAULT '';
    
    SELECT CONCAT(C.NOME, ' ', C.SOBRENOME) INTO V_NOME
    FROM TB_CLIENTES C 
    INNER JOIN TB_CONTRATOS_PLANOS CP ON CP.ID_CLIENTE = C.ID_CLIENTE
	WHERE CP.ID_CONTRATO = NEW.ID_CONTRATO_DO_PLANO;

	SELECT ST.DESCRICAO INTO V_DESCRICAO_OLD
    FROM TB_STATUS_DO_PAGAMENTO ST 
    WHERE ST.ID_STATUS = OLD.ID_DO_STATUS;
    
    SELECT ST.DESCRICAO INTO V_DESCRICAO_NEW
    FROM TB_STATUS_DO_PAGAMENTO ST 
    WHERE ST.ID_STATUS = NEW.ID_DO_STATUS;
    
    
	IF OLD.ID_DO_STATUS <> 12 AND NEW.ID_DO_STATUS = 12 THEN
		 INSERT INTO TB_LOGS(LOG_DATA, EVENTO, DETALHES, USUARIO)
		 VALUES (
            CURRENT_TIMESTAMP(),
			'Alteração de status do pagamento',
				CONCAT('O status do pagamento do cliente ', 
						V_NOME, 
						' do ID de pagamento ',
						NEW.ID_DO_PAGAMENTO,
						' foi alterado de ',
						V_DESCRICAO_OLD,
						' para ',
						V_DESCRICAO_NEW),
						USER());
                        
		UPDATE TB_CONTRATOS_PLANOS CP SET STATUS_ASSOCIACAO = 'COM PENDENCIAS' WHERE CP.ID_CONTRATO = NEW.ID_CONTRATO_DO_PLANO;
        		
		INSERT INTO TB_LOGS(LOG_DATA, EVENTO, DETALHES, USUARIO)
		VALUES (
			CURRENT_TIMESTAMP(),
			'Inativação do contrato',
				CONCAT('O status do contrato do cliente ', 
						V_NOME, 
						' do ID de pagamento ',
						NEW.ID_DO_PAGAMENTO,
						' foi alterado de ATIVO para COM PENDENCIAS e os agendamentos do cliente foram excluídos'),
                        USER());
                        
		CALL SP_ROTINA_INATIVACAO_CONTRATOS2_AGENDAMENTOS(NEW.ID_CONTRATO_DO_PLANO);

	END IF;
END//

-- TESTES

CALL SP_ROTINA_INATIVACAO_CONTRATOS();

SELECT * FROM TB_VENDAS_PRODUTOS;
