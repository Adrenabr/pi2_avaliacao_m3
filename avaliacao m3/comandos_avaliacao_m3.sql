-- cria tabela usuarios
CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nome_usuario VARCHAR(50) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL, -- verificar bcrypt ou Argon2
    email_usuario VARCHAR(100) UNIQUE NOT NULL, -- login ou recuperacao, implementar
    token_recuperacao_senha VARCHAR(255) UNIQUE, -- token de recuperacao(com data/hora de expiração), conferir necessidade de tamanho
    data_ultima_alteracao_senha TIMESTAMP WITHOUT TIME ZONE,
    tentativas_login_falhas INT DEFAULT 0, -- contator de tentativas falhas para bloquear login
    data_bloqueio TIMESTAMP WITHOUT TIME ZONE,
    codigo_verificacao VARCHAR(6), -- código para verificacao de email ou telefone
    data_expiracao_codigo_verificacao TIMESTAMP WITHOUT TIME ZONE, -- data e hora para expirar codigo de verificacao
    data_cadastro TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    ultimo_login TIMESTAMP WITHOUT TIME ZONE,
    ativo BOOLEAN DEFAULT TRUE NOT NULL, -- se necessario ativação via email mudar
    cliente_id INT REFERENCES clientes(cliente_id), -- FK para vincular a tabela clientes
    primeiro_nome VARCHAR(50),
    ultimo_nome VARCHAR(50),
    foto_perfil VARCHAR(255), -- caminho para img de perfil do usuario
    descricao_anunciante TEXT -- verificar possibilidade de separar uma tabela anunciante
);
-- cria tabela roles(cargos de usuarios)
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    nome_role VARCHAR(50) UNIQUE NOT NULL,
    descricao TEXT
);
-- cria tabela de junção usuarios x roles
CREATE TABLE usuarios_roles (
    usuario_id INT NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    role_id INT NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, role_id)
);
-- cria tabela clientes
CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nome_cliente VARCHAR(100) NOT NULL, -- caso PJ, o responsável
    email VARCHAR(100) UNIQUE,
    tipo_cliente VARCHAR(2) CHECK (tipo_cliente IN ('PF', 'PJ')),
    cpf VARCHAR(14) UNIQUE,
    data_nascimento DATE, -- apenas para PF, implementar lógica de negócio
    cnpj VARCHAR(18) UNIQUE,
    inscricao_estadual VARCHAR(20), -- apenas para PJ, implementar lógica de negócio
    razao_social VARCHAR(100), -- apenas para PJ, implementar lógica de negócio
    nome_fantasia VARCHAR(100),  -- apenas para PJ, implementar lógica de negócio
    telefone VARCHAR(20),
    cep VARCHAR(10),
    endereco VARCHAR(255),
    complemento_endereco VARCHAR(50),
    bairro VARCHAR(50),
    cidade VARCHAR(50),
    estado VARCHAR(2),
    observacoes TEXT,
    status_cliente VARCHAR(20),
    data_cadastro TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
-- cria tabela categorias para categorizar os anuncios
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nome_categoria VARCHAR(100) UNIQUE NOT NULL,
    descricao TEXT,
    data_cadastro TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW() -- verificar necessidade de especificar nome para melhor legibilidade
);
-- cria tabela anuncios para armazenar informações dos anuncios
CREATE TABLE anuncios (
    anuncio_id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    categoria_id INT NOT NULL REFERENCES categorias(categoria_id),
    titulo_anuncio VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    preco DECIMAL(10, 2) NOT NULL,
    data_publicacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    data_atualizacao TIMESTAMP WITHOUT TIME ZONE,
    status_anuncio VARCHAR(20) CHECK (status_anuncio IN ('ativo', 'inativo', 'vendido', 'reservado', 'expirado')) DEFAULT 'ativo',
    localizacao VARCHAR(255), -- verificar possibilidade de especificidades
    destaque BOOLEAN DEFAULT FALSE, -- caso esteja em destaque
    visualizacoes INT DEFAULT 0,
    PRIMARY KEY (anuncio_id)
);
-- cria tabela imagens_anuncios para armazenar multiplas imagens dos anuncios
CREATE TABLE imagens_anuncios (
    imagem_id SERIAL PRIMARY KEY,
    anuncio_id INT NOT NULL REFERENCES anuncios(anuncio_id) ON DELETE CASCADE,
    url_imagem VARCHAR(255) NOT NULL,
    descricao_imagem VARCHAR(255),
    ordem INT DEFAULT 1 -- define a ordem de exibição das imagens
);
-- cria tabela avaliacoes para armazenar as avaliações dos produtos ou anunciantes
CREATE TABLE avaliacoes (
    avaliacao_id SERIAL PRIMARY KEY,
    usuario_avaliador_id INT NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    usuario_avaliado_id INT NOT NULL REFERENCES usuarios(usuario_id), -- avalia o anunciante(testar função)
    anuncio_id INT REFERENCES anuncios(anuncio_id), -- avalia um produto específico (opcional, pode ser avaliação do anunciante em geral)
    nota DECIAML(3, 2) NOT NULL CHECK (nota >= 0 AND nota <= 5), -- avaliar se deve começar do 0 mesmo
    comentario TEXT,
    data_avaliacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    -- restrição para evitar que um unico usuario avalie o mesmo produto ou anunciante varias vezes
    UNIQUE (usuario_avaliador_id, usuario_avaliado_id, anuncio_id) -- verificar possibilidade de alterar para cada aquisição
);
-- adicionando indice para otimizar consultas na tabela avaliacoes
CREATE INDEX idx_usuario_avaliado_id ON avaliacoes (usuario_avaliado_id);
CREATE INDEX idx_anuncio_id ON avaliacoes (anuncio_id);

-- insere role(cargo) na tabela roles
INSERT INTO roles (nome_role) VALUES ('Cliente');
-- associa um usuario a uma role(cargo) na tabela de junção usuarios_roles onde: (usuario_id, (SELECIONA role_id DE roles ONDE nome_role = 'Nome_da_role'))
INSERT INTO usuarios_roles (usuario_id, role_id) VALUES (1, (SELECT role_id FROM roles WHERE nome_role = 'Cliente'));
-- OBS: Para associar mais de uma role a um mesmo usuário apenas modifique o nome da role