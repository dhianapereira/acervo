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
