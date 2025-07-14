# Documentação Técnica - Sistema GED

## Visão Geral
O sistema GED permite o gerenciamento eletrônico de documentos vinculados a pacientes e empresas.

## Arquitetura
- Backend: Python + Flask
- Banco de dados: MySQL (principal), Oracle (dados hospitalares)
- Armazenamento: /opt/ged/static/uploads
- Containers via Docker Compose

## Funcionalidades Principais
- Login, sessão, logs de acesso
- Gestão de usuários e empresas
- Cadastro de pessoas físicas (integração Oracle)
- Upload e visualização de documentos
- Sincronização de pacientes internados

## Rotas Principais
- `/` - Login
- `/home` - Página principal
- `/usuarios` - Gestão de usuários
- `/empresas` - Gestão de empresas
- `/pessoa_fisica` - Cadastro de pacientes
- `/upload_documento` - Upload de PDFs
- `/viewer` - Acesso público de documentos
- `/sincronizar_pacientes` - Execução manual da sincronização

## Banco de Dados
- `usuarios`, `empresas`, `pessoa_fisica`, `documentos`, `grupo_pasta`

## Execução Local
```
docker-compose up --build
```

Acesse: http://localhost:7050
