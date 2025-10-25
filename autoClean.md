
Voici un résumé précis et pragmatique — basé sur le code — de ce que fait exactement la fonctionnalité autoClean (ce qui est exécuté automatiquement lors d'un `hardis:work:save` si vous n'utilisez pas `--noclean`).

## Rappel rapide : déclenchement
- autoClean est déclenché par la commande `sf hardis:work:save` (sauf `--noclean`).
- `Save` appelle `CleanReferences.run(['--type','all'])` : celui‑ci lit `config.autoCleanTypes` (ou vous demande quelles opérations faire) et exécute chaque nettoyage correspondant.
- Après nettoyage, les fichiers modifiés sont ajoutés et commités automatiquement (si git est activé).

## Nettoyages automatiques principaux (valeurs par défaut)
Lors de la création d’un projet, `autoCleanTypes` est initialisé par défaut à :
- `destructivechanges`
- `flowPositions`
- `minimizeProfiles`

Voici ce que fait chacun en détail.

### minimizeProfiles
Fichier(s) impliqué(s)
- minimizeprofiles.ts
- profileUtils.ts

Qu’est‑ce qui est modifié

- Supprime entièrement ces nœuds XML si présents dans un fichier `<Profile>.profile-meta.xml` :
  - classAccesses
  - customMetadataTypeAccesses
  - externalDataSourceAccesses
  - fieldPermissions
  - objectPermissions
  - pageAccesses
- Pour ces nœuds, on ne garde que certaines valeurs « par défaut » (filtre) :
  - applicationVisibilities → ne conserve que les entrées avec visible = false
  - recordTypeVisibilities → ne conserve que les entrées default = true (ou personAccountDefault = true)
  - userPermissions → conserve uniquement enabled = false (et pour Admin.profile on conserve tout)
- Supprime aussi des userPermissions listés dans la config `autoRemoveUserPermissions`.
- Écrit le fichier profile modifié si des changements ont eu lieu.
- Signale un avertissement global (affiche une note après nettoyage) pour vous inciter à vérifier que les permissions supprimées sont bien présentes sur des Permission Sets.

Contrôles / configuration

- `minimizeProfilesNodesToRemove` (dans `.sfdx-hardis.yml`) peut remplacer la liste des nœuds à supprimer.
- `skipMinimizeProfiles` : liste de noms de profils à ignorer.
- `autoRemoveUserPermissions` : liste de permissions utilisateur à supprimer explicitement.

Attention

- Risque pour les projets existants avec profils « riches » : activez/désactivez selon vos contraintes (le message de création du projet le mentionne).

### flowPositions

Fichier impliqué
- flowpositions.ts

Qu’est‑ce qui est modifié

- Pour chaque flow Auto‑Layout (détecté par `<stringValue>AUTO_LAYOUT_CANVAS</stringValue>` dans `*.flow-meta.xml`), remplace :
  - `<locationX>…</locationX>` → `<locationX>0</locationX>`
  - `<locationY>…</locationY>` → `<locationY>0</locationY>`
- But : réduire les conflits de positionnement visuel. Les flows Auto‑Layout restent utilisables.

### destructivechanges

Implémentation

- Partie de `CleanReferences` qui lit `manifest/destructiveChanges.xml` (ou un XML passé en paramètre) et construit une liste `deleteItems`.
- Génère un fichier JSON temporaire à partir de template.txt en y insérant les membres à supprimer.

Qu’est‑ce qui est modifié

- Supprime les fichiers sources listés dans `destructiveChanges.xml` (par type). Exemples : CustomField, CustomObject, etc.
- Nettoie `package.xml` (retire les entrées pointées pour suppression).
- Supprime aussi les fichiers liés (ex. pour CustomField il supprime le fichier de champ et les traductions ; supprime les références dans recordTypes, etc.) — code dans `manageDeleteCustomFieldRelatedFiles`.

### listViewsMine (nom interne `listViewsMine`)

Fichier
- listviews.ts

Qu’est‑ce qui est modifié

- Parcourt `**/*.listView-meta.xml`.
- Si `ListView.filterScope` vaut `'Mine'`, remplace par `'Everything'`.
- Enregistre le chemin relatif du fichier modifié dans la config `project.listViewsToSetToMine` (pour garder trace et éventuellement reparer côté org).
- But : éviter des erreurs de déploiement quand la portée « Mine » bloque.

### sensitiveMetadatas

Fichier
- sensitive-metadatas.ts

Qu’est‑ce qui est modifié
- Recherche fichiers `.crt` et remplace leur contenu par un message indiquant que le certificat a été masqué :
  - Remplace le contenu réel par un texte "CERTIFICATE HIDDEN BY SFDX‑HARDIS…"
- But : ne pas stocker les certificats/bruts sensibles en clair dans Git.

### systemDebug

Fichier
- systemdebug.ts

Qu’est‑ce qui est modifié

- Parcourt les fichiers Apex (`*.cls`, `*.trigger`) :
  - Par défaut : commente les lignes contenant `System.debug` (préfixe `//`) sauf si la ligne contient `NOPMD`.
  - Avec flag `--delete` : supprime totalement les lignes contenant `System.debug`.
- But : enlever les debug provenant du développement.

### template‑based cleaners (dashboards, datadotcom, localfields, caseentitlement, entitlement, productrequest, v60, etc.)
Fichiers / mécanisme
- references.ts
- filter-xml-content.ts
- Templates JSON dans `defaults/clean/*.json` (ex. `dashboards.json`, `localfields.json`, `v60.json`)

Qu’est‑ce qui est modifié

- Pour ces types, `CleanReferences` construit (à partir du template JSON par défaut ou d’un fichier JSON fourni) une configuration de filtrage.
- `FilterXmlContent` parcourt les fichiers ciblés et supprime des nœuds XML correspondant aux règles `exclude_list` du template (par tag et par identifiant).
- Exemple d’usage : supprimer références à des utilisateurs codés en dur dans des dashboards, retirer champs/objets locaux référencés, rendre le metadata compatible v60, etc.
- Ces nettoyages sont configurés par template et peuvent être étendus/overridés.

### cleanXmlPatterns (CleanXml

Fichier
- xml.ts (commande `clean:xml`)

Qu’est‑ce qui est modifié

- Supprime des éléments XML selon des paires globPattern + xpath.
- Deux modes :
  - Vous fournissez `--globpattern` et `--xpath` en ligne de commande.
  - Ou la commande utilise `cleanXmlPatterns` défini dans `.sfdx-hardis.yml` (appliqué automatiquement par `save` si présent).
- Très utile pour règles ad‑hoc complexes (ex : supprimer un bloc entier si un sous‑élément contient X).

## Autres nettoyages disponibles (non toujours activés par défaut)

- `standarditems` : supprime dossiers d'objets standards vides ou champs standards récupérés.
- `manageditems` : supprime fichiers appartenant à un namespace managé (avec protection si dossier contient items locaux).
- `hiddenitems` : supprime fichiers commençant par `(hidden)` (ex. artefacts temporaires LWC/Aura).
- `emptyitems` : supprime fichiers XML vides pour certains types (globalValueSetTranslation, standardValueSet, sharingRules).
- `orgmissingitems` : compare avec un org cible / package.xml et retire références (ex. dans `reportType`).
- Et d'autres templates listés dans clean.

## Où configurer / comment désactiver

- `.sfdx-hardis.yml` (niveau `project` ou `branch`) — propriétés utiles :
  - autoCleanTypes: liste des types à exécuter automatiquement.
  - minimizeProfilesNodesToRemove: liste des nœuds de profil à supprimer (remplace le défaut).
  - skipMinimizeProfiles: liste de profils à ignorer.
  - autoRemoveUserPermissions: liste des userPermissions à retirer automatiquement.
  - cleanXmlPatterns: liste de { globPattern, xpaths } pour `CleanXml`.
  - listViewsToSetToMine: liste (mise à jour) des listviews modifiés.
- Si vous ne voulez pas de nettoyage automatique lors d’un `save`, utilisez `sf hardis:work:save --noclean`.

## Recommandations rapides (pratique)

- Si vous activez `minimizeProfiles` sur un projet avec des profils contenant beaucoup de droits, faites une passe manuelle d’audit avant d’activer en CI (ou excluez `minimizeProfiles`).
- Commit/PR : `save` commit automatiquement les modifications de nettoyage — vérifiez le diff avant de créer la MR.
- Pour règles spécifiques non couvertes par les templates, utilisez `clean:xml` avec un xpath + glob (vous pouvez l’ajouter ensuite dans `cleanXmlPatterns`).

---

Si vous voulez, je peux :
- Lister exactement les valeurs actuelles de `autoCleanTypes` dans votre `.sfdx-hardis.yml` (je peux l’ouvrir et la lire).
- Générer un petit guide en français avec exemples `.sfdx-hardis.yml` pour activer/désactiver chaque nettoyage (et suggestions de sécurité pour `minimizeProfiles`).
- Auditer un ou deux fichiers (par exemple un profil ou un flow) et montrer un "avant/après" simulé du nettoyage. Lequel préférez‑vous ?
