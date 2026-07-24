# 03 — Expandir navegação por teclado e entre capítulos

**What to build:** O usuário consegue controlar a leitura pelo teclado em paginação e rolagem; ao chegar ao fim ou início de um capítulo, o app muda naturalmente para o capítulo seguinte ou anterior.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Em modo paginação, seta direita, Space, Page Down e seta para baixo avançam.
- [ ] Em modo paginação, seta esquerda, Shift-Space, Page Up e seta para cima voltam.
- [ ] Em modo rolagem, seta para baixo, Space e Page Down rolam para baixo.
- [ ] Em modo rolagem, seta para cima, Shift-Space e Page Up rolam para cima.
- [ ] Avançar no fim do capítulo abre o próximo capítulo no começo.
- [ ] Voltar no início do capítulo abre o capítulo anterior próximo ao fim.
- [ ] Os botões visuais de paginação seguem as mesmas regras de avanço e retorno entre capítulos.
- [ ] A navegação respeita a seleção atual do sumário e não tenta atravessar limites quando não há capítulo anterior ou próximo.
- [ ] O comportamento de mudança de capítulo é coberto por testes no maior seam prático, e a parte de foco/eventos WebKit é validada por QA manual.
