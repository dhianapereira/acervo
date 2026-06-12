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

## YouTube

### Credenciais

O Acervo usa OAuth para ler e alterar playlists. Assim a mesma credencial serve
para dry-run e para `--apply`, inclusive em playlists privadas ou não listadas.

O jeito mais simples por enquanto é gerar um token temporário pelo OAuth 2.0
Playground:

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/).
2. Crie ou selecione um projeto.
3. Em "APIs e serviços" > "Biblioteca", procure por "YouTube Data API v3" e
   habilite a API.
4. Acesse o [OAuth 2.0 Playground](https://developers.google.com/oauthplayground/).
5. No passo "Step 1", procure por "YouTube Data API v3".
6. Selecione um escopo que permita editar playlists. Para este comando, use:

   ```txt
   https://www.googleapis.com/auth/youtube
   ```

   ou:

   ```txt
   https://www.googleapis.com/auth/youtube.force-ssl
   ```

7. Clique em "Authorize APIs".
8. Faça login com a conta Google dona da playlist.
9. Confirme a tela de consentimento.
10. No passo "Step 2", clique em "Exchange authorization code for tokens".
11. Copie o valor de "Access token" para `YOUTUBE_ACCESS_TOKEN`.

Esse access token expira depois de um tempo. Quando isso acontecer, gere um novo token pelo Playground e atualize o `.env`.

### Configuração local

Crie um `.env` na raiz do projeto:

```sh
YOUTUBE_ACCESS_TOKEN=seu-token-oauth
```

O `YOUTUBE_ACCESS_TOKEN` expira depois de um tempo. Quando isso acontecer, gere
um novo token pelo Playground e atualize o `.env`.

### Comandos

| Comando                                                                                                        | Descrição                                                                       |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID"`         | Lista a ordem desejada da playlist, dos vídeos mais antigos para os mais novos. |
| `dart run acervo youtube playlist sort --playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" --apply` | Aplica a ordenação na playlist no YouTube. Exige `YOUTUBE_ACCESS_TOKEN`.        |

Por padrão, o comando faz um dry-run: ele lista a ordem desejada usando
`contentDetails.videoPublishedAt`, que é a data em que o vídeo foi publicado no
YouTube, não a data em que ele foi adicionado na playlist.

O comando também aceita o ID puro da playlist, mas a URL costuma ser mais
prática para copiar direto do navegador.

## Licença

Este projeto está licenciado sob os termos descritos em [LICENSE](./LICENSE).
