---
type: Limitation
title: Limitations connues du hub, et comment faire avec
description: >
  Ce que le hub ne fait pas en v0, pourquoi c'est assumé, et le contournement
  quand il y en a un.
tags: [kb_hub_rescan, kb_propose, kb_read, kb_search, okf-lock]
applies-to: "rév. 4.7"
generated:
  by: claude-code/opus-5
  at: 2026-08-30T00:00:00Z
sources:
  - id: readme-hub
    resource: "README.md du dépôt okf-hub — section « Limitations v0 assumées »"
  - id: spec-v0
    resource: "docs/SPEC-okf-bundle-hub-v0.md"
verified:
  - by: claude-code/opus-5.5
    at: '2026-09-23T00:00:00Z'
    note: 'rattrapage sur le code du hub (prop-2026-09-23-af92) : synchronisation au démarrage, version au handshake, kb_search multi-bases, observateur de bases-dir'
  - by: claude-code/opus-5.5
    at: '2026-10-27T00:00:00Z'
    note: ajout de « Les propositions en attente ne sont pas cherchées » (prop-2026-10-27-678b)
  - by: claude-code/opus-5.5
    at: '2026-11-02T00:00:00Z'
    note: rattrapage sur le code du hub au 02/11 (prop-2026-11-02-42c1) — propositions en attente cherchées sur demande (rév. 4.7), notification de l'observateur corrigée (022e291), version relevée sous Non publié, avertissements de cites et lecture du profil (rév. 4.5), corps d'une proposition dans okf-hub web
---

# Limitations connues

Une limitation listée ici est **assumée**, pas oubliée. Avant d'ouvrir un retour
sur l'une d'elles, vérifie qu'il apporte un élément nouveau : un cas d'usage que
le contournement ne couvre pas, ou un comportement qui diffère de ce qui est
décrit.

## Visibilité des bases entre sessions

**Ce qui se passe.** `kb_hub_rescan` n'a d'effet que sur l'instance qui
l'exécute. Chaque client MCP connecté a sa propre instance du serveur, avec son
propre registre.

**Depuis la rév. 4.1**, tout appel de `kb_list` déclenche la découverte (sous
cooldown de 5 s) : une base importée est donc visible de toute session qui
liste, sans rescan explicite ni redémarrage.

**Depuis le 02/09** (commit `0427433` du hub, encore sous « Non publié » dans
`CHANGELOG.md` au 23/09), chaque instance observe aussi son propre
`bases-dir` : un répertoire de base créé ou supprimé déclenche le même re-scan,
sans attendre un `kb_list`. Toujours par instance, sans état partagé
(§ 4.4.a).[^rattrapage-0923]

**Ce qui reste.** La *description* de l'outil `kb_list`, telle que l'affiche le
client, peut rester périmée si celui-ci ignore la notification
`tools/list_changed`. Le cas de l'observateur, reproduit le 23/09 — son re-scan n'avait pas de
session à notifier, et le `kb_list` suivant ne voyait plus de changement —
est corrigé depuis le 23/09 (commit `022e291` du hub) : le changement vu par
l'observateur est notifié au premier appel d'outil qui suit.[^rattrapage-1102] Le contenu retourné par l'appel, lui, est à jour. C'est cosmétique.

## `submitted_by` n'est pas authentifié

C'est un champ **déclaratif**. N'importe quelle session peut déclarer n'importe
quelle identité. Conséquences pratiques :

- il ne doit peser dans **aucune** décision d'intégration ;
- le filtre `submitted_by` de `kb_proposal_status` retrouve ce qui a été déclaré
  sous ce nom, sans garantie que ce soit la même personne ou le même agent ;
- une proposition dont le `submitted_by` semble usurpé s'escalade à l'humain.

Le modèle de menace de la v0 est mono-utilisateur (§ 8). L'authentification
n'est pas au programme.

## Synchronisation avec un remote : au démarrage seulement, jamais de push

**Depuis le 02/09** (0.2.5, commit `5f5874e` du hub), chaque instance du
serveur tire, à son démarrage et avant sa première découverte, les bases qui
ont un remote — en **fast-forward seulement**. Une base en avance sur son amont
(propositions déposées, jamais poussées) n'est pas touchée. Une **divergence**
est journalisée dans `hub.log`, jamais fusionnée ni écrasée. Un remote
injoignable ne bloque pas le démarrage. Désactivable par
`sync-on-start: false`.[^rattrapage-0923]

**Ce qui reste.** Rien n'est tiré en cours de session : une base mise à jour
en amont après le démarrage d'une instance ne l'est pas pour elle avant son
prochain démarrage. Une divergence se résout à la main. Et rien n'est poussé.

**Contournement**, en cours de session : tirer explicitement, et **sous le
verrou de la base** — sans quoi un `kb_propose` concurrent pourrait
s'intercaler :

```sh
okf-lock <base> -- sh -c "git -C \"\$(okf-base-path <base> root)\" pull --ff-only"
```

## Le corps d'une proposition n'est pas relisible via MCP

`kb_proposal_status` retourne l'état, la résolution et `integrated-into`, mais
**pas le corps** de la proposition. C'est délibéré : le corps peut peser 16 Ko,
et une fois la proposition intégrée, ce qui compte est le corpus, lisible par
`kb_read` en suivant `integrated-into`.

**Depuis la rév. 4.7**, `kb_search` avec `include_pending` montre des extraits
du corps d'une proposition **en attente**, jamais son corps entier (§ 5.7).

Pour une proposition rejetée dont on veut relire le texte exact : depuis la
rév. 4.5, la page de la proposition dans `okf-hub web`, qui rend son corps et
son motif de rejet ; sinon, accès git direct au dépôt de la base, dans
`proposals/rejected/`.[^rattrapage-1102]

## Pas de vérification de fraîcheur de l'installation

**Ce qui se passe.** Un correctif commité au dépôt du hub ne s'applique qu'aux
installations qui l'ont retiré (`git pull` / rebuild du devcontainer). Le hub
n'a ni auto-mise-à-jour ni vérification de version au démarrage : une
installation périmée reproduit indéfiniment un bug déjà corrigé en amont,
sans qu'aucun message ne le signale.[^prop-9513-lim]

**Ce qui a changé le 02/09.** Le champ `version` que le serveur annonce au
handshake n'est plus une chaîne figée (`"0.1.0"` jusqu'en 0.2.5) : depuis
0.2.6 (commit `59abfbb`), il vient des métadonnées du paquet, donc de
`pyproject.toml`. Il permet de comparer une installation à la version
d'amont. Il ne distingue pas deux états du code entre deux
relèvements de version.[^rattrapage-0923] Depuis le 29/10, la version est
relevée sous « Non publié » de `CHANGELOG.md` — 0.3.0 à la rév. 4.5, 0.3.1 à
la rév. 4.7 —, alors que la dernière section publiée reste 0.2.8 : c'est à
`pyproject.toml` en amont que la version annoncée se compare.[^rattrapage-1102]

**Contournement.** Comparer la version annoncée au handshake à celle de
`pyproject.toml` en amont ; pour un correctif encore non publié, comparer
l'historique du dépôt du hub local (`git -C <hub root> log -1`) à celui
d'amont. Sinon, retirer le dépôt et redémarrer le serveur.

## Aucune validation de conformité OKF

Le hub n'a aucune opinion sur le contenu et
n'implémente aucune validation du format OKF : ni le frontmatter, ni les noms
réservés, ni les liens entre concepts ne sont vérifiés. `schema.yaml` est de la
**documentation** injectée au gestionnaire, pas un validateur.

Une exception, et c'est un écart documenté : `index.md` et `log.md` sont
**déclassés** dans le classement de `kb_search`, parce que ce sont des sommaires
denses en texte de liens. Ils restent lisibles par `kb_read` et comptés par
`kb_list`.

**Depuis la rév. 4.5**, `kb_find` et `okf-hub web` lisent le frontmatter, et le
profil que peut porter `schema.yaml` (§ 3.5), pour filtrer et compter : ils ne
refusent rien. Seconde exception, en avertissement seulement : une base qui
déclare `cites` reçoit, dans le rapport de `kb_hub_rescan`, ses références vers
une base hors de `cites`, une base citée absente, ou un cycle (§ 3.3). Rien
n'est invalidé.[^rattrapage-1102]

## `kb_search` : un plafond de sortie, même sur plusieurs bases

**Depuis le 02/09** (0.2.4, commit `bcd1fbb`), `kb_search` interroge une ou
plusieurs bases : `base` accepte un nom, une liste de noms, ou `"*"` — voir
`roadmap.md`, « Livré — hors révision ». Ce n'est plus un appel par base à
enchaîner.

**Ce qui reste.** La sortie est plafonnée en volume (~4 000 tokens) : un seul
budget pour l'appel, quel que soit le nombre de bases. Les résultats
s'ajoutent dans l'ordre — base par base, puis par pertinence — et l'ajout
s'arrête **définitivement** au premier qui dépasse le budget restant : tout ce
qui suit est omis, y compris les bases suivantes, qui n'affichent plus que
leur en-tête. Relever `max_results` ne fait donc jamais réapparaître un
résultat masqué, et le baisser non plus. Le message de troncature le dit
depuis le 10/09 ; il conseillait auparavant de réduire
`max_results`.[^rattrapage-0923]

**Contournement.** Router vers une seule base par les descriptions de
`kb_list` quand c'est possible ; n'interroger plusieurs bases que si le sujet
est vraiment à cheval ; reformuler la requête, seul levier qui change ce qui
arrive en tête.

## Les propositions en attente : cherchées sur demande, après le corpus

**Jusqu'à la rév. 4.7**, `kb_search` ne cherchait que dans le corpus, `proposals/` en étant exclu par construction (§ 2, et liste d'exclusions transverse du § 5.2) : une proposition déposée par `kb_propose` restait introuvable jusqu'à son intégration. Constaté le 27/10/2026 : aucun résultat sur un numéro de ticket d'éditeur que citait une proposition en attente depuis la veille, alors que 261 propositions attendaient sur un hub de 8 bases.[^prop-678b-lim]

**Depuis la rév. 4.7** (02/11/2026, commit `97002e2` du hub), `include_pending` les cherche : voir `roadmap.md`, « Livré — rév. 4.7 ». Ce qui reste :[^rattrapage-1102]

- `kb_search` ne les cherche que **sur demande** (`include_pending`) ; sans l'option, une proposition reste introuvable jusqu'à son intégration ;
- une proposition en attente reste une affirmation non revue : marquée « non intégré », après le corpus, en extraits seulement — son corps entier n'est pas lisible par MCP ;
- quand le corpus remplit `max_results`, les propositions qui répondent sont comptées mais pas listées : relever `max_results` (25 au plus), ou préciser la requête. Le plafond de sortie (~4 000 tokens) vaut aussi pour elles, après le corpus.

**Contournement.** Activer `include_pending` avant de déposer, ou pour ne pas refaire une enquête. `kb_list` avec `include_pending_concerns` donne l'`id`, le `type` et le `concerns` des propositions en attente, pas leur contenu ; cette liste est la première tronquée quand la sortie dépasse son plafond (§ 5.1), et le message de troncature renvoie, depuis le 02/11/2026, à `kb_search` avec `include_pending` et à `kb_proposal_status` avec `submitted_by`. Pour ce qu'a déposé un contributeur connu : `kb_proposal_status` avec `submitted_by` et `status: pending`. Pour un humain : la boîte des propositions en attente d'`okf-hub web`. Sinon, accès git direct à `proposals/pending/` de la base.

## Gros documents : deux appels, ou un seul

Au-delà de `read-toc-threshold`, `kb_read` sans `section` retourne la **table
des headings** au lieu du contenu. Ce n'est pas une limitation à contourner,
c'est le fonctionnement voulu (§ 1.5 : retourner le minimum pertinent).

Depuis la rév. 4.1, un résultat de `kb_search` porte le heading de sa section
après `§` : le reporter dans `kb_read(path, section)` donne la section en un
seul appel. `force: true` reste disponible pour le document entier.

[^prop-9513-lim]: prop-2026-09-01-9513, résolu en `accepted/`.

[^rattrapage-0923]: prop-2026-09-23-af92, résolu en `accepted/` — rattrapage de la base sur le code du hub au 23/09, sans nouveau retour d'usage : version au handshake (0.2.6, `59abfbb`), `kb_search` multi-bases (0.2.4, `bcd1fbb`), synchronisation au démarrage (0.2.5, `5f5874e`), diagnostic `NOT_FOUND` de `kb_read` (`4102cf4`), observateur de `bases-dir` (`0427433`). Voir `CHANGELOG.md` du dépôt okf-hub.

[^prop-678b-lim]: prop-2026-10-27-678b, résolu en `accepted/`.


[^rattrapage-1102]: prop-2026-11-02-42c1, résolu en `accepted/` — rattrapage de la base sur le code du hub au 02/11/2026 (0.3.1, spec rév. 4.7), sans nouveau retour d'usage : propositions en attente cherchables (rév. 4.7, `97002e2`), messages de `kb_list` et de `kb_read` corrigés (`de8b84a`), notification de l'observateur (`022e291`, 23/09), version relevée sous « Non publié » (`e9c87c3`, `97002e2`), `cites` et profil (rév. 4.5). Voir `CHANGELOG.md` et `docs/SPEC-okf-bundle-hub-v0.md` du dépôt okf-hub.
