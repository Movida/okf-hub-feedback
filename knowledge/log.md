# Journal des mises à jour

Historique des changements du corpus, groupé par date (convention OKF § 9), le
plus récent en premier. Le gestionnaire y ajoute une ligne à chaque intégration.

## 2026-09-23

* **Roadmap** : intégration de `prop-2026-09-14-be3b` — sa seule part d'ici,
  que `kb_read` serve un fichier source hors `corpus-dir`, consignée en
  « À arbitrer ». Le défaut de rendu des fiches, outillage propre
  de `referentiel-x`, y a été corrigé le 16/09 (commit `f9bb3ed`).
* **Roadmap** et **Limitations** : rattrapage sur le code du hub
  (`prop-2026-09-23-af92`), sans nouveau retour d'usage. `kb_search` multi-bases
  passe de « Reporté » à « Livré — hors révision » (livré le 02/09, 0.2.4) ;
  la version annoncée au handshake n'est plus figée (0.2.6) ; « Recherche
  mono-base » et « Aucune synchronisation avec un remote » réécrites, devenues
  fausses le 02/09 ; « Visibilité des bases » complétée de l'observateur de
  `bases-dir` (02/09) ; l'entrée `GOVERNANCE.md` d'« À arbitrer » complétée
  du diagnostic `NOT_FOUND` de `kb_read` (10/09).

## 2026-09-11

* **Roadmap** : intégration de `prop-2026-09-01-5149` — enregistrement manuel
  des deploy keys, consigné en « Livré — hors révision » (GitHub App, commit
  `8667394`, déjà en place au moment de la revue).
* **Roadmap** : intégration de `prop-2026-09-02-e36e` — `kb_search` sans repli
  quand ripgrep est absent, et chemins de `GOVERNANCE.md` non alignés sur
  `kb_read`, consignés en « À arbitrer ».

## 2026-09-01

* **Roadmap** : intégration de `prop-2026-09-01-d8ed` — `kb_search` échouait
  avec `IO_ERROR` (ripgrep introuvable), sur deux causes distinctes déjà
  corrigées côté hub (0.2.1, 0.2.2) au moment de la revue ; consigné en
  « Livré — hors révision ».

## 2026-08-30

* **Initialisation** : création de la base à partir de `okf-bundle-template`,
  en application de l'amendement rév. 4.1, § B6.
* **Roadmap** : consignation des six évolutions de la rév. 4.1 (livrées,
  reportées, refusées) et des retours d'usage qui les ont motivées.
* **Limitations** : reprise des limitations v0 assumées du README du hub, mises
  à jour de ce que la rév. 4.1 a levé.
