/* ============================================================================
   ROTA86 — Tabelas de referência (domínio/pesos), com carga inicial
   Fonte: dicts hardcoded em lojas_perfeitas/src/{kbd_ps,sos,pe,cko}.py,
   validados contra o fechamento oficial de julho/2026. Ver
   MIGRACAO_BANCO/06_MOTOR_LOJAS_PERFEITAS_E_MOP.md seção 2.3.
   vigente_de/vigente_ate permitem versionar uma mudança de peso sem perder
   o valor histórico (nunca UPDATE destrutivo em linha vigente: fechar a
   antiga com vigente_ate e inserir a nova).
   ============================================================================ */

/* ---------------------------------------------------------------------------
   ref_peso_kbd_canal_plataforma — SCORE_PS_OBJETIVO fixo por (canal, plataforma)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.ref_peso_kbd_canal_plataforma', 'U') IS NOT NULL DROP TABLE rota86.ref_peso_kbd_canal_plataforma;
CREATE TABLE rota86.ref_peso_kbd_canal_plataforma (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    canal           VARCHAR(30)     NOT NULL,
    plataforma      VARCHAR(30)     NOT NULL,
    peso_objetivo   DECIMAL(9,2)    NOT NULL,
    vigente_de      DATE            NOT NULL DEFAULT '2026-07-01',
    vigente_ate     DATE            NULL,
    CONSTRAINT uq_ref_peso_kbd UNIQUE (canal, plataforma, vigente_de)
);
INSERT INTO rota86.ref_peso_kbd_canal_plataforma (canal, plataforma, peso_objetivo) VALUES
    ('DPP',        'LEGO',            38.0),
    ('C&C',        'LEGO',            36.0),
    ('C&C',        'STORE PLATFORM',  36.0),
    ('C&C',        'SEM PLATAFORMA',  36.0),
    ('DPP',        'STORE PLATFORM',  36.0),
    ('NMR',        'LEGO',            36.0),
    ('NMR',        'STORE PLATFORM',  36.0),
    ('NMR',        'SEM PLATAFORMA',  36.0),
    ('GMR',        'LEGO',            36.0),
    ('CLUB',       'LEGO',            25.0),
    ('HFS',        'STORE PLATFORM',  24.0),
    ('LASA',       'LEGO',            26.0),
    ('PERFUMARIA', 'STORE PLATFORM',  37.0);
GO

/* ---------------------------------------------------------------------------
   ref_peso_sos_marca — peso por marca/categoria dentro de (canal, plataforma).
   A soma dos pesos de um grupo = SCORE_SOS_OBJETIVO daquele grupo.
   categoria = tradução MARCA_PARA_CATEGORIA (nome usado em stg_f_sos.categoria)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.ref_peso_sos_marca', 'U') IS NOT NULL DROP TABLE rota86.ref_peso_sos_marca;
CREATE TABLE rota86.ref_peso_sos_marca (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    canal           VARCHAR(30)     NOT NULL,
    plataforma      VARCHAR(30)     NOT NULL,
    marca           VARCHAR(30)     NOT NULL,
    categoria       VARCHAR(30)     NOT NULL,   -- valor esperado em stg_f_sos.categoria
    peso            DECIMAL(9,2)    NOT NULL,
    vigente_de      DATE            NOT NULL DEFAULT '2026-07-01',
    vigente_ate     DATE            NULL,
    CONSTRAINT uq_ref_peso_sos UNIQUE (canal, plataforma, marca, vigente_de)
);
INSERT INTO rota86.ref_peso_sos_marca (canal, plataforma, marca, categoria, peso) VALUES
    ('C&C','LEGO','Downy','Amaciantes',9.0), ('C&C','LEGO','Gillette','Laminas Masc',4.0),
    ('C&C','LEGO','Pampers','Fraldas',3.5), ('C&C','LEGO','Venus','Laminas Fem',2.0),
    ('C&C','LEGO','Escovas','Escovas',3.0), ('C&C','LEGO','Cremes','Cremes dentais',3.0),
    ('C&C','LEGO','Cabelos','Cabelos',3.0), ('C&C','LEGO','Always','Absorventes',2.5),
    ('C&C','LEGO','Old Spice','Desodorantes',2.0), ('C&C','LEGO','Secret','Desodorantes Fem',2.0),

    ('DPP','LEGO','Downy','Amaciantes',0.0), ('DPP','LEGO','Gillette','Laminas Masc',3.5),
    ('DPP','LEGO','Pampers','Fraldas',9.0), ('DPP','LEGO','Venus','Laminas Fem',2.0),
    ('DPP','LEGO','Escovas','Escovas',2.5), ('DPP','LEGO','Cremes','Cremes dentais',2.5),
    ('DPP','LEGO','Cabelos','Cabelos',3.5), ('DPP','LEGO','Always','Absorventes',3.0),
    ('DPP','LEGO','Old Spice','Desodorantes',1.5), ('DPP','LEGO','Secret','Desodorantes Fem',1.5),

    ('NMR','LEGO','Downy','Amaciantes',9.0), ('NMR','LEGO','Gillette','Laminas Masc',4.5),
    ('NMR','LEGO','Pampers','Fraldas',5.0), ('NMR','LEGO','Venus','Laminas Fem',2.0),
    ('NMR','LEGO','Escovas','Escovas',3.5), ('NMR','LEGO','Cremes','Cremes dentais',3.0),
    ('NMR','LEGO','Cabelos','Cabelos',4.0), ('NMR','LEGO','Always','Absorventes',2.0),
    ('NMR','LEGO','Old Spice','Desodorantes',1.5), ('NMR','LEGO','Secret','Desodorantes Fem',1.5),

    ('GMR','LEGO','Downy','Amaciantes',9.0), ('GMR','LEGO','Gillette','Laminas Masc',4.5),
    ('GMR','LEGO','Pampers','Fraldas',5.0), ('GMR','LEGO','Venus','Laminas Fem',2.0),
    ('GMR','LEGO','Escovas','Escovas',3.5), ('GMR','LEGO','Cremes','Cremes dentais',3.0),
    ('GMR','LEGO','Cabelos','Cabelos',4.0), ('GMR','LEGO','Always','Absorventes',2.0),
    ('GMR','LEGO','Old Spice','Desodorantes',1.5), ('GMR','LEGO','Secret','Desodorantes Fem',1.5),

    ('CLUB','LEGO','Downy','Amaciantes',11.0), ('CLUB','LEGO','Gillette','Laminas Masc',6.0),
    ('CLUB','LEGO','Pampers','Fraldas',8.5), ('CLUB','LEGO','Venus','Laminas Fem',0.0),
    ('CLUB','LEGO','Escovas','Escovas',4.5), ('CLUB','LEGO','Cremes','Cremes dentais',4.0),
    ('CLUB','LEGO','Cabelos','Cabelos',4.0), ('CLUB','LEGO','Always','Absorventes',3.5),
    ('CLUB','LEGO','Old Spice','Desodorantes',0.0), ('CLUB','LEGO','Secret','Desodorantes Fem',0.0),

    -- LASA/Venus corrigido de 0,0 (PPT) para 2,0: fecha com o oficial (36 em 43/43 lojas). Ver README do motor.
    ('LASA','LEGO','Downy','Amaciantes',9.0), ('LASA','LEGO','Gillette','Laminas Masc',4.5),
    ('LASA','LEGO','Pampers','Fraldas',5.0), ('LASA','LEGO','Venus','Laminas Fem',2.0),
    ('LASA','LEGO','Escovas','Escovas',3.5), ('LASA','LEGO','Cremes','Cremes dentais',3.0),
    ('LASA','LEGO','Cabelos','Cabelos',4.0), ('LASA','LEGO','Always','Absorventes',2.0),
    ('LASA','LEGO','Old Spice','Desodorantes',1.5), ('LASA','LEGO','Secret','Desodorantes Fem',1.5),

    ('C&C','STORE PLATFORM','Downy','Amaciantes',9.0), ('C&C','STORE PLATFORM','Gillette','Laminas Masc',4.0),
    ('C&C','STORE PLATFORM','Pampers','Fraldas',3.5), ('C&C','STORE PLATFORM','Venus','Laminas Fem',2.0),
    ('C&C','STORE PLATFORM','Escovas','Escovas',3.0), ('C&C','STORE PLATFORM','Cremes','Cremes dentais',3.0),
    ('C&C','STORE PLATFORM','Cabelos','Cabelos',3.0), ('C&C','STORE PLATFORM','Always','Absorventes',2.5),
    ('C&C','STORE PLATFORM','Old Spice','Desodorantes',2.0), ('C&C','STORE PLATFORM','Secret','Desodorantes Fem',2.0),

    ('DPP','STORE PLATFORM','Downy','Amaciantes',0.0), ('DPP','STORE PLATFORM','Gillette','Laminas Masc',3.5),
    ('DPP','STORE PLATFORM','Pampers','Fraldas',9.0), ('DPP','STORE PLATFORM','Venus','Laminas Fem',2.0),
    ('DPP','STORE PLATFORM','Escovas','Escovas',2.5), ('DPP','STORE PLATFORM','Cremes','Cremes dentais',2.5),
    ('DPP','STORE PLATFORM','Cabelos','Cabelos',3.5), ('DPP','STORE PLATFORM','Always','Absorventes',3.0),
    ('DPP','STORE PLATFORM','Old Spice','Desodorantes',1.5), ('DPP','STORE PLATFORM','Secret','Desodorantes Fem',1.5),

    ('NMR','STORE PLATFORM','Downy','Amaciantes',9.0), ('NMR','STORE PLATFORM','Gillette','Laminas Masc',4.5),
    ('NMR','STORE PLATFORM','Pampers','Fraldas',5.0), ('NMR','STORE PLATFORM','Venus','Laminas Fem',2.0),
    ('NMR','STORE PLATFORM','Escovas','Escovas',3.5), ('NMR','STORE PLATFORM','Cremes','Cremes dentais',3.0),
    ('NMR','STORE PLATFORM','Cabelos','Cabelos',4.0), ('NMR','STORE PLATFORM','Always','Absorventes',2.0),
    ('NMR','STORE PLATFORM','Old Spice','Desodorantes',1.5), ('NMR','STORE PLATFORM','Secret','Desodorantes Fem',1.5),

    ('HFS','STORE PLATFORM','Downy','Amaciantes',9.0), ('HFS','STORE PLATFORM','Gillette','Laminas Masc',5.5),
    ('HFS','STORE PLATFORM','Pampers','Fraldas',7.0), ('HFS','STORE PLATFORM','Venus','Laminas Fem',2.5),
    ('HFS','STORE PLATFORM','Escovas','Escovas',4.5), ('HFS','STORE PLATFORM','Cremes','Cremes dentais',3.5),
    ('HFS','STORE PLATFORM','Cabelos','Cabelos',5.0), ('HFS','STORE PLATFORM','Always','Absorventes',2.0),
    ('HFS','STORE PLATFORM','Old Spice','Desodorantes',1.5), ('HFS','STORE PLATFORM','Secret','Desodorantes Fem',1.5),

    ('C&C','SEM PLATAFORMA','Downy','Amaciantes',9.0), ('C&C','SEM PLATAFORMA','Gillette','Laminas Masc',4.0),
    ('C&C','SEM PLATAFORMA','Pampers','Fraldas',3.5), ('C&C','SEM PLATAFORMA','Venus','Laminas Fem',2.0),
    ('C&C','SEM PLATAFORMA','Escovas','Escovas',3.0), ('C&C','SEM PLATAFORMA','Cremes','Cremes dentais',3.0),
    ('C&C','SEM PLATAFORMA','Cabelos','Cabelos',3.0), ('C&C','SEM PLATAFORMA','Always','Absorventes',2.5),
    ('C&C','SEM PLATAFORMA','Old Spice','Desodorantes',2.0), ('C&C','SEM PLATAFORMA','Secret','Desodorantes Fem',2.0),

    ('NMR','SEM PLATAFORMA','Downy','Amaciantes',9.0), ('NMR','SEM PLATAFORMA','Gillette','Laminas Masc',4.5),
    ('NMR','SEM PLATAFORMA','Pampers','Fraldas',5.0), ('NMR','SEM PLATAFORMA','Venus','Laminas Fem',2.0),
    ('NMR','SEM PLATAFORMA','Escovas','Escovas',3.5), ('NMR','SEM PLATAFORMA','Cremes','Cremes dentais',3.0),
    ('NMR','SEM PLATAFORMA','Cabelos','Cabelos',4.0), ('NMR','SEM PLATAFORMA','Always','Absorventes',2.0),
    ('NMR','SEM PLATAFORMA','Old Spice','Desodorantes',1.5), ('NMR','SEM PLATAFORMA','Secret','Desodorantes Fem',1.5);
    -- PERFUMARIA/STORE PLATFORM: sem linhas (canal sem módulo de SOS habilitado) — objetivo = 0 por ausência de peso.
GO

/* ---------------------------------------------------------------------------
   ref_peso_pe_grupo — peso máximo de cada grupo do PE, por canal.
   canal = '*' é o valor-padrão (todos os canais exceto PERFUMARIA).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.ref_peso_pe_grupo', 'U') IS NOT NULL DROP TABLE rota86.ref_peso_pe_grupo;
CREATE TABLE rota86.ref_peso_pe_grupo (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    canal           VARCHAR(30)     NOT NULL,   -- '*' = padrão; 'PERFUMARIA' = exceção
    grupo           VARCHAR(50)     NOT NULL,   -- '1. Contrato' | '2. Outras Negociações' | '3. Conquistas'
    peso_maximo     DECIMAL(9,2)    NOT NULL,
    vigente_de      DATE            NOT NULL DEFAULT '2026-07-01',
    vigente_ate     DATE            NULL,
    CONSTRAINT uq_ref_peso_pe UNIQUE (canal, grupo, vigente_de)
);
INSERT INTO rota86.ref_peso_pe_grupo (canal, grupo, peso_maximo) VALUES
    ('*',          '1. Contrato',              10.0),
    ('*',          '2. Outras Negociações',     7.0),
    ('*',          '3. Conquistas',             3.0),
    ('PERFUMARIA', '1. Contrato',              15.0),
    ('PERFUMARIA', '2. Outras Negociações',    10.0),
    ('PERFUMARIA', '3. Conquistas',             4.0);
GO

/* ---------------------------------------------------------------------------
   ref_meta_cko_canal — meta de CKO fixa por canal (não varia por plataforma)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.ref_meta_cko_canal', 'U') IS NOT NULL DROP TABLE rota86.ref_meta_cko_canal;
CREATE TABLE rota86.ref_meta_cko_canal (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    canal           VARCHAR(30)     NOT NULL,
    meta            DECIMAL(9,2)    NOT NULL,
    vigente_de      DATE            NOT NULL DEFAULT '2026-07-01',
    vigente_ate     DATE            NULL,
    CONSTRAINT uq_ref_meta_cko UNIQUE (canal, vigente_de)
);
INSERT INTO rota86.ref_meta_cko_canal (canal, meta) VALUES
    ('DPP', 15.0), ('C&C', 10.0), ('NMR', 8.0), ('GMR', 8.0),
    ('LASA', 8.0), ('HFS', 10.0), ('CLUB', 7.5);
    -- PERFUMARIA=34 usa cesta de marca diferente, fora do escopo desta regra (ver REGRAS_GERAIS.md 5.3).
GO

/* ---------------------------------------------------------------------------
   ref_config_cko — parâmetros escalares do CKO (chave/valor), versionados.
   limiar_compliance_marca = 0,46 foi calibrado empiricamente, não é uma
   regra de negócio documentada — mudar isto exige revalidação contra f_score.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.ref_config_cko', 'U') IS NOT NULL DROP TABLE rota86.ref_config_cko;
CREATE TABLE rota86.ref_config_cko (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    chave           VARCHAR(50)     NOT NULL,
    valor           DECIMAL(9,4)    NOT NULL,
    vigente_de      DATE            NOT NULL DEFAULT '2026-07-01',
    vigente_ate     DATE            NULL,
    CONSTRAINT uq_ref_config_cko UNIQUE (chave, vigente_de)
);
INSERT INTO rota86.ref_config_cko (chave, valor) VALUES
    ('limiar_compliance_marca', 0.46);
GO

/* ---------------------------------------------------------------------------
   categoria_kpi — domínio de categorias válidas por KPI. NÃO é uma lista
   inventada: são os valores DISTINCT reais extraídos direto dos arquivos
   do motor de Lojas Perfeitas (17/09/2026) — coluna CATEGORIA de
   kbdscat.xlsx (KBD), f_sos.xlsx (SOS), md_pe.xlsx (PE) e coluna MARCA de
   bases_cko.xlsx (CKO, as 3 abas de checkout). Usado tanto na leitura de
   campo (é o valor que já vem nos arquivos) quanto no select de categoria
   da tela de justificativa do app.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.categoria_kpi', 'U') IS NOT NULL DROP TABLE rota86.categoria_kpi;
CREATE TABLE rota86.categoria_kpi (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    kpi         VARCHAR(15)     NOT NULL,   -- SOS | KBD | PE | CKO
    categoria   VARCHAR(100)    NOT NULL,
    especial    BIT             NOT NULL DEFAULT 0,  -- linha técnica, não é categoria de produto (ex.: "Total PG" no PE)
    ativo       BIT             NOT NULL DEFAULT 1,
    ordem       INT             NOT NULL DEFAULT 0,
    CONSTRAINT uq_categoria_kpi UNIQUE (kpi, categoria)
);

-- KBD (kbdscat.xlsx, coluna CATEGORIA — 7 valores distintos)
INSERT INTO rota86.categoria_kpi (kpi, categoria, ordem) VALUES
    ('KBD', 'Absorventes', 1),
    ('KBD', 'Amaciantes', 2),
    ('KBD', 'Cabelos', 3),
    ('KBD', 'Cuidados com Bebe', 4),
    ('KBD', 'Desodorantes', 5),
    ('KBD', N'Lâminas e Aparelhos', 6),
    ('KBD', 'Oral', 7);

-- SOS (f_sos.xlsx, coluna CATEGORIA — 11 valores distintos)
INSERT INTO rota86.categoria_kpi (kpi, categoria, ordem) VALUES
    ('SOS', 'Absorventes', 1),
    ('SOS', 'Absorventes Internos', 2),
    ('SOS', 'Amaciantes', 3),
    ('SOS', 'Cabelos', 4),
    ('SOS', 'Cremes dentais', 5),
    ('SOS', 'Desodorantes', 6),
    ('SOS', 'Desodorantes Fem', 7),
    ('SOS', 'Escovas', 8),
    ('SOS', 'Fraldas', 9),
    ('SOS', 'Laminas Fem', 10),
    ('SOS', 'Laminas Masc', 11);

-- PE (md_pe.xlsx, coluna CATEGORIA — 9 valores distintos). "Total PG" é a
-- linha-alvo agregada do grupo Conquistas (ver src/pe.py), não uma
-- categoria de produto — marcada como especial/inativa para o select do app.
INSERT INTO rota86.categoria_kpi (kpi, categoria, especial, ativo, ordem) VALUES
    ('PE', 'Absorventes', 0, 1, 1),
    ('PE', 'Cabelos', 0, 1, 2),
    ('PE', 'Cabelos Perf', 0, 1, 3),
    ('PE', 'Desodorantes', 0, 1, 4),
    ('PE', 'Fabric', 0, 1, 5),
    ('PE', 'Fraldas', 0, 1, 6),
    ('PE', N'Lâminas', 0, 1, 7),
    ('PE', 'Oral', 0, 1, 8),
    ('PE', 'Total PG', 1, 0, 9);

-- CKO (bases_cko.xlsx, coluna MARCA — união das abas "f_CKO Regular",
-- "f_CKO Drug Chain" e "f_CKO Papa Fila Paredao"; MVP é um agregado de
-- marca (Gillette+Venus+Presto) usado só nas duas últimas abas).
INSERT INTO rota86.categoria_kpi (kpi, categoria, especial, ativo, ordem) VALUES
    ('CKO', 'Escovas', 0, 1, 1),
    ('CKO', 'Mach 3', 0, 1, 2),
    ('CKO', 'Mach3 Ap', 0, 1, 3),
    ('CKO', 'Mach3 Carga', 0, 1, 4),
    ('CKO', 'Pantene', 0, 1, 5),
    ('CKO', 'Presto 3', 0, 1, 6),
    ('CKO', 'Venus', 0, 1, 7),
    ('CKO', 'MVP', 1, 1, 8);
GO

/* ---------------------------------------------------------------------------
   feriado — datas que não cobram visita (calendario_excecoes_feriados.csv).
   Calendário estável dentro do ano corrente — carregado 1x por ano, não é
   uma carga recorrente mensal como as tabelas de staging. `ano` é derivado
   da própria data, então uma carga anual é só inserir as datas do ano
   seguinte quando ele chegar (nunca precisa apagar o ano corrente/anterior).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.feriado', 'U') IS NOT NULL DROP TABLE rota86.feriado;
CREATE TABLE rota86.feriado (
    data        DATE            NOT NULL PRIMARY KEY,
    descricao   NVARCHAR(200)   NULL,
    ano         AS (YEAR(data)) PERSISTED,
    criado_em   DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_feriado_ano ON rota86.feriado (ano);
GO

/* ---------------------------------------------------------------------------
   motivo_justificativa — motivos fixos de justificativa de NOTA (tipo='LOJA')
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.motivo_justificativa', 'U') IS NOT NULL DROP TABLE rota86.motivo_justificativa;
CREATE TABLE rota86.motivo_justificativa (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    motivo      NVARCHAR(300)   NOT NULL,
    ativo       BIT             NOT NULL DEFAULT 1,
    ordem       INT             NOT NULL DEFAULT 0
);
INSERT INTO rota86.motivo_justificativa (motivo, ordem) VALUES
    (N'Gerência da loja não autoriza o planograma no padrão MOP', 1),
    (N'Sem espaço físico na loja para a execução ideal', 2),
    (N'Volume de produtos insuficiente para justificar o espaço', 3),
    (N'Volume de produtos instável ao longo do mês', 4),
    (N'Rede trabalha com planograma próprio, diferente do MOP', 5),
    (N'Ponto extra ocupado por concorrente ou negociação da rede', 6);
GO

/* ---------------------------------------------------------------------------
   motivo_visita — motivos fixos de visita não realizada (tipo='VISITA')
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.motivo_visita', 'U') IS NOT NULL DROP TABLE rota86.motivo_visita;
CREATE TABLE rota86.motivo_visita (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    motivo      NVARCHAR(300)   NOT NULL,
    ativo       BIT             NOT NULL DEFAULT 1,
    ordem       INT             NOT NULL DEFAULT 0
);
INSERT INTO rota86.motivo_visita (motivo, ordem) VALUES
    (N'FALTA SEM JUSTIFICATIVA', 1),
    (N'Loja fechada no horário da rota', 2),
    (N'Acesso negado pela loja', 3),
    (N'Rota remanejada pelo coordenador', 4),
    (N'Promotor ausente (falta, atestado ou férias)', 5),
    (N'Treinamento', 6),
    (N'Vaga em Aberto', 7),
    (N'Problema de transporte ou deslocamento', 8),
    (N'Loja em reforma ou inventário', 9),
    (N'Tempo insuficiente para concluir a rota', 10),
    (N'Outro motivo (descrever no complemento)', 11);
GO
