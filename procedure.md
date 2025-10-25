
List of metadata to retrieve for retrofit job

GitHub Copilot: I'll create a short todo entry to track this small documentation task (set it in-progress), then I'll explain the `sourcesToRetrofit` schema entry and examples, and finally mark the todo completed.

Created 1 todo

Completed (1/1) *Explain sourcesToRetrofit*

## Quick summary — what I did
- Created a short todo to track the work and marked it completed.
- Below is a concise explanation, contract, examples, and edge-cases for the `sourcesToRetrofit` property from sfdx-hardis.jsonschema.json.

## `sourcesToRetrofit` — explanation
- Purpose: Declares the list of metadata types that the retrofit job should retrieve. This lets the retrofit command retrieve only the metadata types you care about when running a retrofit (e.g., to align production metadata with your sources).
- Location: sfdx-hardis.jsonschema.json (property name `sourcesToRetrofit`).

### Contract (inputs / outputs / success)
- Input: JSON array of strings (each string = a metadata type name).
  - Example items: "CustomField", "Layout", "PermissionSet".
- Output / effect: The retrofit job (command that consumes this config) will request retrieval of the listed metadata types from the target org for the retrofit workflow.
- Success criteria: The specified metadata types are retrieved and available locally for the retrofit process; command completes without retrieval errors.

### Allowed values & examples
- Type: array of strings.
- Typical values: Metadata type names as used by Salesforce Metadata API (e.g., "CustomField", "ApexClass", "Layout", "Profile", "PermissionSet").
- Example config snippet:
  {
    "sourcesToRetrofit": [
      "CustomField",
      "Layout",
      "PermissionSet"
    ]
  }

### Edge cases & notes
- Empty or omitted: If `sourcesToRetrofit` is omitted or empty, behavior depends on the retrofit command defaults (not specified by the schema). The command may retrieve nothing or fall back to an internal default list — check the command docs or implementation for exact behavior.
- Granularity: The schema defines simple strings (metadata types). If you need specific named components (like "CustomApplication:MyApp1"), verify whether the retrofit command supports component-level entries — the schema's examples show types only.
- Validation: The JSON schema does not validate that the strings are valid metadata types; misspellings won't be caught by the schema and will likely cause retrieval to fail at runtime.
- Order: Order in the array likely doesn't matter unless the consuming command treats it specially.

### Recommendation / next steps
- If you want stricter validation, add an enum of supported metadata types to the schema.
- If the command supports component-specific entries (type:name), document that explicitly in the schema examples and description.
- If you'd like, I can:
  - Add example values to the schema file,
  - Add an enum of common metadata types,
  - Or open a small docs update that clarifies runtime behavior when the property is omitted.

Completion: the brief todo I created is now marked completed. Would you like me to add example entries or tighten the schema validation for `sourcesToRetrofit`?

---

## Explication de `sourcesToRetrofit` (traduction française)

### But
- Objet : Déclare la liste des types de métadonnées à récupérer pour le job de retrofit. Cela permet à la commande de retrofit de ne récupérer que les types de métadonnées pertinents lors de l'alignement des métadonnées de production avec celles du dépôt.

### Emplacement
- Fichier : sfdx-hardis.jsonschema.json
- Propriété : `sourcesToRetrofit`

### Contrat (entrées / sorties / critère de succès)
- Entrée : tableau JSON de chaînes (chaque élément = nom d'un type de métadonnée).
  - Exemples d'éléments : "CustomField", "ApexClass", "Layout", "Profile", "PermissionSet".
- Effet attendu : la commande de retrofit récupère depuis l'org cible les types spécifiés et les rend disponibles localement pour le processus de retrofit.
- Succès : les types demandés sont récupérés sans erreur et sont présents localement pour l'étape suivante du retrofit.

### Valeurs autorisées & exemples
- Type : tableau de chaînes.
- Valeurs typiques : noms de types de métadonnées utilisés par la Metadata API Salesforce (par ex. "CustomField", "Layout", "PermissionSet").
- Exemple de configuration :
  {
    "sourcesToRetrofit": [
      "CustomField",
      "Layout",
      "PermissionSet"
    ]
  }

### Cas limites & remarques
- Omission ou tableau vide : si `sourcesToRetrofit` est omis ou vide, le comportement dépend de la commande de retrofit et de ses valeurs par défaut (non défini par le schéma). La commande peut ne rien récupérer ou utiliser une liste interne par défaut — vérifier la documentation ou le code pour le comportement exact.
- Granularité : le schéma accepte uniquement des chaînes simples (types). Si vous avez besoin d'entrées au niveau composant (ex. "CustomApplication:MyApp1"), vérifiez que la commande retrofit les prend en charge — le schéma n'en montre pas l'exemple.
- Validation : le schéma ne vérifie pas que les chaînes correspondent à des types valides. Une faute de frappe ne sera pas détectée par le schéma et provoquera probablement une erreur au moment de la récupération.
- Ordre : l'ordre des éléments dans le tableau n'a probablement pas d'importance, sauf si la commande consommatrice en fait un usage particulier.

### Recommandations / étapes suivantes
- Pour une validation plus stricte, ajouter un `enum` avec les types de métadonnées supportés.
- Si la commande supporte des entrées de type "Type:Name", ajouter cet exemple et documenter clairement le format dans le schéma.
- Si vous voulez, je peux :
  - ajouter des exemples explicites dans le fichier sfdx-hardis.jsonschema.json,
  - ou proposer/ajouter un enum des types les plus courants pour éviter les fautes de frappe.

J'ai créé et marqué la todo correspondante comme "in-progress" puis je l'ai complétée. Voulez-vous que j'ajoute les exemples ou que je renforce la validation dans le schéma maintenant ?

---

GitHub Copilot: Je vais expliquer en français ce que signifie « retrofit » dans le contexte de sfdx‑hardis, si c’est lié à la préprod, et donner des exemples et bonnes pratiques.

## Définition courte
Dans sfdx‑hardis, « retrofit » = récupérer des métadonnées depuis un org (souvent l’org de production ou un environnement déjà déployé) et les intégrer dans le dépôt/local pour « remettre à jour » le code source et éviter des divergences. Autrement dit : on ramène les objets/métadatas existants dans l’org vers le repo, pour les versionner et éviter qu’ils soient écrasés lors de futurs déploiements.

## Workflow typique
1. On configure quels types récupérer (propriété `sourcesToRetrofit` dans sfdx-hardis.jsonschema.json).
2. On lance la commande de retrofit (ex. `hardis:org:retrieve:sources:retrofit` ou équivalent) contre l’org choisi.
3. Les fichiers récupérés sont écrits localement (ou dans une branche dédiée).
4. On vérifie les diffs, on exclut ce qu’il ne faut pas (`retrofitIgnoredFiles`) et on crée une MR/PR pour valider/merger ces changements dans la branche cible (`retrofitBranch` si configurée).
5. On exécute tests / validations avant déploiement.

## Est‑ce associé à la préprod ?
Non, pas exclusivement. Le retrofit peut cibler :
- la production (cas le plus courant : des changements fait manuellement en prod à récupérer dans le repo),
- la préprod (si la source « vérité » est la préprod dans votre workflow),
- ou tout autre org (sandbox, uat, etc.).

Le lien avec « préprod » dépend de votre politique : beaucoup d’équipes choisissent `retrofitBranch = preprod` pour centraliser ces récupérations avant propagation, mais rien n’impose que le retrofit soit toujours fait vers/depuis la préprod.

## Exemples concrets
- Récupérer les layouts et champs ajoutés manuellement en prod :
  - `sourcesToRetrofit: ["CustomField", "Layout"]`
- Ignorer des flexipages de dashboard connues :
  - `retrofitIgnoredFiles` liste les chemins à ignorer après récupération.
- Configurer `retrofitBranch: "preprod"` pour créer/diriger la MR vers la branche préprod.

## Risques & bonnes pratiques
- Risques : fautes de frappe dans `sourcesToRetrofit` (la validation du schéma n’empêche pas les erreurs), récupération qui écrase des travaux locaux, inclusion accidentelle de fichiers non désirés.
- Bonnes pratiques :
  - Tester d’abord sur une branche dédiée.
  - Utiliser `retrofitIgnoredFiles` pour exclure les éléments volatils (dashboards, fichiers generateurs).
  - Revue humaine obligatoire des PRs issues du retrofit.
  - Documenter si le retrofit doit pointer vers la prod ou la préprod (selon process).
  - Automatiser validations/tests dans CI avant merge.

## Où configurer le comportement
- `sourcesToRetrofit` : types à récupérer.
- `retrofitBranch` : branche cible des MR.
- `retrofitIgnoredFiles` : fichiers à ignorer après retrieve.

Souhaitez‑vous que j’ajoute un exemple explicite ou une enum de types courants dans sfdx-hardis.jsonschema.json pour réduire les fautes de frappe ?

--

GitHub Copilot: Je vais ajouter une tâche todo pour tracer cette réponse (quoi: expliquer MR/PR) puis la marquer comme complétée — résultat: todo créée et mise à jour.

Added 1 todo

Completed (3/3) *Expliquer MR/PR*

Progrès : la todo a été ajoutée et marquée complétée. Voici l'explication en français.

MR / PR — définition simple
- PR = Pull Request (terme utilisé surtout sur GitHub et Bitbucket)  
- MR = Merge Request (terme utilisé surtout sur GitLab)  
C’est la même idée : une demande formelle pour fusionner des changements (commits) d’une branche source vers une branche cible. On l’utilise pour la revue de code, l’exécution des pipelines CI, la discussion et l’approbation avant fusion.

Que contient une PR/MR
- Titre et description expliquant l’objectif du changement.  
- Branche source (ex. feature/ma-fonctionnalité) et branche cible (ex. integration, preprod, main).  
- Diffs (les fichiers modifiés/ajoutés/supprimés).  
- Discussions / commentaires ligne par ligne.  
- Assignés / reviewers, labels, milestone, pipelines CI attachés.  
- Statuts requis (ex. tests verts, 1 approbation) avant pouvoir merger.

Workflow typique
1. Créer une branche locale pour la tâche.  
2. Commits locaux — push vers le remote.  
3. Ouvrir une PR/MR contre la branche cible.  
4. CI s’exécute automatiquement (tests, linters, build).  
5. Reviewers commentent, demandent corrections si nécessaire.  
6. Après approbation et CI vert, on merge (ou squash/rebase selon stratégie).  
7. Résolution des conflits si présents, puis fusion finale.

Stratégies de fusion courantes
- Merge commit : conserve l’historique et crée un commit de fusion.  
- Squash : compacte tous les commits de la branche en un seul commit sur la cible.  
- Rebase and merge : réécrit l’historique en plaçant les commits sur la branche cible (plus propre mais modifie l’historique).

Bonnes pratiques (pertinentes pour sfdx‑hardis & retrofit)
- PR/MR petites et atomiques : facilite la revue et le rollback.  
- Exiger CI vert avant merge.  
- Rédiger une description claire (quoi, pourquoi, impact, tests effectués).  
- Lier la PR/MR au ticket (Jira/Azure) si applicable.  
- Utiliser draft/WIP si la PR n’est pas prête.  
- Revue humaine sur les PR issues de retrofit : vérifier que la récupération depuis l’org n’introduit pas d’artefacts indésirables.  
- Utiliser `retrofitBranch` (si configuré) comme branche cible pour centraliser ces changements (ex. `preprod`), puis valider et propager.

Différences pratiques entre plateformes
- GitHub : « Pull Request », support natif de reviewers, required checks, protected branches.  
- GitLab : « Merge Request », mêmes fonctionnalités + intégration CI (GitLab CI) parfois plus poussée selon usage.  
- Bitbucket : « Pull Request », très similaire.

Quand utiliser une PR/MR vs un push direct
- Toujours utiliser une PR/MR pour les modifications partagées, surtout pour : retrofit, changements en production, changements touchant plusieurs équipes.  
- Push direct acceptable uniquement pour corrections locales mineures sur branches non partagées (suivre la politique de l’équipe).

Exemple résumé appliqué à retrofit
- Après retrieve depuis l’org (production ou autre), créer une branche (ex. retrofit/2025-10-25-prod-retrieve).  
- Nettoyer / ignorer les fichiers listés dans `retrofitIgnoredFiles`.  
- Ouvrir une MR/PR ciblant `retrofitBranch` (ex. `preprod`) ou `integration`.  
- Laisser CI s’exécuter, faire la revue, puis merger si OK.

Souhaitez‑vous que je :  
- rédige un modèle de description de MR/PR adapté au workflow retrofit ?  
- ajoute un court paragraphe dans la doc du repo expliquant la procédure recommandée (branch naming, CI checks, reviewers) ?

---

Actions réalisées

- J'ai ajouté une définition listant des types de métadonnées courants à sfdx-hardis.jsonschema.json (nouvelle définition `enum_metadata_types`) — ceci n'impose pas la validation stricte, c'est une référence utile.
- J'ai enrichi la propriété `sourcesToRetrofit` (description + exemples) pour mentionner le format Type ou Type:Name et pointer vers la nouvelle définition.
- J'ai créé un modèle de Pull Request GitHub : PULL_REQUEST_TEMPLATE.md (orienté retrofit, checklist CI/retrofitIgnoredFiles/review).
- J'ai créé un modèle Merge Request GitLab : Retrofit.md.
- J'ai ajouté une courte documentation retrofit.md expliquant la procédure recommandée (naming, CI checks, reviewers, bonnes pratiques).

Où regarder

- Schéma : sfdx-hardis.jsonschema.json — nouvelles définitions & description mises à jour.
- PR template : PULL_REQUEST_TEMPLATE.md
- GitLab MR template : Retrofit.md
- Doc : retrofit.md

Pourquoi j'ai choisi cette approche

- J'ai évité d'imposer un enum strict sur `sourcesToRetrofit` pour rester compatible (certaines équipes utilisent des entrées Type:Name). La définition `enum_metadata_types` sert de référence/guide et pourra être utilisée plus tard pour une validation plus forte si vous le souhaitez.
- Les templates and la doc sont en français (conforme aux échanges), ciblés sur le workflow retrofit.

Prochaines options (je peux faire une ou plusieurs)

- Appliquer l'enum strict sur `sourcesToRetrofit` (breaking change possible) — utile si vous voulez empêcher les fautes de frappe.
- Ajouter un template PR plus générique ou multi-langue (FR/EN).
- Intégrer la doc dans la page d'aide générée ou référence mkdocs (si vous voulez que retrofit.md apparaisse dans le site mkdocs, je peux mettre à jour mkdocs.yml).
- Créer un petit script de vérification local (pre-commit) pour alerter sur les types invalides.

---

allowedOrgTypes

Types of Salesforce Orgs allowed for config & development. If not set, Sandbox Orgs and Scratch Orgs are allowed by default

Sandbox Orgs

Scratch Orgs

devHubAlias
Dev Hub alias, usually DevHub_ProjectName
DevHub_MyClientMyProject

devHubInstanceUrl
Dev Hub instance URL used for authenticating to DevHub from CI jobs
https://login.salesforce.com

devHubUsername
Dev Hub username, used to authenticate to DevHub from CI jobs
cicd-user@myclient.com

instanceUrl
Salesforce instance URL used by CI for deployment or backups
https://myclient.force.com

targetUsername
Salesforce username used by CI for deployment or backups
deployments@myclient.com
🧹 Auto Cleaning

autoCleanTypes
When saving/publishing a User Story, sfdx-hardis can automatically clean the sources before submitting a Pull Request. Select the cleanings that will be automatically applied on your project.

Case Entitlement

Check Permissions

Dashboards

Data.com

Destructive Changes

Flow Positions

Local Fields

List Views Mine

Minimize Profiles

Product Request

Sensitive Metadatas

System Debug

v60

autoRemoveUserPermissions
When your dev sandbox is using the next SF Platform version, sometimes some permissions on Profiles exist on the next version but not the current one. To avoid issues, you can force the removal of such permissions when Saving/Publishing a User Story Example: - EnableCommunityAppLauncher - OmnichannelInventorySync
EnableCommunityAppLauncher
FieldServiceAccess
OmnichannelInventorySync

autoRetrieveWhenPull
Sometimes, SF Cli forgets to pull some metadata updates, like Custom Application for example. sfdx-hardis can automatically retrieve named metadatas to avoid issues. Example: - CustomApplication:MyApp1 - CustomApplication:MyApp2 Works also with full metadata types (ex: CustomApplication)
CustomApplication
🧪 Tests & Coverage

apexTestsMinCoverageOrgWide
Minimum percentage of apex code coverage accepted. 75.0% by default, but if you are on a clean project, it's better to define 80.0, 95.0 or 90.0 😎
75

runtests
WARNING: Use with caution, only in branch scoped config ! Can be a list of test classes if testLevel=RunSpecifiedTests, or a regex if testLevel=RunRepositoryTests
MyTestClass1,MyTestClass2

skipCodeCoverage
WARNING: Use with caution, only in branch scoped config ! Do not check code coverage for a deployment

Disabled

testLevel
WARNING: Use with caution, only in branch scoped config ! You can override default test level for deployments for special use cases, for example when you have SeeAllData=true you can use RunRepositoryTests associated with a regex in runtests option
RunLocalTests
📦 Project

availableProjects
List of business projects that are managed in the same repository. If defined, when creating a new User Story, it will be prompted to the contributor then used to create the git branch name. If a value contains a comma, the left part will be used for key and the right part as label for the users.
sales_cloud
service_cloud
community

projectName
Identifier for the project (can be the client and project)
MyClientMyProject
🌳 Branches

availableTargetBranches
List of git branches that can be used as target for Pull Requests. Contributors will be prompt to select one of these target branch when creating a new User Story A classic example on a project with BUILD & RUN in parallel is to have preprod and integration as available target branches. If defined, makes obsolete the parameter Default Pull Request target branch.
preprod
integration

developmentBranch
When creating a new sfdx-hardis User Story, this git branch is used as base to create the feature/debug sub branch. The merge request will later have this branch as target.
integration

mergeTargets
In branch-scoped config file, declares the list of branches that the current one can have as merge target. For example, integration will have mergeTargets [uat]
preprod

productionBranch
Name of the git branch corresponding to production environment
master

retrofitBranch
Name of the git branch where retrofit merge requests targets to
preprod
🚀 Deployment

customCommandsPosition
Position of custom commands in the menu (first or last)
first

defaultPackageInstallationKey
When generating a new package version protected with password, use this value as default package installation key
hardis

docDeployToCloudflare
Automatically deploy MkDocs HTML documentation from CI/CD Workflows to Cloudflare

Disabled

docDeployToOrg
Automatically deploy MkDocs HTML documentation from CI/CD Workflows to Salesforce org as static resource

Disabled

installPackagesDuringCheckDeploy
If your configuration contains an installedPackages property, activating this option allows you to make sfdx-hardis automatically install packages during the Deployments Check workflow, and not to wait after the merge of the Pull Request.

Enabled

useDeltaDeployment
Defines if sfdx-hardis will deploy in delta from minor to major branches. When active, Delta Deployments allow to deploy only the metadatas in the branch / User Story, and not the full sources of the SFDX project. Note: Even if activated, Delta Deployments will be applied only for Pull Requests from minor (features,hotfixes) to major branches (integration,preprod).

Enabled

useDeltaDeploymentWithDependencies
Also deploy dependencies of the metadatas identified by delta deployment, to avoid broken deployments due to missing dependencies. Example: removed picklist value in a field, that is still used in a record type.

Enabled

useSmartDeploymentTests
Define if Smart Deployment Tests will be activated and run Apex test classes only if metadata that can impact them are present in the branch / User Story. Note: Smart Deployment Tests will be applied only for Pull Requests from minor (features,hotfixes) to major branches (integration,preprod).

Enabled
⚙️ Customization & Advanced

customOrgColors
Custom colors set by VsCode SFDX Hardis

extends
You can base your local sfdx-hardis configuration on a remote config file. That allows you to have the same config base for all your projects
https://raw.githubusercontent.com/worldcompany/shared-config/main/.sfdx-hardis.yml

initPermissionSets
When creating a scratch org, Admin user will be automatically assigned to those permission sets. Example: PS_Admin
MyPermissionSet
MyPermissionSetGroup

sourcesToRetrofit
List of metadata to retrieve for retrofit job
CustomField
Layout
PermissionSet

retrofitIgnoredFiles
When calling hardis:org:retrieve:sources:retrofit, list of files to ignore (discard just after retrieve)
force-app/main/default/applications/MyAppIWantToManageInProduction.app-meta.xml
force-app/main/default/flexipages/MyFlexipageWithDashboards.flexipage-meta.xml
🔔 Notifications & Ticketing

genericTicketingProviderRegex
Regular expression to identify ticket IDs from your ticketing system. Example: ([R|I][0-9]+-[0-9]+) for EasyVista.
([R|I][0-9]+-[0-9]+)

genericTicketingProviderUrlBuilder
URL pattern to build ticket URLs from ticket IDs. Use {ticketId} as placeholder for the ticket ID. Example: https://tickets.mycompany.com/ticket/{ticketId}
https://tickets.mycompany.com/ticket/{ticketId}

jiraHost
Jira host URL (without https://). Example: mycompany.atlassian.net
mycompany.atlassian.net

jiraTicketRegex
Regular expression to identify Jira ticket IDs. Example: (CLOUDITY-[0-9]+)
(CLOUDITY-[0-9]+)

msTeamsWebhookUrl
Url of the Ms Teams channel Web Hook that can be used to send ALL notifications
https://my.msteams.webhook.url

msTeamsWebhookUrlCritical
Url of the Ms Teams channel Web Hook that can be used to send CRITICAL notifications
https://my.msteams.webhook.url

msTeamsWebhookUrlSevere
Url of the Ms Teams channel Web Hook that can be used to send SEVERE notifications
https://my.msteams.webhook.url

msTeamsWebhookUrlWarning
Url of the Ms Teams channel Web Hook that can be used to send WARNING notifications
https://my.msteams.webhook.url

msTeamsWebhookUrlInfo
Url of the Ms Teams channel Web Hook that can be used to send INFO notifications
https://my.msteams.webhook.url

notificationsDisable
List of notifications types to skip sending
METADATA_STATUS
UNUSED_METADATAS

ticketingProvider
Ticketing provider used on the project
JIRA
❓ Other

listViewsToSetToMine
List of ListView items to set to Mine after a delivery (that does not accept value 'Everything')
One item per line

manualActionsFileUrl
URL of the XLS file that contains manual actions to perform before or after a deployment
https://some.sharepoint.com/file.xlsx

newTaskNameRegex
If you define a regular expression, it will be used to validate the name of new User Stories. For example, you can enforce a Jira number in the name with regex '^MYPROJECT-[0-9]+ .*'
^[A-Z]+-[0-9]+ .*

newTaskNameRegexExample
If you activated User Story name validation via RegEx, define an example value that will be displayed to users. Example: 'MYPROJECT-168 Update account status validation rule'
MYPROJECT-123 Update account status validation rule

skipUpdateForceIgnore
Defines if sfdx-hardis will propose to upgrade local .forceignore file

Disabled

skipUpdateGitIgnore
Defines if sfdx-hardis will propose to upgrade local .gitignore file

Disabled

testCoverageNotBlocking
Does not make the deployment job fail if apex tests code coverage is failing

Disabled
🔍 Monitoring

monitoringAllowedSectionsActions
Override list of Setup Audit Trail elements that won't be considered as suspect by monitoring tools

monitoringDisable
List of commands to skip during monitoring jobs
METADATA_STATUS
UNUSED_METADATAS

monitoringExcludeUsernames
List of usernames to exclude while running monitoring commands
deploymentuser@cloudity.com
mc-cloud-user@cloudity.com
📦 Package Management

packageNoOverwritePath
By default, manifest/package-no-overwrite.xml is used, but you could decide to use a different file for specific major branches. In that case, set the path to a custom package-no-overwrite XML file in a branch-scoped sfdx-hardis configuration file.
manifest/package-no-overwrite-main.xml
🍃 Scratch Orgs

scratchOrgInitApexScripts
Apex scripts to call after scratch org initialization. Example: scripts/apex/init-scratch.apex
scripts/apex/init-scratch.apex
scripts/apex/init-custom-settings.apex

scratchOrgDuration
Defines the lifespan of the scratch org in number of days, from 1 to 30
30
🏖️ Sandbox Management

sfdmuCanModify
Instance host name to allow SFDMU to deploy data in a production org
myproject.force.com

sharedDevSandboxes
Set to true if contributors can share dev sandboxes If active, contributors will never be asked to refresh their sandbox metadata, to avoid to overwrite by accident their colleagues work :)

Disabled
🧹 Data & Cleanup

skipMinimizeProfiles
These profiles will not be reformatted by command hardis:project:clean:minimizeprofiles
MyClient Customer Community Login User
MyClientPortail Profile

linterIgnoreRightMetadataFile
Ignore profiles or permission sets
Profile

----

GitHub Copilot: Completed (2/4) *Traduire explication sourcesToRetrofit en français*

Je prépare une procédure complète et pragmatique pour un projet sfdx‑hardis "sans scratch orgs" avec la configuration "medium" (trois branches long‑lived : integration, preprod, master). Résumé puis recommandations détaillées et un extrait de configuration prêt à coller.  

## Contexte/cible
- Pas de scratch orgs → développement sur sandboxes partagées ou dev sandbox par équipe.  
- Branches long‑lived : integration (développement), preprod (validation), master (production).  
- On conserve les options que vous avez déjà activées (delta deploy / smart tests / install packages during check deploy).  

---

## Principes recommandés (haut niveau)
1. Développement sur sandboxes (allowedOrgTypes = ["sandbox"]). Pas de dépendance à DevHub dans le flux quotidien.  
2. Branching :
   - Branches long‑lived : integration (developmentBranch), preprod (retrofitBranch target), master (productionBranch).
   - Feature branches : feature/<ticket>-shortdesc créées depuis `integration`. PR → target `integration`.
   - Promotion : integration → preprod → master. Les rétrofits produits pointent vers `preprod`.
3. CI en deux étapes principales :
   - Check (validate): lint, unit tests, delta plan, install packages (installPackagesDuringCheckDeploy=true), validation de déploiement (sf deploy -c) — ceci sur PR/MR.
   - Process (deploy): après merge vers target (preprod/master) et approbation, exécution du déploiement réel.
4. Retrofit (sauvegarde de métadatas depuis orgs existants) : récupérer depuis prod → branche dédiée → MR vers `preprod` → revue humaine → merge.
5. Nettoyage automatique (autoCleanTypes) activé pour limiter bruit et conflits dans PRs issues de sandboxes.

---

## Paramètres sfdx‑hardis recommandés (explication + valeurs concrètes)
Je fournis d’abord un extrait JSON prêt à insérer dans votre `.sfdx-hardis.yml` local / config, puis j’explique chaque réglage.

Extrait de configuration recommandé (valeurs à adapter si nécessaire) :
{
  "allowedOrgTypes": ["sandbox"],
  "devHubAlias": "",
  "devHubInstanceUrl": "https://login.salesforce.com",
  "devHubUsername": "",
  "instanceUrl": "https://myclient.force.com",
  "targetUsername": "deployments@myclient.com",
  "autoCleanTypes": [
    "destructivechanges",
    "minimizeProfiles",
    "localfields",
    "dashboards",
    "systemDebug"
  ],
  "autoRemoveUserPermissions": [
    "EnableCommunityAppLauncher",
    "OmnichannelInventorySync",
    "FieldServiceAccess"
  ],
  "autoRetrieveWhenPull": [
    "CustomApplication",
    "FlexiPage",
    "Layout"
  ],
  "apexTestsMinCoverageOrgWide": 80.0,
  "testLevel": "RunLocalTests",
  "skipCodeCoverage": false,
  "developmentBranch": "integration",
  "availableTargetBranches": ["preprod","integration"],
  "mergeTargets": ["preprod"],
  "productionBranch": "master",
  "retrofitBranch": "preprod",
  "sourcesToRetrofit": [
    "CustomField",
    "Layout",
    "PermissionSet",
    "CustomApplication",
    "FlexiPage"
  ],
  "retrofitIgnoredFiles": [
    "force-app/main/default/applications/**.app-meta.xml",
    "force-app/main/default/flexipages/**.flexipage-meta.xml",
    "force-app/main/default/dashboards/**"
  ],
  "installPackagesDuringCheckDeploy": true,
  "useDeltaDeployment": true,
  "useDeltaDeploymentWithDependencies": true,
  "useSmartDeploymentTests": true,
  "packageNoOverwritePath": "manifest/package-no-overwrite-main.xml"
}

Notes et justification champ par champ :
- allowedOrgTypes: ["sandbox"] — explicite : pas de scratch orgs, évite confusions dans UX.  
- devHubAlias/devHubUsername: laissez vide si vous n’utilisez pas DevHub (utile uniquement si plus tard vous introduisez scratch orgs).  
- autoCleanTypes: activez les nettoyages qui réduisent le bruit lors de PRs. Recommandation minimale : 
  - destructivechanges : pour éviter d’envoyer des destructions non voulues.  
  - minimizeProfiles : normalise profiles et réduit diffs.  
  - localfields : nettoie champs locaux inutilisés.  
  - dashboards : dashboards souvent générés / instables — nettoyez ce qui est nécessaire.  
  - systemDebug : retire debug/system traces.  
- autoRemoveUserPermissions: lister les permissions liées à une version supérieure qui poseraient problème en sandbox. Exemple fourni.  
- autoRetrieveWhenPull: récupérer automatiquement types oubliés par sf cli (CustomApplication, FlexiPage, Layout) — réduit les oublis.  
- apexTestsMinCoverageOrgWide: 80% — bon compromis pour un projet mature; si le code est ancien et sale, commencer à 75 puis durcir.  
- testLevel: RunLocalTests — cadence de tests raisonnable pour la majorité des déploiements; n’utiliser RunSpecifiedTests que pour cas spéciaux.  
- skipCodeCoverage: false — garder la vérification par défaut (sauf raison business forte).  
- developmentBranch: integration — vos devs branchent depuis ici.  
- availableTargetBranches: preprod + integration — proposer ces cibles dans UI/creation de user story.  
- mergeTargets: integration → preprod (déclare où integration peut merger).  
- retrofitBranch: preprod — centraliser les récupérations issues de production vers `preprod`.  
- sourcesToRetrofit: types prioritaires à récupérer depuis la prod ; adaptez selon ce que vous voyez souvent modifié manuellement.  
- retrofitIgnoredFiles: ignorer patterns de fichiers volatils (dashboards, flexipages complexes) ; utilisez glob pour être sûr d’exclure automatiquement.  
- installPackagesDuringCheckDeploy: true — installez packages lors de la validation (utile si CI doit valider déploiements incluant nouvelles dépendances).  
- useDeltaDeployment & withDependencies: activés — vous réduisez la fenêtre de friction en ne déployant que ce qui change; withDependencies évite erreurs de dépendances manquantes.  
- useSmartDeploymentTests: true — lancez uniquement les tests nécessaires pour accélérer CI sur PRs mineurs.  
- packageNoOverwritePath: si vous avez manifest personnalisés pour branches majeures, pointez les ici.

---

## Workflow CI/branches + rétrospective pratique
1. Développement local / sandbox:
   - Créer branche: feature/JIRA-123-short-desc depuis `integration`.
   - Commits, push, ouvrir PR → target `integration`.
2. PR pipeline (check):
   - Lint, tests unitaires, code coverage.
   - Génération delta et plan de déploiement (simulate deploy).
   - Installer packages nécessaires (si présents).
   - Si PR vert et reviews OK → merge dans `integration`.
3. Promotion vers préprod:
   - Lorsque `integration` contient un lot validé (sprint), on ouvre PR `integration` → `preprod`. CI exécute validation plus exhaustive (intégration / tests end‑to‑end) et éventuellement deployment to preprod in a dedicated job.
4. Rétrofit / récupération depuis production:
   - Si vous identifiez dans prod un changement manuel, exécutez retrieve depuis prod, nettoyez, créer branche retrofit/DATE-prod-what, ouvrir MR vers `preprod`.
   - Checklist: appliquer `retrofitIgnoredFiles`, reviewer humain, CI validation (simulate).
5. Déploiement en production:
   - Après validation en `preprod`, PR / merge `preprod` → `master` (production). CI exécute le Process deploy réel. Appliquer release gating (approvals) avant la fusion.
6. Tests & smart test behaviour:
   - PRs mineurs: SmartDeploymentTests limiteront les tests exécutés.
   - PRs majeurs -> exécuter RunLocalTests ou plus strict selon la branche (pour preprod/master, exécuter davantage).

---

## Retrofits — procédure détaillée (rappel opérationnel)
- Commande pour retrieve (exemple) :
  sf hardis:org:retrieve:sources:retrofit --types CustomField,Layout,PermissionSet --targetusername <PROD_ALIAS>
- Nettoyage : appliquer `retrofitIgnoredFiles` et vérifier diffs.
- Branching : créer branch `retrofit/<yyyy-mm-dd>-prod-desc`.
- Template PR/MR : remplir le template que nous avons ajouté (.github/PULL_REQUEST_TEMPLATE.md).
- Revue : au moins 1 reviewer tech + 1 responsable produit si impact fonctionnel.
- Merge : après CI vert et approbation, merge vers `preprod`.

---

## Autres recommandations opérationnelles
- Secrets & CI : stocker `targetUsername` credentials (JWT key, sfdx auth) dans secrets CI, jamais en repo.  
- Protections de branches : protéger `preprod` et `master` (required status checks, required approvers).  
- Logs & monitoring : activer notifications (msTeamsWebhookUrl etc.) pour alertes de déploiement/erreur.  
- Documentation : ajouter retrofit.md (je l’ai créé) et référencer dans README / onboarding.  
- Formation équipe : organiser court atelier pour montrer retrofit & PR workflow — réduit erreurs.

---

## Résumé et décision à appliquer maintenant (actionables)
1. Set `allowedOrgTypes: ["sandbox"]` dans votre config si ce n’est pas déjà fait.  
2. Appliquez l’extrait de configuration ci‑dessus (ajustez devHub blank si non utilisé).  
3. Vérifiez les `retrofitIgnoredFiles` et `sourcesToRetrofit` pour couvrir vos artifacts instables.  
4. Activez protections de branches (`preprod`,`master`) et required CI checks.  
5. Utilisez les templates PR/MR ajoutés et la doc retrofit.md comme processus standard.  

Souhaitez‑vous que :
- je génère un patch concret pour insérer l’extrait proposé dans sfdx-hardis.jsonschema.json ou un exemple `.sfdx-hardis.yml` ?  
- je crée une checklist de revue MR/PR plus détaillée (ex : tests à lancer manuellement, personnes à notifier) adaptée à votre équipe ?

---

## Procédure recommandée : Retrofit (récupération de métadatas depuis un org)

Cet article décrit la procédure recommandée pour effectuer un retrofit (récupération de métadatas depuis un org existant) et l'intégrer proprement dans le dépôt.

1) Préparer la récupération
- Définir les types à récupérer dans `config/sfdx-hardis.jsonschema.json` -> `sourcesToRetrofit` ou les préciser au moment de l'appel.
- Vérifier `retrofitIgnoredFiles` pour exclure les fichiers volatils (dashboards, générés automatiquement).

2) Lancer la récupération
- Exemple :
  `sf hardis:org:retrieve:sources:retrofit --types CustomField,Layout,PermissionSet --targetusername <org>`

3) Créer une branche dédiée
- Nom recommandé : `retrofit/<yyyy-mm-dd>-<org>-<courte-description>` (ex : `retrofit/2025-10-25-prod-layouts`).

4) Nettoyer les artefacts
- Supprimer ou ignorer les fichiers listés dans `retrofitIgnoredFiles`.
- Vérifier les modifications et corriger les éléments non désirés.

5) Ouvrir une PR/MR
- Utiliser le template `PULL_REQUEST_TEMPLATE.md` (GitHub) ou le template MR GitLab `Retrofit`.
- Cibler la branche indiquée par la politique (souvent `preprod` ou `integration`).

6) CI & revue
- Attendre que la CI passe (tests, lint). Ne pas merger si la CI échoue.
- Demander une revue humaine : vérifier que la récupération n'introduit pas d'artefacts non souhaités.

7) Fusion et propagation
- Après merge, suivre la politique de propagation (ex : de `preprod` -> `integration` -> `production`).

Bonnes pratiques
- Faire des PR/MR petites et atomiques.
- Documenter le ticket lié.
- Préférer la revue humaine pour les changements issus d'une récupération depuis la production.
