# 11 — Polir UX do MVP e estados de erro

**What to build:** Interface minimalista e elegante, mensagens claras para EPUB inválido/fixo/não suportado, empty states e acabamento suficiente para uso diário.

**Blocked by:** 01 — Scaffold do app macOS com janela de leitura vazia; 02 — Importar um EPUB local para armazenamento do app; 03 — Ler manifesto, spine e metadados de um EPUB reflowable; 04 — Mostrar sumário e trocar capítulos; 05 — Renderizar capítulo em WKWebView com layout centralizado; 06 — Adicionar configurações globais de leitura; 07 — Adicionar paginação simples como modo padrão; 08 — Adicionar modo de rolagem contínua configurável; 09 — Persistir posição de leitura por livro; 10 — Restaurar sessão com recentes e último livro.

**Status:** ready-for-agent

- [ ] O app apresenta empty states úteis quando nenhum livro está aberto.
- [ ] EPUB inválido, fixo ou fora do escopo gera mensagem clara.
- [ ] A interface final é minimalista, elegante e funcional.
- [ ] A sidebar, área de leitura e controles de aparência não competem visualmente com o texto.
- [ ] O app está confortável para uso diário no fluxo local pessoal definido pela spec.
