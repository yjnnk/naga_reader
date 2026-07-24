# 03 — Ler manifesto, spine e metadados de um EPUB reflowable

**What to build:** Ao importar um EPUB textual, o app entende título, ordem de capítulos e recursos básicos; EPUBs fora do escopo falham com mensagem clara.

**Blocked by:** 02 — Importar um EPUB local para armazenamento do app.

**Status:** ready-for-agent

- [ ] O app extrai metadados básicos do EPUB importado.
- [ ] O app identifica o manifesto de recursos do EPUB.
- [ ] O app identifica a ordem de leitura pelo spine.
- [ ] O app detecta ou rejeita EPUBs claramente fora do escopo do MVP.
- [ ] O comportamento de parsing é coberto por testes com fixture EPUB.
