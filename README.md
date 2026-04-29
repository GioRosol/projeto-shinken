# Projeto Shinken Flutter — v03 Donativos e Frequência

Versão focada em deixar funcionando os módulos principais:

- Donativos: lista, filtros, total geral, decêndios, novo lançamento, edição e exclusão.
- Frequência: lista, filtros, resumo por categoria/evento, novo lançamento, edição, exclusão e bloqueio de duplicidade por pessoa + data + evento.
- Dados reais continuam vindo de `assets/seed_data.json`.

## Como usar

Copie/substitua os arquivos deste pacote dentro da pasta do projeto Flutter que já está rodando.

Depois rode:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

Se o navegador abrir dados antigos em branco, use Ctrl+F5 no Chrome.
