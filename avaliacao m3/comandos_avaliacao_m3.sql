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
    visualizacoes INT DEFAULT 0
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
    nota DECIMAL(3, 2) NOT NULL CHECK (nota >= 0 AND nota <= 5), -- avaliar se deve começar do 0 mesmo
    comentario TEXT,
    data_avaliacao TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    -- restrição para evitar que um unico usuario avalie o mesmo produto ou anunciante varias vezes
    UNIQUE (usuario_avaliador_id, usuario_avaliado_id, anuncio_id) -- verificar possibilidade de alterar para cada aquisição
);
-- adicionando indice para otimizar consultas na tabela avaliacoes
CREATE INDEX idx_usuario_avaliado_id ON avaliacoes (usuario_avaliado_id);
CREATE INDEX idx_anuncio_id ON avaliacoes (anuncio_id);

-- cadastra um usuário que ainda não conta como cliente
INSERT INTO usuarios (nome_usuario, senha_hash, email_usuario, primeiro_nome, ultimo_nome)
VALUES ('usuario01', 'senha_criptografada', 'usuario01@email.com', 'Rusbé', 'Maico');
INSERT INTO usuarios (nome_usuario, senha_hash, email_usuario, primeiro_nome, ultimo_nome)
VALUES ('mariasilva', 'maria123', 'maria.silva@email.com', 'Maria', 'Silva');
INSERT INTO usuarios (nome_usuario, senha_hash, email_usuario, primeiro_nome, ultimo_nome)
VALUES ('xyzcomercio', 'xyzpassword123', 'contato@empresa.com.br', 'Robervaldinei', 'Barbosa');
INSERT INTO usuarios (nome_usuario, senha_hash, email_usuario, primeiro_nome, ultimo_nome)
VALUES ('shacoalhando', 'senhadocara', 'shacoalhando@email.com', 'Shaco', 'Clones');

-- insere usuario na tabela clientes e atualiza a tabela usuarios com o cliente_id sendo referenciado
INSERT INTO clientes (nome_cliente, email, tipo_cliente, cpf, data_nascimento, telefone, cep, endereco, bairro, cidade, estado, status_cliente)
VALUES ('Maria Silva', 'maria.silva@email.com', 'PF', '123.456.789-00', '1985-03-15', '(67) 99999-8888', '79000-000', 'Rua das Flores, 123', 'Centro', 'Campo Grande', 'MS', 'ativo');
UPDATE usuarios
SET cliente_id = (SELECT cliente_id FROM clientes WHERE email = 'maria.silva@email.com')
WHERE nome_usuario = 'mariasilva';
-- insere usuario na tabela clientes e atualiza a tabela usuarios com o cliente_id sendo referenciado
INSERT INTO clientes (nome_cliente, email, tipo_cliente, cnpj, inscricao_estadual, razao_social, nome_fantasia, telefone, cep, endereco, bairro, cidade, estado, status_cliente)
VALUES ('Empresa XYZ Ltda', 'contato@empresa.com.br', 'PJ', '00.111.222/0001-33', '123456789', 'XYZ Comércio de Produtos', 'XYZ Produtos', '(11) 5555-4444', '01000-000', 'Avenida Paulista, 500', 'Bela Vista', 'São Paulo', 'SP', 'ativo');
UPDATE usuarios
SET cliente_id = (SELECT cliente_id FROM clientes WHERE email = 'contato@empresa.com.br')
WHERE nome_usuario = 'xyzcomercio';

-- insere valores na tabela categorias
INSERT INTO categorias (nome_categoria, descricao)
VALUES 
('Delivery', 'Entrega de alimentos.'),
('Transporte', 'Transporte de passageiros.'),
('Finanças', 'Serviços de contabilidade e finanças.'),
('Informática', 'Manutenção e comércio.'),
('Esportes', 'Esportes e lazer.'),
('Alimentação', 'Alimentos e produtos.');

-- atualiza uma categoria ou descrição
UPDATE categorias
SET descricao = 'Produtos alimentícios.'
WHERE nome_categoria = 'Alimentação';

-- remove
DELETE FROM categorias WHERE categoria_nome = 'Esportes';

SELECT * FROM categorias;

-- insere role(cargo) na tabela roles
INSERT INTO roles (nome_role) VALUES ('administrador');
INSERT INTO roles (nome_role) VALUES ('suporte');
INSERT INTO roles (nome_role) VALUES ('cliente');
INSERT INTO roles (nome_role) VALUES ('anunciante');
-- associa um usuario a uma role(cargo) na tabela de junção usuarios_roles onde: (usuario_id, (SELECIONA role_id DE roles ONDE nome_role = 'Nome_da_role'))
INSERT INTO usuarios_roles (usuario_id, role_id) VALUES (1, (SELECT role_id FROM roles WHERE nome_role = 'cliente'));
-- OBS: Para associar mais de uma role a um mesmo usuário apenas modifique o nome da role