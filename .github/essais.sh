#!/usr/bin/env bash
# Les essais d'une base OKF, joués par le banc de l'hôte de l'atelier (Movida/architecte, hote/banc.sh) :
#   .github/essais.sh [commit de base]
# Décisions : D-2026-11-16-okf-hub-01 (A : les bases du hub passent sur le banc, essais = governance.checks),
# D-2026-11-15-actions-03 (pas de fournisseur). Fichier COMMUN, identique dans chaque base : le corriger ici
# veut dire le corriger partout (environnements, okf-hub-feedback, cartographie, david-morvan, david-vie-perso).
#
# Ce qu'il vérifie, dans une image Python épinglée, avec okf-hub (public) installé à un commit épinglé :
#   1. le manifeste se charge comme le hub le charge (okf_hub.manifest.load_manifest) : un manifeste refusé
#      ou un avertissement (champ mal formé, schéma introuvable, checks illisibles) est un échec ;
#   2. chaque commande de `governance.checks`, dans l'ordre déclaré, depuis la racine de la base : un code
#      non nul est un échec. Ce sont les mêmes contrôles que `okf-review resolve --checks` joue sur le poste.
#
# CONFIDENTIALITÉ : les bases sont privées et la sortie du banc part dans le flux de l'atelier et dans le
# statut GitHub de la PR. Ce script n'imprime donc JAMAIS le contenu d'une fiche, une valeur de frontmatter
# ni la sortie d'un contrôle : seulement le nom du contrôle, son rang et son code. Le détail se lit en local
# (`okf-review resolve --checks`, ou ce script lancé avec ESSAIS_DETAIL=oui, jamais sur le banc).
#
# Le banc lance ce script avec un environnement vidé ; seul DOCKER_HOST passe. Le dépôt est monté en lecture
# seule puis copié : rien n'est écrit chez l'appelant.
# Essai local derrière un mandataire : ESSAIS_DOCKER_OPTS="--network host -e HTTPS_PROXY …" .github/essais.sh
set -uo pipefail

OKF_HUB=https://github.com/Movida/okf-hub
OKF_HUB_SHA=aa989d2bab381ec87ec804599f3d32edc7f8ccaf
IMAGE=python:3.12-bookworm@sha256:4209fae09a3e20afd863e528bfddc235da5fd5977983e1996cd54cc9a72e6267

case ${1:-} in
--dedans) # Dans le conteneur, en root : okf-hub épinglé, puis la main à un utilisateur ordinaire.
    pip install -q --root-user-action=ignore --disable-pip-version-check "okf-hub @ git+$OKF_HUB@$OKF_HUB_SHA" >/dev/null 2>&1 \
        || { echo "ÉCHEC installation d'okf-hub ($OKF_HUB_SHA)"; exit 1; }
    useradd -m -u 1000 banc
    mkdir -p /tmp/base && tar -C /source -cf - . | tar -C /tmp/base -xf - && chown -R banc: /tmp/base || exit 1
    exec setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/home/banc LANG=C.UTF-8 PATH="$PATH" \
        ESSAIS_DETAIL="${ESSAIS_DETAIL:-}" python3 -I - /tmp/base <<'PY'
import os, subprocess, sys
from pathlib import Path
from okf_hub.manifest import ManifestError, load_manifest

racine = Path(sys.argv[1])
detail = os.environ.get("ESSAIS_DETAIL") == "oui"
echecs = []

def resultat(ok, libelle, precision=""):
    print(("ok    " if ok else "ÉCHEC ") + libelle + (f" ({precision})" if precision else ""), flush=True)
    if not ok:
        echecs.append(libelle)

try:
    m = load_manifest(racine)
except ManifestError as exc:
    # Le message du hub peut citer une ligne du fichier : on n'en garde que le début, sans la valeur.
    resultat(False, "manifeste", str(exc).split(":")[0] if not detail else str(exc))
    m = None
if m is not None:
    resultat(not m.warnings, "manifeste", f"{len(m.warnings)} avertissement(s)" if m.warnings else f"base {m.name}")
    if detail:
        for w in m.warnings:
            print("      " + w)
    if not m.checks:
        print("--    aucun contrôle déclaré (governance.checks)")
    for k, argv in enumerate(m.checks, 1):
        libelle = f"contrôle {k} ({Path(argv[0]).name})"
        try:
            p = subprocess.run(argv, cwd=racine, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=600)
            code = p.returncode
            if detail:
                sys.stdout.write(p.stdout + p.stderr)
        except subprocess.TimeoutExpired:
            code = "délai"
        except OSError as exc:
            code = f"lancement impossible : {type(exc).__name__}"
        resultat(code == 0, libelle, f"code {code}")

if echecs:
    print("Essais en échec : " + ", ".join(echecs))
    sys.exit(1)
print("Tous les essais passent.")
PY
    ;;
esac

# Sur l'hôte : une image épinglée, le dépôt monté en lecture seule.
cd "$(dirname "$0")/.."
# shellcheck disable=SC2086
docker run --rm -i ${ESSAIS_DOCKER_OPTS:-} -e ESSAIS_DETAIL="${ESSAIS_DETAIL:-}" -v "$PWD:/source:ro" "$IMAGE" \
    bash /source/.github/essais.sh --dedans
