# YouTube

O Acervo usa OAuth para ler e alterar playlists. Assim a mesma autorização serve
para dry-run e para `--apply`, inclusive em playlists privadas ou não listadas.

## Credenciais

Primeiro configure o projeto no Google Cloud:

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/).
2. Crie ou selecione um projeto.
3. Em "APIs e serviços" > "Biblioteca", procure por "YouTube Data API v3" e
   habilite a API.
4. Em "APIs e serviços" > "Google Auth Platform", abra "Branding".
5. Preencha as informações obrigatórias:
   - App name: `Acervo`
   - User support email: seu email
   - Developer contact email: seu email
6. Salve o branding.
7. Em "Audience", deixe o app como "Testing" para uso local.
8. Em "Test users", adicione a conta Google dona da playlist.
9. Em "Data Access" ou "Scopes", adicione o escopo:

   ```txt
   https://www.googleapis.com/auth/youtube
   ```

10. Em "APIs e serviços" > "Credenciais", crie um "ID do cliente OAuth".
11. Use o tipo "Aplicativo da Web".
12. Em "URIs de redirecionamento autorizados", adicione:

   ```txt
   http://localhost:53682/oauth2callback
   ```

13. Copie o Client ID e o Client secret para o `.env`.

Crie um `.env` na raiz do projeto:

```sh
cp .env.example .env
```

Depois rode:

```sh
dart run acervo youtube auth
```

O comando imprime uma URL de autorização do Google, espera o callback local e
salva `YOUTUBE_ACCESS_TOKEN` e `YOUTUBE_REFRESH_TOKEN` no `.env`.

Se quiser usar outra porta, registre o redirect URI correspondente no Google
Cloud e passe `--port`:

```sh
dart run acervo youtube auth --port 53683
```

O `YOUTUBE_ACCESS_TOKEN` expira depois de um tempo, mas o Acervo renova o token
automaticamente quando `YOUTUBE_REFRESH_TOKEN`, `YOUTUBE_CLIENT_ID` e
`YOUTUBE_CLIENT_SECRET` estão configurados.

## Comandos

### Reorganizar playlist por data de publicação

Listar a ordem desejada por data de publicação do vídeo, sem alterar a playlist:

```sh
dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

Aplicar essa ordenação na playlist:

```sh
dart run acervo youtube playlist sort \
  --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" \
  --apply
```

Por padrão, o comando faz um dry-run: ele apenas lista a ordem desejada usando
`contentDetails.videoPublishedAt`, que é a data em que o vídeo foi publicado no
YouTube, não a data em que ele foi adicionado na playlist.

O comando também aceita o ID puro da playlist, mas a URL costuma ser mais
prática para copiar direto do navegador.

### Copiar vídeos marcados como não gostei

O YouTube não mostra uma playlist de vídeos marcados como "não gostei", mas a
API permite consultá-los. Para visualizar o que será sincronizado:

```sh
dart run acervo youtube playlist sync-disliked
```

Para criar ou atualizar a playlist privada `Disliked videos`:

```sh
dart run acervo youtube playlist sync-disliked --apply
```

Use `--name` para escolher outro nome. O comando não duplica vídeos que já
estão na playlist e não remove itens existentes.

### Categorizar vídeos curtidos

Copie o exemplo e edite as categorias, playlists e palavras-chave:

```sh
cp youtube-categories.example.json youtube-categories.json
```

As regras são avaliadas na ordem do arquivo. Título, descrição e tags são
comparados sem diferenciar maiúsculas de minúsculas; a primeira categoria que
combinar recebe o vídeo, portanto cada vídeo entra em no máximo uma playlist.
Vídeos sem correspondência são apenas contabilizados.

Faça primeiro uma simulação:

```sh
dart run acervo youtube playlist categorize-liked
```

Depois crie e atualize as playlists privadas:

```sh
dart run acervo youtube playlist categorize-liked --apply
```

Para usar outro arquivo, passe `--config caminho/para/categorias.json`. O
comando evita duplicatas e não remove vídeos que já estejam nas playlists.

Adicionar um vídeo a uma playlist custa 50 unidades da cota da YouTube Data
API. Para coleções grandes, talvez seja necessário executar novamente no dia
seguinte depois que a cota diária for renovada.
