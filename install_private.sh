#!/bin/bash

# ✓ INSTALLATION SÉCURISÉE AVEC AUTHENTIFICATION TOKEN GITHUB (DÉPÔT PRIVÉ)
# Ce script permet l'installation depuis un dépôt privé avec authentification par token

set -e

# Couleurs
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# ✓ VÉRIFICATION ROOT
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ ERREUR: Ce script doit être exécuté en tant que ROOT${NC}"
    echo -e "${YELLOW}   Utilisez: sudo bash install_private.sh${NC}"
    exit 1
fi

# ✓ DEMANDER LE TOKEN GITHUB
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC} ${GREEN}🔐 INSTALLATION SÉCURISÉE - MODE DÉPÔT PRIVÉ${NC} ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}[!] Pour installer depuis un dépôt privé, vous avez besoin d'un GitHub Personal Access Token${NC}"
echo ""
echo -e "${BLUE}📋 Comment obtenir un token:${NC}"
echo "   1. Allez sur: https://github.com/settings/tokens"
echo "   2. Cliquez sur 'Generate new token (classic)'"
echo "   3. Donnez un nom (ex: 'Clone-THE_S-TUNNEL-Install')"
echo "   4. Sélectionnez les permissions:"
echo "      - repo (Full control of private repositories)"
echo "      - workflow (Update GitHub Action workflows)"
echo "   5. Générez et copiez le token"
echo ""
echo -e "${YELLOW}⚠️  LE TOKEN SERA UTILISÉ UNIQUEMENT POUR CETTE INSTALLATION${NC}"
echo -e "${YELLOW}⚠️  IL NE SERA PAS SAUVEGARDÉ SUR LE SERVEUR${NC}"
echo ""
read -sp "🔑 Entrez votre GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Token vide! Aborted.${NC}"
    exit 1
fi

# ✓ DEMANDER LES INFORMATIONS DU DÉPÔT
echo ""
read -p "👤 Nom d'utilisateur GitHub (ex: wilfriedekongolo320-coder): " GITHUB_USER
read -p "📦 Nom du dépôt (ex: Clone-THE_S-TUNNEL-): " GITHUB_REPO

if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_REPO" ]; then
    echo -e "${RED}❌ Informations manquantes! Aborted.${NC}"
    exit 1
fi

# ✓ CONSTRUIRE LES URLS AVEC AUTHENTIFICATION
readonly REPO_URL="https://${GITHUB_TOKEN}@raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main"
readonly GITHUB_API_URL="https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}"

echo ""
echo -e "${BLUE}[*] Vérification de l'accès au dépôt...${NC}"

# ✓ VÉRIFIER L'ACCÈS AU DÉPÔT
if ! curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${GITHUB_API_URL}" | grep -q "\"id\""; then
    echo -e "${RED}❌ Impossible d'accéder au dépôt. Vérifiez:${NC}"
    echo "   - Le token est valide"
    echo "   - Le nom d'utilisateur est correct"
    echo "   - Le nom du dépôt est correct"
    echo "   - Vous avez les permissions sur le dépôt"
    exit 1
fi

echo -e "${GREEN}✓ Accès au dépôt validé!${NC}"

# ✓ DÉSACTIVATION SSH/SFTP PENDANT L'INSTALLATION
echo -e "${BLUE}[*] Désactivation SSH/SFTP pendant l'installation...${NC}"
systemctl stop ssh 2>/dev/null || true
systemctl disable ssh 2>/dev/null || true

# ✓ TÉLÉCHARGER LE SCRIPT PRINCIPAL EN MÉMOIRE
echo -e "${BLUE}[*] Téléchargement du script principal...${NC}"

# Créer un script temporaire qui charge nexus.sh en mémoire avec le token
INSTALLER_SCRIPT=$(mktemp)
trap "rm -f $INSTALLER_SCRIPT" EXIT

cat > "$INSTALLER_SCRIPT" <<'NESTED_SCRIPT'
#!/bin/bash

set -e

# Récupérer les variables passées en paramètres
REPO_URL="$1"
GITHUB_USER="$2"
GITHUB_REPO="$3"
GITHUB_TOKEN="$4"

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

echo -e "${BLUE}[*] Téléchargement et exécution du script principal...${NC}"

# Télécharger nexus.sh en mémoire
if ! NEXUS_SCRIPT=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${REPO_URL}/nexus.sh"); then
    echo -e "${RED}❌ Erreur: Impossible de télécharger nexus.sh${NC}"
    exit 1
fi

# Vérifier que le script n'est pas vide
if [ -z "$NEXUS_SCRIPT" ]; then
    echo -e "${RED}❌ Erreur: Script nexus.sh est vide${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Script téléchargé avec succès${NC}"
echo -e "${BLUE}[*] Exécution...${NC}"

# Exécuter le script en mémoire avec le token passé en variable d'environnement
export GITHUB_TOKEN="$GITHUB_TOKEN"
export GITHUB_USER="$GITHUB_USER"
export GITHUB_REPO="$GITHUB_REPO"
export REPO_URL="$REPO_URL"

# Exécuter le script
bash -c "$NEXUS_SCRIPT"

# Cleanup: Supprimer le token de la mémoire
unset GITHUB_TOKEN
unset REPO_URL
NESTED_SCRIPT

# ✓ EXÉCUTER LE SCRIPT D'INSTALLATION
chmod +x "$INSTALLER_SCRIPT"
bash "$INSTALLER_SCRIPT" "$REPO_URL" "$GITHUB_USER" "$GITHUB_REPO" "$GITHUB_TOKEN"

INSTALL_EXIT_CODE=$?

# ✓ CLEANUP
rm -f "$INSTALLER_SCRIPT"

# Supprimer le token de la mémoire
unset GITHUB_TOKEN

exit $INSTALL_EXIT_CODE
