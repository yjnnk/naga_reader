# 02 — Adicionar seleção de fonte de leitura

**What to build:** O usuário escolhe uma fonte de leitura no menu Aparência, a escolha persiste entre execuções e o EPUB renderizado usa a fonte selecionada.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] O menu Aparência oferece uma lista curta de fontes: System, New York, Georgia, Athelas, Palatino, Charter, Iowan Old Style e Menlo.
- [x] A fonte escolhida é salva nas configurações globais de leitura.
- [x] Arquivos de configuração existentes sem fonte carregam com um valor padrão compatível.
- [x] Alterar a fonte atualiza a renderização do capítulo atual.
- [x] O CSS gerado para o documento de leitura aplica a fonte escolhida com fallbacks adequados.
- [x] A seleção de fonte compõe com tamanho da fonte, altura da linha, largura da coluna, margens, tema e modo de leitura.
- [x] A persistência e a transformação da configuração em documento de leitura são cobertas por testes nos seams existentes.
