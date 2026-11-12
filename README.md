# EasierShot

Aplicativo nativo de captura de tela para macOS, feito em SwiftUI, 100% offline.

## Privacidade

**O EasierShot não salva nem envia suas imagens para a nuvem ou para qualquer outro
servidor. Todo o processamento é local e seguro, na sua máquina.**

- O app não contém nenhum código de rede: não faz upload, não coleta dados de uso e não
  se conecta à internet.
- A captura existe apenas na memória até você decidir o que fazer com ela: copiar para
  a área de transferência, salvar em um arquivo no local que você escolher ou fixar na tela.
- Se você cancelar (`Esc`), a captura é descartada.

## Recursos

- Captura de todas as telas com seleção de área (mover e redimensionar pelas alças).
- Ferramentas de edição: lápis, linha, seta, retângulo, retângulo preenchido, elipse,
  marca-texto, texto, contador numerado e pixelizar.
- Cores e espessura (no ponto de cor da barra, ou pela rolagem do mouse), desfazer e refazer.
- Copiar direto para a área de transferência, sem salvar em disco (`⌘C` ou `Enter`).
- Salvar em PNG (`⌘S`).
- Fixar a captura na tela em uma janela flutuante.
- Tema claro, escuro ou do sistema; idiomas inglês e português.
- Nenhuma função de rede: o app não faz conexões com a internet.

## Requisitos

- macOS 14 (Sonoma) ou superior
- Xcode 15 ou superior

## Compilar e executar

Gerar o `EasierShot.app`:

```bash
./build-app.sh
```

Abrir o app:

```bash
open build/EasierShot.app
```

## Gerar o instalador (.dmg)

```bash
./make-dmg.sh
```

O resultado é `build/EasierShot.dmg`. Há duas formas de instalar:

- **2 cliques**: duplo clique no `.dmg` e duplo clique no EasierShot. Ele pergunta se
  deve se instalar, copia-se para Aplicativos, reabre de lá e ejeta o disco.
- **Arrastar**: duplo clique no `.dmg` e arraste o EasierShot para a pasta Aplicativos.
  O disco é ejetado automaticamente na primeira vez que o app instalado for aberto.

### Instalação rápida pela versão mais recente

As versões publicadas ficam disponíveis nos [GitHub Releases](https://github.com/HygorM10/easier-shot/releases).
Em um Mac, é possível baixar e instalar a versão mais recente com:

```bash
curl -fsSL https://raw.githubusercontent.com/HygorM10/easier-shot/main/install.sh | bash
```

O script baixa o `.dmg` da release mais recente, instala o app em `/Applications` e mostra
o progresso do download. Ao final, abra o EasierShot pelo Finder ou pelo Launchpad.
Para publicar uma versão, crie e envie uma tag no formato `v1.0.0`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Isso dispara o workflow do GitHub Actions e cria a release automaticamente. As versões atuais são builds ad hoc e podem exigir autorização em **Privacidade e Segurança** do macOS.
Para distribuição pública sem esse aviso, será necessário configurar assinatura Developer ID e notarização da Apple no GitHub Actions.

Também é possível abrir o `Package.swift` no Xcode e executar por lá. Nesse caso o programa
roda como um executável solto, sem o pacote `.app`, e por isso aparece **sem ícone** no
Dock e na lista de Gravação de Tela dos Ajustes do Sistema. Para ver o ícone colorido,
use o `EasierShot.app` gerado pelo `build-app.sh` ou instalado pelo `.dmg`.

O app fica na barra de menus (ícone de moldura com uma chama). Na primeira captura o macOS pede a
permissão de **Gravação de Tela**; autorize em Ajustes do Sistema › Privacidade e
Segurança e reabra o app.

## Atalhos

| Ação | Atalho |
| --- | --- |
| Capturar tela (global) | `⇧⌘2` |
| Copiar | `⌘C` ou `Enter` |
| Salvar | `⌘S` |
| Desfazer / Refazer | `⌘Z` / `⇧⌘Z` |
| Alterar espessura | Rolagem do mouse |
| Cancelar | `Esc` |

## Código aberto e direitos autorais

O EasierShot é um projeto de código aberto, disponibilizado sob a
[Licença MIT](https://opensource.org/licenses/MIT).

Copyright (c) 2026 HygorM10.