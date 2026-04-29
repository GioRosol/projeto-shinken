# Projeto Shinken v05 - Supabase

Versão focada em Donativos e Frequência com integração Supabase.

## Inclui
- Tela de login com Supabase Auth.
- Donativos salvando no Supabase.
- Frequência salvando no Supabase.
- Upload de comprovantes de Transferência no bucket `comprovantes`.
- Botões em Configurações para enviar dados locais e recarregar dados do Supabase.

## Primeiro uso
1. Crie o usuário em Supabase > Authentication > Users.
2. Entre no app com esse e-mail e senha.
3. Vá em Mais > Configurações.
4. Clique em `Enviar dados locais para Supabase` para mandar os dados importados do Excel.
5. Depois teste novo donativo/frequência.

## Publicação web
```powershell
flutter build web --base-href "/projeto-shinken/"
Remove-Item -Recurse -Force docs -ErrorAction SilentlyContinue
mkdir docs
Copy-Item -Path build\web\* -Destination docs -Recurse -Force
git add .
git commit -m "Integra Supabase"
git push
```


## v09 - Ajuste final de lançamento

- Login usando a logo centralizada da Igreja Messiânica.
- Frequência contínua agora abre em modal/sheet, no mesmo padrão visual do donativo.
- No lançamento de donativo, o primeiro campo agora é a origem do donativo: Urna, Transferência ou Online.
- Ao selecionar Online, o formulário muda os campos:
  - Online oficial acumulado: não pede pessoa.
  - Online identificado: pede pessoa e permite comprovante.
- Transferência mantém banco em lista suspensa: Itaú, Banco do Brasil e Bradesco.


Versão v10: MaterialApp title ajustado para Johrei Center Betim; base v09 mantida.
