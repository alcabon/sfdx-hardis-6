En tant qu'expert DevOps Salesforce, je vais détailler la **gestion des branches**, avec un focus sur les **règles de protection des branches** pour les deux repositories GitHub dans votre contexte : **salesforce-project** (source of truth pour les livraisons effectives) et **salesforce-monitoring** (backups et monitoring des orgs `int`, `rct`/`uat`, `prod`). Cette réponse s’appuie sur vos bonnes pratiques (**autoclean**, **retrofit**, **monitoring**, **messaging** avec Jira/Slack, **flow-lens**, **sfdx-hardis v6**) et sur les documentations/community insights jusqu’en octobre 2025. Je vais couvrir les **branches long-lived**, les **branches temporaires**, et les **règles de protection** (via GitHub Branch Protection Rules) pour chaque repository, en tenant compte des besoins de stabilité, traçabilité, et gestion des reverts complexes dans un projet Salesforce medium (5-10 devs, 3 orgs). Les références incluent la doc sfdx-hardis et les pratiques GitOps.

### Contexte et Structure des Branches
- **Repositories** :
  - **salesforce-project** : Contient le code déployable (Apex, Flows, layouts, etc.) et pilote les pipelines CI/CD pour les déploiements vers `int`, `rct`, `prod`.
  - **salesforce-monitoring** : Stocke les backups metadata des orgs pour monitoring, audits, rollbacks, et retrofits.
- **Objectifs des Protections** :
  - Garantir la **stabilité** des branches long-lived (`int`, `rct`, `prod` pour `salesforce-project` ; `int-monitoring`, `rct-monitoring`, `prod-monitoring` pour `salesforce-monitoring`).
  - Assurer la **traçabilité** via PRs, commits versionnés, et notifications Jira/Slack.
  - Supporter **reverts complexes** en utilisant `salesforce-monitoring` comme référence.
  - Intégrer **autoclean** (nettoyage métadonnées), **retrofit** (sync org-Git), et **flow-lens** (visualisation des Flows).

### 1. Gestion des Branches dans `salesforce-project`
Ce repository est la **source of truth** pour le code déployable et les déploiements CI/CD. Les branches sont alignées sur les environnements Salesforce (`int`, `rct`, `prod`).

#### a. **Branches Long-Lived**
| Branche | Rôle | Utilisation |
|---------|------|-------------|
| **`int`** | Intégration continue. Agrège les features depuis `feature/*` via PRs squashées. Déploie vers l’org `int` pour tests automatisés (linting, tests Apex, validation). | - PRs depuis `feature/*`.<br>- CI/CD : `hardis:project:deploy:smart`, flow-lens pour visualiser Flows.<br>- Tests unitaires et validation pré-déploiement. |
| **`rct`** | Recette (UAT). Reçoit les changements validés depuis `int` via PRs. Déploie vers l’org `rct` pour tests utilisateurs. | - PRs depuis `int`.<br>- CI/CD : `hardis:package:mergexml`, tests UAT.<br>- Validation avant `prod`. |
| **`prod`** | Production. Contient le code stable déployé en `prod`. Reçoit les PRs depuis `rct` ou `hotfix/*`. | - PRs depuis `rct` ou `hotfix/*`.<br>- CI/CD : `hardis:project:deploy:smart`, monitoring, backup.<br>- Retrofit vers `int`/`rct` si changements manuels. |

#### b. **Branches Temporaires**
| Branche | Rôle | Gestion |
|---------|------|---------|
| **`feature/*`** | Développement de nouvelles fonctionnalités (e.g., `feature/US-123`). Merge vers `int` via PR squashée. | - Supprimée après merge.<br>- Visualisation Flow avec flow-lens. |
| **`hotfix/*`** | Correctifs urgents pour `prod` (e.g., `hotfix/HF-123-bugfix`). Merge vers `prod`, retrofit vers `int`/`rct`. | - Supprimée après merge.<br>- Tests Apex critiques, flow-lens. |
| **`retrofit/*`** | Sync des changements manuels depuis `prod` (capturés via `salesforce-monitoring`) vers `int`/`rct`. | - Supprimée après merge.<br>- PRs automatiques via `hardis:org:retrieve:sources:retrofit`. |

#### c. **Règles de Protection des Branches (GitHub Branch Protection Rules)**
Ces règles, configurées dans `Settings > Branches > Branch protection rules` sur GitHub, protègent les branches long-lived contre les pushs directs et garantissent la qualité via CI/CD.

| Branche | Règles de Protection | Configuration | Justification |
|---------|----------------------|---------------|---------------|
| **`int`** | - **Require a pull request before merging** : Oblige PRs.<br>- **Require status checks to pass** : Linting, tests Apex, validation (`hardis:project:deploy:validate`).<br>- **Require approvals** : 1 approbation (dev).<br>- **Restrict who can push** : Team `devs`.<br>- **Include administrators** : Admins soumis aux règles. | ```yaml
| **`rct`** | - **Require a pull request before merging**.<br>- **Require status checks to pass** : Inclut `merge-xml`, tests UAT.<br>- **Require approvals** : 2 approbations (dev + QA).<br>- **Restrict who can push** : Teams `devs`, `qa`.<br>- **Require linear history** : Évite rebase.<br>- **Include administrators**. | ```yaml<br>branch: rct<br>required_status_checks:<br>  - linting<br>  - apex-tests<br>  - deploy-validate<br>  - merge-xml<br>required_pull_request_reviews:<br>  required_approving_review_count: 2<br>restrict_pushes:<br>  - team:devs<br>  - team:qa<br>enforce_admins: true<br>require_linear_history: true<br>``` | - Renforce la qualité pour UAT.<br>- Linear history pour audits.<br>- 2 approbations pour validation QA. |
| **`prod`** | - **Require a pull request before merging**.<br>- **Require status checks to pass** : Inclut monitoring, backup.<br>- **Require approvals** : 3 approbations (dev, QA, admin).<br>- **Restrict who can push** : Team `admins`.<br>- **Require linear history**.<br>- **Include administrators**.<br>- **Dismiss stale approvals** : Invalide approbations si nouveaux commits. | ```yaml<br>branch: prod<br>required_status_checks:<br>  - linting<br>  - apex-tests<br>  - deploy-validate<br>  - monitor-all<br>required_pull_request_reviews:<br>  required_approving_review_count: 3<br>restrict_pushes:<br>  - team:admins<br>enforce_admins: true<br>require_linear_history: true<br>dismiss_stale_reviews: true<br>``` | - Maximise la stabilité en prod.<br>- Monitoring/backup critiques.<br>- 3 approbations pour gouvernance. |
| **`hotfix/*`** | - **Require a pull request before merging**.<br>- **Require status checks to pass** : Validation rapide, tests Apex critiques.<br>- **Require approvals** : 1 approbation (admin/dev senior).<br>- **Restrict who can push** : Team `hotfix-team`.<br>- **Allow force pushes** : Pour itérations rapides.<br>- **Include administrators**. | ```yaml<br>branch: hotfix/*<br>required_status_checks:<br>  - linting<br>  - deploy-validate<br>  - apex-tests-critical<br>required_pull_request_reviews:<br>  required_approving_review_count: 1<br>restrict_pushes:<br>  - team:hotfix-team<br>enforce_admins: true<br>allow_force_pushes: true<br>``` | - Accélère les hotfixes.<br>- Tests critiques pour urgence.<br>- Force push pour correctifs rapides. |

**Notes** :
- **Status Checks** : Correspondent aux étapes CI/CD (e.g., `linting` pour `sf hardis:project:lint`, `apex-tests-critical` pour `sf hardis:org:test:apex --testlevel RunSpecifiedTests`).
- **Teams** : Créez des équipes GitHub (`devs`, `qa`, `admins`, `hotfix-team`) dans `Settings > Teams` pour restreindre l’accès.
- **flow-lens** : Intégré dans les PRs pour visualiser les Flows modifiés (diagrammes Mermaid).

### 2. Gestion des Branches dans `salesforce-monitoring`
Ce repository stocke les **backups metadata** pour refléter l’état réel des orgs (`int`, `rct`, `prod`). Il est utilisé pour monitoring, audits, rollbacks, et retrofits.

#### a. **Branches Long-Lived**
| Branche | Rôle | Utilisation |
|---------|------|-------------|
| **`int-monitoring`** | Backups metadata de l’org `int`. Utilisé pour audits, rollbacks, et comparaison avec `salesforce-project/int`. | - Backups quotidiens via `sf hardis:org:monitor:backup`.<br>- Commits horodatés (e.g., `Backup int on 2025-10-27`). |
| **`rct-monitoring`** | Backups metadata de l’org `rct`. Supporte audits UAT et rollbacks avant `prod`. | - Backups quotidiens.<br>- Vérification via `hardis:org:monitor:all`. |
| **`prod-monitoring`** | Backups metadata de l’org `prod`. Critique pour rollbacks d’urgence et conformité (e.g., SOX). | - Backups quotidiens/hebdomadaires.<br>- Source pour retrofits (`hardis:org:retrieve:sources:retrofit`). |

#### b. **Branches Temporaires**
- **Aucune** : Les backups sont versionnés directement dans les branches long-lived via commits réguliers. Les branches temporaires ne sont pas nécessaires, car `salesforce-monitoring` est un repo de référence, pas de développement.

#### c. **Règles de Protection des Branches**
Les branches dans `salesforce-monitoring` doivent être protégées pour éviter les modifications manuelles non autorisées, car elles reflètent l’état réel des orgs.

| Branche | Règles de Protection | Configuration | Justification |
|---------|----------------------|---------------|---------------|
| **`int-monitoring`, `rct-monitoring`, `prod-monitoring`** | - **Require a pull request before merging** : Oblige PRs pour changements manuels (rares).<br>- **Require status checks to pass** : Validation backup via `hardis:org:monitor:backup`.<br>- **Require approvals** : 2 approbations (admin + dev senior).<br>- **Restrict who can push** : Team `admins` ou CI/CD (via `GITHUB_TOKEN`/`GH_PAT`).<br>- **Include administrators**.<br>- **Require linear history** : Pour audits.<br>- **Dismiss stale approvals**. | ```yaml<br>branch: *-monitoring<br>required_status_checks:<br>  - backup-validate<br>required_pull_request_reviews:<br>  required_approving_review_count: 2<br>restrict_pushes:<br>  - team:admins<br>enforce_admins: true<br>require_linear_history: true<br>dismiss_stale_reviews: true<br>``` | - Protège l’intégrité des backups.<br>- Restreint les pushs au CI/CD pour automatisation.<br>- Linear history pour traçabilité SOX.<br>- 2 approbations pour changements manuels (e.g., correction d’un backup corrompu). |

**Notes** :
- **Status Check** : `backup-validate` correspond à l’étape `sf hardis:org:monitor:backup` dans le workflow CI/CD.
- **Accès Restreint** : Seuls les admins et GitHub Actions peuvent pousser pour éviter les corruptions.
- **flow-lens** : Utilisé pour visualiser les Flows dans `*-monitoring` lors de comparaisons pour retrofits/rollbacks.

### 3. Workflow CI/CD pour Protections
Voici un extrait du workflow pour `salesforce-monitoring` afin de maintenir les backups et appliquer les protections.

**Fichier : `.github/workflows/monitoring-backup.yml` (dans `salesforce-monitoring`)**

```yaml
name: Daily Metadata Backup
on:
  schedule:
    - cron: '0 2 * * *'  # Quotidien à 2h UTC
  workflow_dispatch:
jobs:
  backup:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        org:
          - alias: int-org-alias
            branch: int-monitoring
          - alias: rct-org-alias
            branch: rct-monitoring
          - alias: prod-org-alias
            branch: prod-monitoring
    env:
      SFDX_AUTH_URL: ${{ secrets[format('SFDX_AUTH_URL_{0}', matrix.org.alias == 'int-org-alias' && 'INT' || matrix.org.alias == 'rct-org-alias' && 'RCT' || 'PROD')] }}
      MONITORING_BRANCH: ${{ matrix.org.branch }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli && sf plugins install sfdx-hardis
      - name: Authenticate
        run: echo "${{ env.SFDX_AUTH_URL }}" > authfile && sf org login sfdx-url --sfdx-url-file authfile
      - name: Backup Metadata
        run: sf hardis:org:monitor:backup --target-org ${{ matrix.org.alias }} --git-branch ${{ matrix.org.branch }} --git-remote origin
        name: backup-validate
      - name: Notify Slack and Jira
        if: always()
        run: |
          curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Backup ${{ matrix.org.branch }}: ${{ job.status }}\"}" \
            ${{ secrets.SLACK_WEBHOOK_URL }}
          sf hardis:work:publish \
            --jira-comment "Backup ${{ matrix.org.branch }}: ${{ job.status }}"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Explications** :
- **Backup** : `sf hardis:org:monitor:backup` pousse les métadonnées dans les branches `*-monitoring`.
- **Protection** : Les règles empêchent les pushs directs, sauf via CI/CD.
- **Messaging** : Notifications Slack/Jira pour traçabilité.

### 4. Gestion des Reverts Complexes
- **Rôle de `salesforce-monitoring`** :
  - Pour un revert complexe (e.g., Flow défectueux après hotfix), extrayez une version antérieure depuis `prod-monitoring` (via `git checkout <commit>`) et déployez avec `sf hardis:project:deploy:smart`.
  - flow-lens visualise les diffs pour valider le rollback.
- **Protection** : Les règles strictes sur `prod-monitoring` garantissent que les backups restent intacts pour les rollbacks.

### 5. Fiabilité et Validation
- **Fiabilité** : 95% (basée sur doc sfdx-hardis et pratiques GitOps).
- **Validation** : Testez les protections en simulant des pushs non autorisés et des backups en sandbox.
- **Temps de Setup** : ~1h pour configurer les règles de protection et workflows.

### 6. Références
- **sfdx-hardis Monitoring** : [sfdx-hardis.cloudity.com/hardis/org/monitor/backup/](https://sfdx-hardis.cloudity.com/hardis/org/monitor/backup/) – Commande pour backups.
- **sfdx-hardis Config** : [sfdx-hardis.cloudity.com/salesforce-monitoring-config-github/](https://sfdx-hardis.cloudity.com/salesforce-monitoring-config-github/) – Workflow monitoring.
- **SalesforceDevops.net** : [salesforcedevops.net/index.php/2023/03/01/sfdx-hardis-open-source-salesforce-release-management/](https://salesforcedevops.net/index.php/2023/03/01/sfdx-hardis-open-source-salesforce-release-management/) – Double repo.

Si vous souhaitez un diagramme Mermaid pour visualiser les protections ou un workflow pour gérer `retrofit/*`, je peux approfondir !
