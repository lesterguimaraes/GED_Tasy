CREATE DATABASE IF NOT EXISTS ged;
USE ged;

CREATE TABLE IF NOT EXISTS empresas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    status CHAR(1) DEFAULT 'A'
);
INSERT INTO empresas (nome, descricao)
VALUES ('Hospital Beira Mar', 'HBM - Registro via banco');

CREATE TABLE IF NOT EXISTS usuarios (
    id INT(11) NOT NULL AUTO_INCREMENT,
    login VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(250) NOT NULL,
    email VARCHAR(255),
    senha VARCHAR(255) NOT NULL,
    status CHAR(1) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'Editor',
    empresa_id INT(11),
    PRIMARY KEY (id),
    KEY fk_empresa_id (empresa_id),
    CONSTRAINT fk_usuarios_empresa FOREIGN KEY (empresa_id)
        REFERENCES empresas(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
CREATE TABLE log_acesso (
    id INT AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(100) NOT NULL,
    tipo_acesso ENUM('V', 'F') NOT NULL COMMENT 'V = Válido, F = Falha',
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX (login),
    INDEX (data_hora)
);
CREATE TABLE pessoa_fisica (
    id_pessoa_fisica INT AUTO_INCREMENT PRIMARY KEY,
    cd_pessoa_fisica INT UNIQUE,
    nome_pessoa_fisica VARCHAR(255),
    nr_prontuario VARCHAR(50),
    cd_pessoa_fisica_anterior INT,
    nr_prontuario_alterior VARCHAR(50),
    dt_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    dt_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    login VARCHAR(100),
    FOREIGN KEY (login) REFERENCES usuarios(login)
);

CREATE TABLE grupo_pasta (
    id_grupo_documento INT AUTO_INCREMENT PRIMARY KEY,
    ds_grupo_documento VARCHAR(255) NOT NULL,
    grupo_pai_id INT,
    id_usuario_cadastro INT,
    dt_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    dt_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    login VARCHAR(100) NOT NULL,
    status CHAR(1) DEFAULT 'A',
    FOREIGN KEY (grupo_pai_id) REFERENCES grupo_pasta(id_grupo_documento)
);

CREATE TABLE documentos (
  id_documento INT AUTO_INCREMENT PRIMARY KEY,
  id_grupo_documento INT NOT NULL,
  nome_arquivo VARCHAR(255) NOT NULL,
  caminho_arquivo VARCHAR(512) NOT NULL,
  dt_upload DATETIME DEFAULT CURRENT_TIMESTAMP,
  cd_pessoa_fisica INT NOT NULL,
  login VARCHAR(100) NOT NULL,
  FOREIGN KEY (id_grupo_documento) REFERENCES grupo_pasta(id_grupo_documento)
);

INSERT INTO usuarios (login, nome, senha, status, tipo)
VALUES ('lester', 'Administrador', 'scrypt:32768:8:1$Ir5SErztEmLw6cTb$195c1c93a0a1b11ecf9450da7542e711387f4cefdb4457d266cb93fcc444c0a7434150f4a1ff3373e47cce35ff2d273497af24266dee5d5a6bdd757cad9729cc', 'A', 'Administrador');

INSERT INTO usuarios (login, nome, senha, status, tipo)
VALUES ('admin', 'Administrador', 'scrypt:32768:8:1$JSOMnMN7GB7uHize$ad651820676e2bdfdf946427c3a641e7e66ccc221b3b854cba797d8e683f363ea06e7430ca3ce50a4c41ad506cf6e760a16271c4585a586ed33b07f562a65dcd', 'A', 'Administrador');

INSERT INTO usuarios (login, nome, senha, status, tipo)
VALUES ('job', 'Administrador', 'scrypt:32768:8:1$JSOMnMN7GB7uHize$ad651820676e2bdfdf946427c3a641e7e66ccc221b3b854cba797d8e683f363ea06e7430ca3ce50a4c41ad506cf6e760a16271c4585a586ed33b07f562a65dcd', 'A', 'Administrador');