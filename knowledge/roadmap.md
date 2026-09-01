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
  at: 2026-08-30 00:00:00+00:00
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
distinctes (`el2d-blueway`, `el2d-referentiel`) dans la même session ;
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

**Résidu, corroboré le 01/09.** `prop-2026-09-01-9513` (device "port-el2d105",
soumise 10:01:59Z) reproduit l'erreur *dans son libellé pré-correctif*
(« voir `.devcontainer/devcontainer.json` »), après les deux correctifs
ci-dessus (06:41:34Z) et après la clôture de `prop-2026-09-01-d8ed`
(08:44:13Z). Pas une régression : cette installation du hub n'avait
simplement pas retiré le dépôt depuis avant le correctif. Mais rien ne le
signale à une session qui heurte l'erreur — un correctif commité au dépôt du
hub ne s'applique qu'aux installations qui l'ont retiré, et aucune n'a de
moyen de savoir si c'est son cas. Le champ `version` que le serveur MCP
annonce au handshake est figé en dur (`"0.1.0"` dans `server.py`), pendant
que `CHANGELOG.md` en est à `0.2.3` : il ne reflète pas l'état réel du code
et ne peut donc pas servir à distinguer une installation à jour d'une
installation périmée. Signalé, non corrigé — voir
`limitations-connues.md`.[^prop-9513]

## À arbitrer

### `kb_propose` — aucun canal pour un artefact source (export XML/zip)

**Retour à l'origine.** Une session disposait d'un export à jour d'un objet Designer
(archive zip) montrant qu'une fiche générée d'`el2d-referentiel` décrivait un état antérieur
de l'objet. Aucun paramètre de `kb_propose` ne permet de joindre ou de référencer un
artefact binaire — `content` est du markdown borné à 16 Ko — et la golden rule 1
d'`el2d-referentiel` rejette de toute façon toute proposition touchant `designer/` : ces
fiches sont la propriété exclusive du générateur.[^prop-3cb9]

**Contournement actuel.** Déposer une **analyse** qui décrit le nouvel état et signale
explicitement qu'elle contredit la fiche générée (golden rule 9 d'`el2d-referentiel` →
escalade). Documente l'écart, ne le résorbe pas : le corpus généré reste périmé tant que
personne ne ré-exporte et ne relance `build_catalogue.py` hors du canal `kb_propose`.

**Piste proposée, non arbitrée.** Un dépôt d'artefact tracé, distinct de `kb_propose`, dont
le générateur de la base concernée serait le seul consommateur — l'intégration restant au
gestionnaire comme aujourd'hui. Touche à la surface d'écriture du hub (§ 1, § 4.4.b) : à
remonter au propriétaire de la spécification avant toute implémentation, comme le prévoit le
CLAUDE.md du dépôt du hub. Pas de décision prise ici.

## Reporté

### `kb_search` multi-bases

**Demande.** Pouvoir passer `base: [...]` ou `base: "*"` pour chercher dans
plusieurs bases d'un coup.[^retour-j5]

**Décision : reportée en v1 optionnelle**, sur un seul retour. Élargir la
surface d'outils se paie sur toutes les sessions ; on attend la récurrence.

**Spec pré-cadrée**, pour que la reprise soit mécanique le jour venu : plafond
de sortie **global unique**, réparti entre les bases interrogées (et non un
plafond par base, qui multiplierait la sortie par le nombre de bases) ;
résultats **groupés par base**.

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
