#!/bin/bash
# =============================================================================
# init-salesforce-project.sh
# Initialise un projet Salesforce DevOps moderne à partir d'un repo legacy
# Utilise : sfdx-hardis v6, GitOps, double repo, autoclean, retrofit, flow-lens
# =============================================================================

set -e  # Arrête sur erreur
set -o pipefail

# -----------------------------
# CONFIGURATION (à adapter)
# -----------------------------
REPO_URL="${1:-}"  # URL GitHub du repo legacy (ex: https://github.com/company/legacy-repo.git)
PROJECT_NAME="salesforce-project"
MONITORING_REPO_NAME="salesforce-monitoring"
ORG_ALIASES=("int-org-alias" "rct-org-alias" "prod-org-alias")
ORG_BRANCHES=("int-monitoring" "rct-monitoring" "prod-monitoring")
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Token GitHub avec repo + admin:org
SF_CLI_VERSION="latest"
SFDX_HARDIS_VERSION="latest"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# -----------------------------
# VÉRIFICATIONS PRÉLIMINAIRES
# -----------------------------
command -v git >/dev/null 2>&1 || error "git n'est pas installé"
command -v node >/dev/null 2>&1 || error "node n'est pas installé"
command -v npm >/dev/null 2>&1 || error "npm n'est pas installé"
command -v sf >/dev/null 2>&1 || error "sf CLI n'est pas installé. Exécutez : npm install -g @salesforce/cli"

[[ -z "$REPO_URL" ]] && error "Usage: $0 <github-repo-url>"
[[ -z "$GITHUB_TOKEN" ]] && warn "GITHUB_TOKEN non défini → protections GitHub désactivées"

# -----------------------------
# 1. CLONE DU REPO LEGACY
# -----------------------------
log "Clonage du repo legacy : $REPO_URL"
git clone "$REPO_URL" "$PROJECT_NAME" || error "Échec du clone"
cd "$PROJECT_NAME"

# -----------------------------
# 2. INITIALISATION SALESFORCE DX
# -----------------------------
log "Initialisation du projet Salesforce DX"
sf project generate -n "$PROJECT_NAME" --output-dir . --template standard

# Créer la structure force-app
mkdir -p force-app/main/default/{classes,triggers,lwc,flows,objects,profiles,layouts,permissionsets}

# Déplacer tout le code legacy dans force-app
log "Déplacement du code legacy vers force-app/main/default/"
find . -maxdepth 1 \( -name "*.cls" -o -name "*.trigger" -o -name "*.flow-meta.xml" -o -name "*.object-meta.xml" \) -exec mv {} force-app/main/default/ \;
find . -type d \( -name "classes" -o -name "triggers" -o -name "lwc" -o -name "flows" \) -exec cp -r {} force-app/main/default/ \;

# -----------------------------
# 3. AJOUT DES FICHIERS DE CONFIG
# -----------------------------
log "Ajout des fichiers de configuration"

# .forceignore
cat > .forceignore << 'EOF'
# (contenu complet de .forceignore - voir réponse précédente)
.sfdx/
.sf/
.localdev/
.scratch/
**/*.dup
**/*.log
**/*.backup
force-app/main/default/classes/*Test.cls
force-app/main/default/lwc/**/__tests__/
EOF

# .gitignore
cat > .gitignore << 'EOF'
# (contenu complet de .gitignore)
node_modules/
.sfdx/
.sf/
.env
*.log
EOF

# package.json
cat > package.json << 'EOF'
{
  "name": "salesforce-project",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "prepare": "sf plugins install sfdx-hardis@latest",
    "format": "prettier --write .",
    "clean": "sf hardis:project:clean:all --auto",
    "lint": "sf hardis:project:lint",
    "test": "sf hardis:org:test:apex",
    "deploy:int": "sf hardis:project:deploy:smart --target-org int-org-alias --delta"
  },
  "devDependencies": {
    "@salesforce/cli": "latest",
    "sfdx-hardis": "latest",
    "prettier": "^3.3.0",
    "prettier-plugin-apex": "^2.1.0"
  }
}
EOF

# README.md
cat > README.md << 'EOF'
# Salesforce Project

Projet Salesforce DevOps avec sfdx-hardis, GitOps, double repo.

## Setup
```bash
npm ci
sf plugins install sfdx-hardis
```

## Orgs
- `int` → Integration
- `rct` → UAT
- `prod` → Production
EOF

# -----------------------------
# 4. INSTALL & FORMAT
# -----------------------------
log "Installation des dépendances"
npm ci

log "Formatage complet du code"
npm run format

log "Nettoyage des métadonnées"
npm run clean

# -----------------------------
# 5. CRÉATION DU REPO DE MONITORING
# -----------------------------
log "Création du repo de monitoring : $MONITORING_REPO_NAME"
cd ..
gh repo create "$MONITORING_REPO_NAME" --private --clone || error "Échec création repo monitoring"
cd "$MONITORING_REPO_NAME"

sf project generate -n "$MONITORING_REPO_NAME"
cp ../"$PROJECT_NAME"/.forceignore .
cp ../"$PROJECT_NAME"/.gitignore .
npm init -y
npm install sfdx-hardis@latest

# -----------------------------
# 6. BACKUP INITIAL DES ORGS
# -----------------------------
log "Backup initial des orgs"
for i in {0..2}; do
  ALIAS="${ORG_ALIASES[$i]}"
  BRANCH="${ORG_BRANCHES[$i]}"
  log "Backup $ALIAS → $BRANCH"
  git checkout -b "$BRANCH"
  sf hardis:org:monitor:backup --target-org "$ALIAS" --git-branch "$BRANCH" --git-remote origin
  git push origin "$BRANCH"
done

# -----------------------------
# 7. CONFIG BRANCHES & PROTECTIONS
# -----------------------------
cd ../"$PROJECT_NAME"
log "Création des branches long-lived"
for branch in int rct prod; do
  git checkout -b "$branch"
  git push origin "$branch"
done

if [[ -n "$GITHUB_TOKEN" ]]; then
  log "Activation des protections de branches via GitHub API"
  ORG=$(echo "$REPO_URL" | cut -d'/' -f4)
  REPO=$(echo "$REPO_URL" | cut -d'/' -f5 | cut -d'.' -f1)

  # Protection pour prod
  curl -X PUT "https://api.github.com/repos/$ORG/$REPO/branches/prod/protection" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d '{
      "required_status_checks": {"strict": true, "contexts": ["ci"]},
      "enforce_admins": true,
      "required_pull_request_reviews": {"required_approving_review_count": 3},
      "restrictions": null,
      "require_linear_history": {"enabled": true}
    }'
fi

# -----------------------------
# 8. COMMIT FINAL & TAG
# -----------------------------
cd ../"$PROJECT_NAME"
git add .
git commit -m "chore: initialisation DX, formatage, nettoyage, structure GitOps"
git tag -a v1.0.0-initial -m "Version initiale propre"
git push origin main --tags
git push origin int rct prod

# -----------------------------
# FIN
# -----------------------------
log "Initialisation terminée !"
echo
echo "Prochains étapes :"
echo "1. Configurer les GitHub Secrets : SFDX_AUTH_URL_INT, SFDX_AUTH_URL_RCT, SFDX_AUTH_URL_PROD"
echo "2. Activer les GitHub Actions"
echo "3. Premier déploiement : npm run deploy:int"
echo
echo "Repos :"
echo "  → Code : https://github.com/$(git remote get-url origin | cut -d'/' -f4-)"
echo "  → Monitoring : https://github.com/$(git remote -v | grep "$MONITORING_REPO_NAME" | head -1 | awk '{print $2}')"
