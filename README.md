# acervo

Acervo é uma ferramenta para organizar, revisar e redescobrir conteúdos que você salvou ao longo do tempo.

## YouTube

### Como conseguir as chaves

Para listar uma playlist pública, o Acervo precisa de uma API key da YouTube
Data API v3:

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/).
2. Crie ou selecione um projeto.
3. Em "APIs e serviços" > "Biblioteca", procure por "YouTube Data API v3" e
   habilite a API.
4. Em "APIs e serviços" > "Credenciais", crie uma "Chave de API".
5. Use essa chave como `YOUTUBE_API_KEY`.

Para aplicar mudanças na playlist com `--apply`, também é necessário um OAuth
access token do usuário dono da playlist. O token precisa ter um escopo que
permita editar playlists, como:

```txt
https://www.googleapis.com/auth/youtube
```

ou:

```txt
https://www.googleapis.com/auth/youtube.force-ssl
```

Por enquanto o Acervo ainda não gera esse token sozinho. Você pode obter um
token temporário usando ferramentas como o OAuth Playground ou implementando o
fluxo OAuth de "Desktop app" no Google Cloud. Depois, coloque o valor em
`YOUTUBE_ACCESS_TOKEN`.

Referências oficiais:

- [YouTube Data API - primeiros passos](https://developers.google.com/youtube/v3/getting-started)
- [Credenciais da YouTube Data API](https://developers.google.com/youtube/registering_an_application)
- [OAuth para apps desktop](https://developers.google.com/youtube/v3/guides/auth/installed-apps)
- [playlistItems.update](https://developers.google.com/youtube/v3/docs/playlistItems/update)

### Configuração local

Crie um `.env` na raiz do projeto:

```sh
YOUTUBE_API_KEY=sua-chave
YOUTUBE_ACCESS_TOKEN=seu-token-oauth
```

O `YOUTUBE_ACCESS_TOKEN` só é necessário para aplicar mudanças com `--apply`.

### Como rodar a CLI

Instale as dependências:

```sh
dart pub get
```

Rode o dry-run da ordenação passando a URL da playlist:

```sh
dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

Por padrão o comando faz um dry-run: ele lista a ordem desejada usando
`contentDetails.videoPublishedAt`, que é a data em que o vídeo foi publicado no
YouTube, não a data em que ele foi adicionado na playlist.

Para aplicar a ordenação na playlist, use:

```sh
dart run acervo youtube playlist sort \
  --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" \
  --apply
```

O comando também aceita o ID puro da playlist, mas a URL costuma ser mais
prática para copiar direto do navegador.
