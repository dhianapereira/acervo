# acervo

Acervo é uma ferramenta para organizar, revisar e redescobrir conteúdos que você salvou ao longo do tempo.

## Como rodar

Instale as dependências:

```sh
dart pub get
```

Execute um comando com:

```sh
dart run acervo <comando>
```

Exemplo:

```sh
dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

Esse comando mostra como a playlist ficaria reorganizada pela data de publicação
original dos vídeos, do mais recente para o mais antigo. Ele só altera a playlist
quando você passa `--apply`.

## YouTube

Comandos para organizar playlists do YouTube. A configuração de OAuth, branding
no Google Cloud e os detalhes dos comandos ficam em [docs/youtube.md](docs/youtube.md).

Listar como uma playlist ficaria reorganizada pela data de publicação original
dos vídeos, sem alterar a playlist:

```sh
dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"
```

Aplicar a reorganização:

```sh
dart run acervo youtube playlist sort \
  --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" \
  --apply
```

Sincronizar os vídeos marcados como não gostei em uma playlist privada:

```sh
dart run acervo youtube playlist sync-disliked --apply
```

Separar vídeos curtidos em playlists privadas usando regras locais:

```sh
cp youtube-categories.example.json youtube-categories.json
dart run acervo youtube playlist categorize-liked --apply
```

## Licença

Este projeto está licenciado sob os termos descritos em [LICENSE](./LICENSE).
