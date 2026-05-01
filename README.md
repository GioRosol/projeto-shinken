# Projeto Shinken v11 — Experiência de Fé básica

Inclui cadastro básico de Experiência de Fé com:

- contador no painel
- lista e busca
- nome da pessoa
- título
- resumo
- tags
- status
- arquivo anexado
- visualização rápida do arquivo
- armazenamento no Supabase Database + Storage

Antes de usar, rode no Supabase o SQL:

`docs/supabase_migration_v11_experiencias.sql`


## v11.1
Correção: upload de arquivos Word/PDF da Experiência de Fé agora envia o MIME type correto para o Supabase Storage.

Observação: foto da pessoa será tratada no cadastro de Pessoas em etapa própria; nesta versão a experiência usa avatar/inicial quando não houver foto.

## v11.5 — Login simples e bloqueio automático

- Login por usuário simples: `Giovanni` vira `giovanni@projetoshinken.local`.
- Tela de login agora usa `Usuário` e `Senha`.
- Bloqueio automático após 15 minutos de inatividade.
- Botão Sair continua disponível em Configurações.


## v11.5.2
- Adiciona ícone próprio do app/PWA usando a logo existente da Igreja.
- Atualiza web/manifest.json, favicon e apple-touch-icon.
