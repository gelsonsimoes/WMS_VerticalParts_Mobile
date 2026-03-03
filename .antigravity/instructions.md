# Diretrizes de Desenvolvimento - Mobile (Coletor de Dados) WMS VerticalParts

## 1. Visão Geral do Projeto
- **Objetivo:** Desenvolver o aplicativo "Mobile (Coletor de Dados)" para o sistema WMS_VerticalParts.
- **Plataforma:** Android (foco em dispositivos industriais/coletores).
- **Linguagem/Framework:** Flutter / Dart.

## 2. Regra Arquitetural Principal (Fluxo Passthrough)
- **Zero Armazenamento Local:** O aplicativo NÃO deve armazenar dados de domínio localmente (não implemente bancos de dados locais como SQLite ou Room para os dados da operação).
- **Comunicação em Tempo Real:** O aplicativo atua estritamente como um repassador de dados. Toda leitura de etiqueta de código EAN deve alimentar o site/backend do WMS_VerticalParts em tempo real, utilizando a **Integração REST**.

## 3. Gestão de Assets e Mídias
- **ATENÇÃO:** Todas as imagens, ícones não-nativos e logotipos que você precisa para construir a interface do aplicativo **estão localizados na pasta `img`**. Consuma os recursos visuais diretamente deste diretório.

## 4. Identidade Visual e UI/UX (Design Industrial)
- **Tema de Alto Contraste:** O ambiente é de chão de fábrica. Utilize o padrão visual de alto contraste:
  - Fundo principal: Preto Profundo (ex: `#0A0A0A`).
  - Destaques e Ações principais: Amarelo Dourado/Action Yellow (ex: `#FFD700`).
  - Sucesso/Confirmação: Verde (ex: `#00C851`).
  - Erros/Alertas: Vermelho (ex: `#FFFF4444`).
  - Textos: Branco (ex: `#FFFFFF`) e Cinza para textos secundários.
- **Acessibilidade Operacional:** 
  - Os botões de ação devem ser superdimensionados (ex: altura mínima de 80pt) para permitir a operação por funcionários usando luvas de proteção.
  - Implemente navegação simplificada, minimizando o uso de gestos complexos. Forneça botões grandes de "Voltar" e "Continuar".
  - Fontes: Utilize a família tipográfica `Poppins` para máxima legibilidade.

## 5. Escopo Funcional de Telas
O aplicativo deve prever interfaces para os seguintes processos logísticos do Coletor de Dados:
- **Tela de Login:** Autenticação do operador (ex: ID do funcionário e senha).
- **Menu Principal:** Acesso rápido por "tiles/botões" às categorias de: Entrada/Recebimento, Alocação, Movimentação, Separação (Picking), e Inventário.
- **Leitura de Código (Scanner):** Integração com câmera do dispositivo para ler códigos EAN e códigos de endereçamento (Zonas/Corredores).
- **Entrada Manual Fallback:** Sempre forneça um teclado numérico virtual grande para digitação manual caso a etiqueta EAN esteja ilegível.

## 6. Massa de Dados Reais (Para uso em Mocks/Testes)
Sempre que precisar criar dados simulados (mocks) para pré-visualização das telas antes da integração REST, **NÃO** utilize nomes genéricos como "Produto 1" ou "Usuário Teste". Utilize estritamente os dados reais abaixo:

**Usuários/Operadores:**
- Danilo
- Matheus
- Thiago

**Catálogo de Produtos (SKU | Descrição):**
- VEPEL-BPI-174FX | Barreira de Proteção Infravermelha (174 Feixes)
- VPER-ESS-NY-27MM | Escova de Segurança (Nylon - Base 27mm)
- VPER-PAL-INO-1000 | Pallet de Aço Inox (1000mm)
- VPER-INC-ESQ | InnerCap (Esquerdo) - Ref.: VERTICALPARTS
- VPER-INC-DIR | InnerCap (Direito) - Ref.: VERTICALPARTS
- VPER-PNT-AL-22D-202X145-CT | Pente de Alumínio - 22 Dentes (202x145mm)
- VEPEL-BTI-JX02-CCS | Botoeira de Inspeção - Mod. JX02
- VPER-LUM-LED-VRD-24V | Luminária em LED Verde 24V

## 7. Padrões de Código
- O idioma de todo o texto de interface (labels, placeholders, mensagens de erro) deve ser **Português (Brasil)**.
- Mantenha tratamentos de erro visíveis (ex: "Algo deu errado") orientando o usuário sobre a falha de comunicação com a API.
