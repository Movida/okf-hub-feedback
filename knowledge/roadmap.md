---
type: Roadmap
title: Roadmap des évolutions de l'outillage du hub
description: 'Ce qui a été décidé, reporté ou refusé sur les outils du hub, avec le motif de chaque décision et le retour d''usage qui l''a provoquée.

  '
tags:
- kb_search
- kb_propose
- kb_proposal_status
- kb_list
- kb_hub_rescan
- kb-review
applies-to: rév. 4.2
generated:
  by: claude-code/opus-5
  at: '2026-08-30T00:00:00Z'
verified:
- by: claude-code/opus-5
  at: '2026-08-31T00:00:00Z'
  note: ajout de la section rév. 4.2 (correctif du cooldown de re-scan)
- by: claude-code/sonnet-5
  at: '2026-09-01T00:00:00Z'
  note: ajout de la section « Livré — hors révision » (ripgrep)
- by: claude-code/sonnet-5
  at: '2026-09-01T12:00:00Z'
  note: ajout de la section « À arbitrer » (canal d'artefact source)
- by: claude-code/sonnet-5
  at: '2026-09-01T12:30:00Z'
  note: addendum résidu ripgrep post-correctif (prop-2026-09-01-9513)
- by: claude-code/sonnet-5
  at: '2026-09-11T00:00:00Z'
  note: ajout de la section «Livré — hors révision» (deploy-keys.sh, enregistrement automatique par GitHub App)
- by: claude-code/sonnet-5
  at: '2026-09-11T00:00:00Z'
  note: ajout de la section «À arbitrer» (kb_search sans repli ripgrep ; chemins GOVERNANCE.md non alignés sur kb_read)
- by: claude-code/opus-5.5
  at: '2026-09-23T00:00:00Z'
  note: ajout de l'entrée « À arbitrer » kb_read hors corpus-dir (prop-2026-09-14-be3b)
- by: claude-code/opus-5.5
  at: '2026-09-23T00:00:00Z'
  note: 'rattrapage sur le code du hub (prop-2026-09-23-af92) : version au handshake, kb_search multi-bases livré, NOT_FOUND de kb_read ; horodatages au format OKF 0.2 (datetime ISO 8601 avec décalage)'
sources:
- id: retour-j5
  resource: premier retour d'usage réel d'une session consommatrice, post-J5
- id: amendement-41
  resource: docs/SPEC-okf-bundle-hub-v0.md — amendement rév. 4.1
- id: regression-42
  resource: docs/SPEC-okf-bundle-hub-v0.md — amendement rév. 4.2
- id: prop-d8ed
  resource: prop-2026-09-01-d8ed — kb_search IO_ERROR (ripgrep absent), résolu en proposals/accepted/
- id: prop-9513
  resource: prop-2026-09-01-9513 — récidive post-correctif (installation périmée), résolu en proposals/accepted/
- id: prop-5149
  resource: prop-2026-09-01-5149 — deploy-keys.sh, enregistrement manuel des deploy keys, résolu en proposals/accepted/
---

# Roadmap des évolutions de l'outillage

Ce document est la mémoire des arbitrages. Une demande qui figure ici en
« refusée » avec son motif n'a pas à être re-instruite : c'est précisément ce
qu'on y range pour qu'elle ne revienne pas tous les trois mois (golden rule 4).

## Livré — rév. 4.1

### `kb_proposal_status` — consulter la résolution d'une proposition

**Retour à l'origine.** Un contributeur MCP-only voyait ce qui était en attente
(`kb_list` + `include_pending_concerns`) mais ne pouvait pas lire le motif de
rejet ni l'intégration de ses propres propositions : `accepted/` et `rejected/`
n'étaient lisibles que par accès git direct au dépôt.[^retour-j5]

**Décision.** Livré. Lecture pure, sans verrou ni état nouveau, git reste
canonique. Le statut est **déduit de l'emplacement** du fichier, qui fait foi ;
le champ `status` du frontmatter n'est qu'affiché, et une divergence est
signalée sans faire échouer l'appel.

**Ce qu'il faut savoir en l'utilisant :**

- au moins un de `id` ou `submitted_by` est requis — sans filtre, l'outil
  déverserait `proposals/` en entier ;
- le **corps** de la proposition n'est pas retourné. L'`id` et
  `integrated-into` suffisent : on va lire le corpus avec `kb_read` ;
- `submitted_by` est déclaratif et non authentifié. Le filtre retrouve ce qui a
  été déclaré sous ce nom, sans garantie d'identité.

### `kb_list` — re-scan implicite

**Retour à l'origine.** Une base importée pendant qu'une session était déjà
ouverte lui restait invisible jusqu'à un `kb_hub_rescan` explicite ou un
redémarrage.[^retour-j5]

**Décision.** Livré sous la forme d'un re-scan **avant** chaque `kb_list`, sous
le cooldown de 5 s déjà en place pour le re-scan sur `UNKNOWN_BASE` (§ 4.4.c),
mécanisme unique. Toute session qui liste voit donc l'état réel du disque.

**Limitation résiduelle, cosmétique :** un client qui ignore la notification
`tools/list_changed` continuera d'afficher une description de `kb_list` périmée
jusqu'à sa prochaine énumération d'outils. Le contenu retourné, lui, est à jour.

*(« même compteur » a été retiré de cette description après le correctif
rév. 4.2 ci-dessous — voir « Livré — rév. 4.2 ».)*

### `kb_search` — heading de section dans les extraits

**Retour à l'origine.** Sur un document dépassant `read-toc-threshold`, un
résultat de recherche obligeait à un aller-retour : `kb_read` sans `section`
rendait la table des headings, qu'il fallait lire pour rappeler `kb_read` avec
la bonne section.[^retour-j5]

**Décision.** Livré. Chaque extrait est annoté, après `§`, du heading normalisé
de la section contenant la ligne touchée — ou `(préambule)` si elle précède tout
heading. La valeur se reporte **telle quelle** dans `kb_read(path, section)` :
le chaînage se fait en un appel.

### `kb_propose` — clarification sur `schema.yaml`

**Retour à l'origine.** Une session consommatrice a cru devoir valider le
frontmatter de sa proposition contre le `schema.yaml` de la base.[^retour-j5]

**Décision.** Contresens du modèle : une proposition est une **affirmation
sémantique**, pas un document de corpus. Le `schema.yaml` décrit le frontmatter
du corpus ; la mise en forme conforme relève du gestionnaire, à l'intégration.
La description de `kb_propose` le dit désormais explicitement.

### Convention `status` sur `GOVERNANCE.md`

Un `GOVERNANCE.md` peut porter `status: draft` dans son frontmatter (défaut si
absent : `stable`). En brouillon, `kb_governance` préfixe sa sortie d'un
bandeau, et la skill `kb-review` prévient l'humain que les règles appliquées ne
sont pas validées. **Rien n'est bloqué** : les propositions restent acceptées et
les revues possibles. C'est une convention documentée, pas une machine à états.

## Livré — rév. 4.2

### `kb_list` — cooldown compté par déclencheur

**Retour à l'origine.** La rév. 4.1 avait fait de « le même compteur » entre
`kb_list` et le re-scan sur `UNKNOWN_BASE` une exigence explicite. À l'usage,
ce compteur unique laissait un `kb_list` consommer le cooldown, puis un import
de base juste après retomber sur `UNKNOWN_BASE` **sans** le re-scan
compensatoire garanti par la rév. 4 : l'erreur repartait telle quelle. Lister
une base puis l'utiliser dans la foulée est un usage banal, pas un cas
tordu.[^regression-42]

**Décision.** Le cooldown de 5 s et le mécanisme restent uniques ; l'horodatage
est désormais compté **séparément par déclencheur**. « Deux `kb_list` en moins
de cinq secondes ne provoquent qu'un seul parcours » reste vrai ; un `kb_list`
ne prive plus l'appel suivant du re-scan sur `UNKNOWN_BASE`.

## Livré — hors révision

### `kb_search` — message d'erreur ripgrep absent, et installation en devcontainer

**Retour à l'origine.** `kb_search` échouait sur tout appel avec `IO_ERROR:
ripgrep (rg) introuvable dans le PATH`, reproduit trois fois sur deux bases
distinctes (`installation-x`, `referentiel-x`) dans la même session ;
`kb_list` et `kb_read` fonctionnaient normalement, panne isolée à la
dépendance binaire `rg`. La session touchée avait lancé le hub depuis un clone
vu côté hôte (`hub_root=/home/…`), pas depuis une instance intra-conteneur
(`/workspaces/…`).[^prop-d8ed]

**Décision.** Livré, sur deux causes distinctes, corrigées avant la clôture
formelle de ce retour :

- **installation** — `post-create.sh` désactivait par erreur le dépôt Debian
  officiel (format deb822 dans `sources.list.d`) en tentant d'ignorer un dépôt
  tiers cassé (`yarn.list`, clé GPG expirée) ; corrigé en tolérant l'échec
  d'`apt-get update` plutôt qu'en filtrant les sources (0.2.1) ;
- **message d'erreur** — renvoyait à `.devcontainer/devcontainer.json`, qui ne
  mentionne pas ripgrep, et n'aidait sur aucun lancement hors création de
  conteneur ; il nomme désormais le PATH du **processus serveur** (transport
  stdio, § 4.3) et pointe vers `post-create.sh` et le README (0.2.2), gardé
  par un test qui vérifie que tout fichier cité existe et parle de ripgrep.

Le contournement décrit par le retour — navigation manuelle via `kb_read` sur
`index.md` — est devenu inutile après le correctif.

**Résidu, corroboré le 01/09.** `prop-2026-09-01-9513` (device "port-acme105",
soumise 10:01:59Z) reproduit l'erreur *dans son libellé pré-correctif*
(« voir `.devcontainer/devcontainer.json` »), après les deux correctifs
ci-dessus (06:41:34Z) et après la clôture de `prop-2026-09-01-d8ed`
(08:44:13Z). Pas une régression : cette installation du hub n'avait
simplement pas retiré le dépôt depuis avant le correctif. Mais rien ne le
signale à une session qui heurte l'erreur — un correctif commité au dépôt du
hub ne s'applique qu'aux installations qui l'ont retiré, et aucune n'a de
moyen de savoir si c'est son cas. Le champ `version` que le serveur MCP
annonçait alors au handshake était figé en dur (`"0.1.0"` dans `server.py`),
pendant que `CHANGELOG.md` en était à `0.2.3` : il ne reflétait pas l'état
réel du code et ne pouvait donc pas servir à distinguer une installation à
jour d'une installation périmée.[^prop-9513]

**Corrigé le 02/09, en 0.2.6** (commit `59abfbb`) : la version annoncée vient
des métadonnées du paquet installé, donc de `pyproject.toml`, remonté au
passage (0.2.8 au 23/09). Elle distingue deux versions publiées, pas deux
états du code entre deux publications. Ce qui reste — aucune vérification de
fraîcheur — est décrit dans `limitations-connues.md`.[^rattrapage-0923]

### `.devcontainer/deploy-keys.sh` — enregistrement automatique de la deploy key

**Retour à l'origine.** `deploy-keys.sh` génère la paire de clés manquante par
dépôt, mais l'enregistrement de la clé publique côté GitHub (*Settings > Deploy
keys > Add deploy key*) restait manuel, à répéter à chaque dépôt. Le retour
cite le bloc « à enregistrer à la main » du script (commit `d5cc03d`, lignes
144-162) et README.md § deploy keys ; reproduit à l'identique sur les quatre
bases ajoutées à ce dépôt (`installation-x`, `referentiel-x`,
`okf-hub-feedback`, `produit-x`). Deux pistes étaient proposées à
arbitrer — `gh repo deploy-key add` sous authentification de compte, ou un PAT
fine-grained scopé Administration — en signalant elles-mêmes qu'elles
élargissent la surface d'un conteneur compromis.[^prop-5149]

**Décision.** Livré (commit `8667394`), sous une troisième forme, plus étroite
que les deux pistes proposées : une **GitHub App** dédiée, installée une fois
par l'opérateur hors du conteneur, qui ne lui délivre qu'un **jeton
d'installation** — scopé aux seuls dépôts où l'App est installée, de courte
durée de vie (~1h), jamais journalisé ni écrit sur disque. Optionnel : en
l'absence de `OKF_HUB_GH_APP_TOKEN`, la procédure manuelle reste inchangée, la
même qu'au moment du retour. Documenté dans `README.md` § « Enregistrement
automatique de la clé (GitHub App, optionnel) » et `docs/ARCHITECTURE.md`
§ 5.3 bis, qui détaille ce que la permission GitHub App `Administration : Read
& write` ouvre au-delà des deploy keys.

**À noter pour la suite.** Les deux pistes que ce retour proposait avaient déjà
été écartées dans un cycle d'arbitrage antérieur pour le motif qu'il signale
lui-même — un secret à portée large et durable dans un conteneur qui exécute du
code de session. Inutile de les ré-instruire si elles reviennent : la décision
retenue (GitHub App, jeton d'installation borné) est au § 5.3 bis.

### `kb_search` multi-bases

**Demande.** Pouvoir passer `base: [...]` ou `base: "*"` pour chercher dans
plusieurs bases d'un coup.[^retour-j5] Reportée d'abord en v1 optionnelle, sur
un seul retour, avec une spec pré-cadrée pour que la reprise soit mécanique.

**Décision.** Livré le 02/09, en 0.2.4 (commit `bcd1fbb`, § 10.3), à la lettre
de cette spec pré-cadrée : `base` accepte un nom, une liste de noms, ou `"*"`
pour toutes les bases enregistrées. `max_results` reste un plafond **global
unique**, réparti à parts égales entre les bases qui ont encore des résultats,
le reliquat d'une base à court profitant aux autres — jamais un plafond par
base. Les résultats sont **groupés par base** ; une base sans résultat
n'apparaît pas. Un nom unique garde une sortie strictement identique à
l'avant. Un nom inconnu dans une liste fait échouer tout l'appel en
`UNKNOWN_BASE`, avant toute recherche.[^rattrapage-0923]

**Ce qu'il faut savoir en l'utilisant.** Ce qui est réparti, c'est le
**nombre** de résultats. Le budget de sortie (~4 000 tokens) reste celui d'un
seul appel : les bases sont écrites dans l'ordre de la liste (alphabétique
pour `"*"`), et quand une base épuise le budget, les suivantes n'affichent plus
que leur en-tête. Voir `limitations-connues.md`, « `kb_search` : un plafond de
sortie, même sur plusieurs bases ».

## À arbitrer

### `kb_propose` — aucun canal pour un artefact source (export XML/zip)

**Retour à l'origine.** Une session disposait d'un export à jour d'un objet Designer
(archive zip) montrant qu'une fiche générée de `referentiel-x` décrivait un état antérieur
de l'objet. Aucun paramètre de `kb_propose` ne permet de joindre ou de référencer un
artefact binaire — `content` est du markdown borné à 16 Ko — et la golden rule 1
de `referentiel-x` rejette de toute façon toute proposition touchant `designer/` : ces
fiches sont la propriété exclusive du générateur.[^prop-3cb9]

**Contournement actuel.** Déposer une **analyse** qui décrit le nouvel état et signale
explicitement qu'elle contredit la fiche générée (golden rule 9 de `referentiel-x` →
escalade). Documente l'écart, ne le résorbe pas : le corpus généré reste périmé tant que
personne ne ré-exporte et ne relance `build_catalogue.py` hors du canal `kb_propose`.

**Piste proposée, non arbitrée.** Un dépôt d'artefact tracé, distinct de `kb_propose`, dont
le générateur de la base concernée serait le seul consommateur — l'intégration restant au
gestionnaire comme aujourd'hui. Touche à la surface d'écriture du hub (§ 1, § 4.4.b) : à
remonter au propriétaire de la spécification avant toute implémentation, comme le prévoit le
CLAUDE.md du dépôt du hub. Pas de décision prise ici.

### `kb_read` — un fichier source hors `corpus-dir` ne se lit pas

**Retour à l'origine.** En diagnostiquant une perte de décimales sur
processus-x, le 14/09, une session a constaté que les fiches `-contenu.md`
générées de `referentiel-x` omettaient trois informations présentes dans les
exports XML : les affectations des `insert`/`update`, les `paramOUT`/`paramERR`
des traitements d'écran, le texte des Formules. Elle demandait de les rendre,
« ou à défaut [d']exposer les XML source via `kb_read` ».[^prop-be3b]

**Ce qui est d'ici, et ce qui ne l'est pas.** Le défaut de rendu relève de
l'outillage propre de `referentiel-x` : ni un outil du hub, ni un contenu
déposable dans cette base (`GOVERNANCE.md`, « N'appartient PAS »). Il a été
signalé et corrigé dans le dépôt de la base, en ligne de commande, le 16/09
(commit `f9bb3ed` de `referentiel-x`). Seul le repli — que `kb_read` serve un
fichier du dépôt hors `corpus-dir` — porte sur un outil du hub.

**État au 23/09.** `kb_read` est confiné à `corpus-dir` (§ 5.3) : un XML sous
`source/` ne se lit pas. Depuis le 10/09 (commit `4102cf4` du hub), un tel
chemin reçoit un `NOT_FOUND` qui dit qu'un fichier existe à cet endroit,
relatif à la racine du dépôt de la base, hors du corpus consultable. L'échec
n'est plus muet ; il reste un échec.

**Pas de décision prise ici.** Le cas qui motivait la demande est résolu à la
source : les fiches rendent désormais les trois éléments. Élargir ce que
`kb_read` peut lire toucherait au confinement du § 5.3 : comme pour le dépôt
d'artefact ci-dessus, à remonter au propriétaire de la spécification avant
toute implémentation. Côté lecture et côté dépôt, c'est la même question —
l'artefact source d'une base générée est-il, par principe, hors de portée des
outils `kb_*` ? — et elle gagne à être tranchée d'un seul tenant.

### `kb_search` — aucun repli quand ripgrep est absent du PATH du serveur

**Retour à l'origine.** `kb_search` échoue avec `IO_ERROR: ripgrep (rg)
introuvable dans le PATH`, reproduit deux fois à ~20 min d'écart, dans une
session dont le serveur était lancé via le pont d'appareil de Claude Desktop —
hors devcontainer, donc sans garantie que `rg` y soit installé. `kb_list`,
`kb_read`, `kb_governance` et `kb_propose` répondaient normalement dans la même
session : panne isolée à la dépendance binaire, distincte du bug d'installation
en devcontainer déjà traité ci-dessus (« Livré — hors révision »).[^prop-e36e]

**Coût du contournement.** Sans `kb_search`, seule la descente en cascade des
`index.md` par `kb_read` permet de localiser un document : cinq appels pour
atteindre un document sur `produit-x` (856 documents), dont deux chemins
devinés à tort. Plus coûteux : sans recherche, impossible de vérifier avant
dépôt qu'une affirmation figure déjà dans le corpus — la vérification que le
mode d'emploi recommande avant toute proposition.

**Pistes proposées, non arbitrées.**

- un repli pur Python (sans `rg`) pour `kb_search`, plus lent mais disponible
  partout où le serveur tourne ;
- un outil, ou une variante de `kb_read`, qui retourne l'arborescence des
  chemins d'une base sans leur contenu — résout la navigation indépendamment
  de ripgrep, et donne au passage la forme exacte des chemins attendus.

Pas de décision prise ici : golden rule 5, le constat est intégré, la mise en
œuvre ne l'est pas.

### `GOVERNANCE.md` — l'arborescence affichée n'est pas un chemin `kb_read`

**Retour à l'origine.** Dans au moins deux bases (`produit-x`,
`referentiel-x`), la section « Organisation du corpus » de `GOVERNANCE.md`
affiche l'arborescence du dépôt avec son préfixe de corpus compris
(`produit-kb/`, `referentiel-x-kb/`), alors que `kb_read` attend un chemin
relatif au corpus, sans ce préfixe. Un lecteur qui suit `GOVERNANCE.md`
construit donc systématiquement un chemin faux.[^prop-e36e]

**État au 23/09.** Le constat vaut pour trois bases : `installation-x` affiche
de même `installation-kb/`. Depuis le 10/09 (commit `4102cf4` du hub), un chemin
préfixé ne reçoit plus un `NOT_FOUND` muet : le message dit qu'un fichier
existe à ce chemin relatif à la racine du dépôt, et donne `corpus-dir`. Il le
range pourtant parmi les fichiers « source ou de travail, hors du corpus
consultable », alors que c'est le document du corpus lui-même, préfixe en
double — reproduit sur `produit-kb/index.md` et `referentiel-x-kb/index.md`.
Le message aide à trouver le bon chemin ; il en dit une raison
fausse.[^rattrapage-0923]

**Périmètre à confirmer.** Ce constat porte sur le contenu propre de trois
bases tierces (probablement hérité d'un gabarit commun), pas sur un outil ou
un script du hub — à la limite de ce que couvre cette base. Consigné ici parce
que la friction touche directement l'usage de `kb_read`, mais une redite dans
ces bases elles-mêmes serait la voie normale s'il s'agit d'un défaut propre à
leur documentation plutôt que d'un gabarit partagé. Le libellé du `NOT_FOUND`,
lui, est bien d'ici.

## Reporté

Rien en report au 23/09. La seule entrée, `kb_search` multi-bases, est livrée
depuis le 02/09 — voir « Livré — hors révision ».

## Refusé

### Validation du frontmatter d'une proposition avant dépôt

**Refusée.** Contresens du modèle d'affirmation sémantique — voir ci-dessus la
clarification de `kb_propose`. Une proposition soumet de l'information ; sa mise
en forme est le travail du gestionnaire. Refuser un dépôt sur un critère de
forme reviendrait à demander au contributeur de connaître le schéma du corpus
avant de pouvoir signaler quoi que ce soit.

### Re-scan « partagé au niveau du hub »

**Refusée dans cette forme.** Le besoin — qu'une session voie les bases
importées après son démarrage — est couvert par le re-scan implicite de
`kb_list`. Un rescan partagé, lui, supposerait un état partagé entre instances
ou un démon, contraire au modèle multi-instances du § 4.4 : **aucun état en
mémoire ne fait autorité, la vérité est sur le disque**.

### Authentification de `submitted_by`

**Hors périmètre v0 et v1**, inchangé : le modèle de menace est mono-utilisateur
(§ 8). Le champ reste déclaratif, et ne doit peser dans aucune décision
d'intégration.

[^retour-j5]: Premier retour d'usage réel d'une session consommatrice, post-J5, consolidé par l'amendement rév. 4.1 de la spécification.
[^regression-42]: Détecté par `test_import_a_chaud_et_rescan_silencieux` (job bout-en-bout), corrigé par l'amendement rév. 4.2 de la spécification. Post-mortem complet : `docs/ARCHITECTURE.md` § 5 bis du dépôt okf-hub.
[^prop-d8ed]: prop-2026-09-01-d8ed, résolu en `accepted/`. Correctifs :
    `.devcontainer/post-create.sh` (0.2.1) et `src/okf_hub/search.py` (0.2.2),
    voir `CHANGELOG.md` du dépôt okf-hub.
[^prop-3cb9]: prop-2026-09-01-3cb9, résolu en `accepted/` — le constat est intégré, la piste qu'il propose ne l'est pas.

[^prop-9513]: prop-2026-09-01-9513, résolu en `accepted/` — corrobore prop-2026-09-01-d8ed sans rien apporter de nouveau sur le correctif lui-même ; ce qu'elle apporte, c'est la preuve que le correctif ne se propage pas de lui-même.

[^prop-5149]: prop-2026-09-01-5149, résolu en `accepted/` — le constat (étape manuelle reproductible) est intégré ; les pistes qu'il proposait ne le sont pas (golden rule 5), la décision réellement livrée en diffère.

[^prop-e36e]: prop-2026-09-02-e36e, résolu en `accepted/`.

[^prop-be3b]: prop-2026-09-14-be3b, résolu en `accepted/` — seule la part qui vise `kb_read` est intégrée ; le défaut de générateur, hors périmètre, est corrigé dans `referentiel-x` (commit `f9bb3ed`).

[^rattrapage-0923]: prop-2026-09-23-af92, résolu en `accepted/` — rattrapage de la base sur le code du hub au 23/09, sans nouveau retour d'usage : version au handshake (0.2.6, `59abfbb`), `kb_search` multi-bases (0.2.4, `bcd1fbb`), synchronisation au démarrage (0.2.5, `5f5874e`), diagnostic `NOT_FOUND` de `kb_read` (`4102cf4`), observateur de `bases-dir` (`0427433`). Voir `CHANGELOG.md` du dépôt okf-hub.
