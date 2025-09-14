
# sfdx-hardis 6
-----

As a DevOps operator, leveraging this comprehensive suite of `sfdx-hardis` commands allows for the creation of a highly structured, automated, and quality-driven delivery process. Here’s how I would organize a project and orchestrate the delivery of tasks from development to production.

My approach is built on four key phases: **Scaffolding**, the **Developer Workflow**, the **Automated CI/CD Pipeline**, and periodic **Auditing**.

-----

## Phase 1: Project & Org Scaffolding (The Foundation)

The goal here is to standardize every project from day one, ensuring that all CI/CD configurations, authentication, and team-wide settings are established correctly before any development begins.

1.  **Initialize the Project:** A tech lead or the first developer on a new project runs `sf hardis:project:create`. This is the cornerstone command that:

      * Scaffolds a standard SFDX project structure.
      * Copies default CI/CD pipeline files (e.g., `.gitlab-ci.yml`).
      * Creates the essential `config/.sfdx-hardis.yml` file with smart defaults, like `autoCleanTypes`, to enforce code hygiene from the start.

2.  **Configure CI/CD Authentication:** For each major branch that corresponds to a long-lived org (e.g., `integration`, `uat`, `main`), we run `sf hardis:project:configure:auth`. This:

      * Associates a Git branch with a target Salesforce org.
      * Generates the necessary JWT certificates and keys for passwordless CI/CD authentication.
      * Establishes the "merge path" (e.g., `integration` can merge to `uat`).

3.  **Prepare the Scratch Org Pool (if applicable):** For projects using scratch orgs, we'll set up a scheduled pipeline job that periodically runs `sf hardis:scratch:pool:refresh`. This ensures a ready supply of pre-built, initialized scratch orgs, dramatically speeding up the start of any new development task.

-----

## Phase 2: The Developer's Daily Workflow (The Loop)

This is the highly repeatable, guided process every developer follows for every user story. The goal is maximum efficiency and minimum friction, with quality built-in.

The mindset is captured in this diagram:

```mermaid
graph TD
    subgraph " "
        A["Start: New User Story<br/><br/>`sf hardis:work:new`"] --> B{Develop & Configure};
        B --> C["Pull UI Changes<br/><br/>`sf hardis:scratch:pull`"];
        C --> D["Commit Changes<br/><br/>`git add .`<br/>`git commit`"];
        D --> E{More Changes?};
        E -- Yes --> B;
        E -- No --> F["Finalize & Push<br/><br/>`sf hardis:work:save`"];
        F --> G["Create Merge Request<br/>(URL provided by previous command)"];
    end
    style F fill:#9f9,stroke:#333,stroke-width:2px
    style A fill:#9cf,stroke:#333,stroke-width:2px
```

**Workflow Steps:**

1.  **Start a New Task:** The developer begins by running `sf hardis:work:new`. This single command is a powerful orchestrator that:

      * Creates a new, correctly named Git branch (e.g., `features/dev/PROJ-123`).
      * Provisions a fresh, fully initialized scratch org by fetching one from the pool or creating a new one.

2.  **Develop:** The developer performs their coding and configuration work in the provisioned org and their local IDE.

3.  **Sync & Commit:** As work progresses, the developer uses `sf hardis:scratch:pull` to bring any declarative changes made in the UI into their local files, followed by standard `git commit` commands to save their progress.

4.  **Finalize for Review:** When the task is complete, the developer runs the flagship `sf hardis:work:save` command. This is the magic step that prepares the branch for review and automates several tedious tasks:

      * It runs **`sfdx-git-delta`** to automatically generate an accurate `package.xml` and `destructiveChanges.xml` based *only* on what changed.
      * It performs **automated code cleaning** based on the `autoCleanTypes` in the project config (e.g., `minimizeprofiles`, `flowpositions`).
      * It commits these generated and cleaned files and **pushes the branch** to the remote repository.
      * Finally, it provides the developer with the direct URL to **create the Merge/Pull Request**.

-----

## Phase 3: The Automated CI/CD Pipeline (The Quality Gate)

This process is triggered the moment a developer creates a Merge Request. It's fully automated, providing fast feedback and ensuring nothing broken gets merged.

Here's the CI/CD pipeline mindset:

```mermaid
graph TD
    subgraph " "
        A["Dev creates Merge Request"] --> B("CI Pipeline Triggered");
        subgraph "Validate Stage (on MR branch)"
            B --> C["Lint Code<br/><br/>`sf hardis:project:lint`"];
            C --> D["Validate Deployment<br/><br/>`sf hardis:project:deploy:smart --check`"];
        end
        D --> E{Validation OK?};
        E -- No --> F["Post Failure Comment on MR<br/><br/>(via `deploy:smart`)"];
        E -- Yes --> G["Post Success & Flow Diff on MR<br/><br/>(via `deploy:smart`)"];
        G --> H["Human merges MR"];
        H --> I("CI Pipeline Triggered on Target Branch");
        subgraph "Deploy Stage (on target branch)"
            I --> J["Deploy to Org<br/><br/>`sf hardis:project:deploy:smart`"];
        end
        J --> K{Deploy OK?};
        K -- Yes --> L["Notify Team (Slack/Jira)<br/><br/>(via `deploy:smart`)"];
        K -- No --> M["Notify Team of Failure<br/><br/>(via `deploy:smart`)"];
    end
    style D fill:#9cf,stroke:#333,stroke-width:2px
    style J fill:#9f9,stroke:#333,stroke-width:2px
```

**Pipeline Stages:**

1.  **Validation (on Merge Request):**

      * **Lint:** The pipeline first runs `sf hardis:project:lint` to check for code quality and style issues across the entire repository. This is a fast, initial quality gate.
      * **Validate Deploy:** The core of this stage is `sf hardis:project:deploy:smart --check`. This command is brilliant for CI because it:
          * Uses **delta deployment** logic to only validate the actual changes.
          * Employs **smart test selection** to skip running Apex tests if the changed metadata is non-impactful (e.g., only Layouts and Reports), saving enormous amounts of time.
          * Posts a detailed **comment back to the Merge Request** with the validation result, including the incredible **visual Flow Git diffs**.

2.  **Deployment (on Merge to Target Branch):**

      * Once the MR is validated and approved, it's merged. This triggers the deployment pipeline.
      * The pipeline runs the exact same command, `sf hardis:project:deploy:smart`, but *without* the `--check` flag. This performs the actual deployment to the target org (e.g., Integration, UAT).
      * Upon success or failure, the command automatically sends notifications to configured channels like **Slack, MS Teams, and Jira**, keeping the entire team informed.

-----

## Phase 4: Auditing and Maintenance (Keeping it Healthy)

To prevent technical debt and ensure long-term project health, a tech lead or a scheduled pipeline will periodically run a suite of auditing and fixing commands.

  * **Security Audits:** Run `sf hardis:project:audit:callincallout` and `sf hardis:project:audit:remotesites` quarterly to review all external integration points.
  * **Technical Debt Management:** Run `sf hardis:project:audit:apiversion --fix` after every Salesforce release to keep the codebase modern. Run `sf hardis:lint:unusedmetadatas` to identify and remove dead code.
  * **Best Practice Enforcement:** For mature projects, `sf hardis:project:convert:profilestopermsets` can be used to facilitate the move to a more modern, Permission Set-based security model.

-----

The `sfdx-hardis` suite provides a powerful, multi-layered approach to verifying the coherence of packages and preventing "missing artifact" errors. It addresses this crucial need in three distinct ways:

### ## Proactive Coherence via Automated Manifest Generation

This is the most powerful method because it **prevents errors before they happen**.

The core of this strategy is the `sf hardis:work:save` command. Instead of relying on a developer to manually update the `package.xml`, this command uses the `sfdx-git-delta` plugin to analyze the Git history. It automatically generates a `package.xml` and `destructiveChanges.xml` that perfectly match all the files that were added, modified, or deleted in the branch.

This ensures **perfect coherence** between the source files being committed and the manifest that describes them, virtually eliminating the common error of forgetting to add a new component to the package.

***
### ## Specific Auditing for Missing Permissions

This method actively **hunts for a common type of missing artifact**: permissions.

The `sf hardis:lint:access` command is a specialized audit tool that scans your project to ensure every Apex Class and Custom Field is referenced in at least one Profile or Permission Set. This directly addresses the "missing artifact" problem where a new field or class is created but no one is given access to it, which would otherwise only be caught during testing or in production.

***
### ## Ultimate Verification via Deployment Simulation

This is the final and most comprehensive check, using the **Salesforce platform itself as the source of truth**.

Commands like `sf hardis:project:deploy:smart --check` or `sf hardis:project:deploy:validate` perform a deployment simulation against a target org. The Salesforce platform's own dependency checker will run and fail if *any* dependent artifact is missing (e.g., a Custom Field referenced in a Layout is not included). The `sfdx-hardis` wrappers enhance this by providing clearer error messages and helpful tips to resolve these dependency issues quickly.

In summary, `sfdx-hardis` provides a robust strategy for package coherence by:
1.  **Preventing** missing artifacts by automatically generating manifests (`work:save`).
2.  **Auditing** for specific, common omissions like permissions (`lint:access`).
3.  **Verifying** the complete package against the ultimate authority—the Salesforce org itself (`deploy:smart --check`).
