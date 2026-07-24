# 09 — Persistir posição de leitura por livro

**What to build:** Ao fechar e reabrir o app/livro, a leitura volta para o último capítulo e posição conhecida.

**Blocked by:** 07 — Adicionar paginação simples como modo padrão; 08 — Adicionar modo de rolagem contínua configurável.

**Status:** done

- [x] O app salva a posição de leitura separadamente para cada livro.
- [x] A posição inclui capítulo atual e localização suficiente para retomar leitura.
- [x] Reabrir um livro restaura a posição salva.
- [x] A persistência funciona para paginação e rolagem contínua.
- [x] O armazenamento de posição é testável sem depender de WKWebView real.
