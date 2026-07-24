# 01 — Empacotar NagaReader como app local

**What to build:** O usuário consegue gerar e instalar um `NagaReader.app` local em `~/Applications`, para abrir o app pelo Finder sem rodar o executável pelo Terminal.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Existe um comando versionado que compila o app e monta um bundle `.app` funcional.
- [x] O bundle gerado contém metadados mínimos corretos para o macOS reconhecer o app.
- [x] O binário compilado é copiado para o local correto dentro do bundle.
- [x] O bundle é instalado em `~/Applications/NagaReader.app` sem exigir instalação global em `/Applications`.
- [x] O README documenta como gerar, instalar e abrir o app local.
- [x] O fluxo mantém fora do escopo assinatura, notarização, App Store, DMG e instalador `.pkg`.
