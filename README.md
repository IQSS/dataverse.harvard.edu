# dataverse.harvard.edu

Development and operations work that is **specific to the [Harvard Dataverse Repository](https://dataverse.harvard.edu)** (HDV), plus the custom code and configuration that run it.

The IQSS Dataverse team uses this repository to track the work that Dataverse developers **scope, size and complete** for the Harvard installation. Planning happens on the [IQSS project board](https://github.com/orgs/IQSS/projects/34).

---

## What belongs here

| Put it here | Put it somewhere else |
|---|---|
| Bugs, configuration or performance problems seen on **dataverse.harvard.edu** | Bugs or features for **Dataverse software in general** → [IQSS/dataverse](https://github.com/IQSS/dataverse/issues) |
| Deploying releases, external tools, previewers and metadata blocks to Harvard Dataverse | Curation, support and policy work by the curation team → [IQSS/dataverse-HDV-Curation](https://github.com/IQSS/dataverse-HDV-Curation) |
| Harvesting clients, migrations and collection setups for HDV | Questions from depositors or users → support@dataverse.harvard.edu |
| Production stability, audits, DevOps tasks and data fixes | |
| HDV work for grants and partners (for example NIH GREI, NIH CAFE, HEAL) | |

If an HDV problem is caused by the Dataverse software itself, open the fix in [IQSS/dataverse](https://github.com/IQSS/dataverse/issues). Then keep a short issue here that links to it and tracks the Harvard rollout.

---

## Opening an issue

Developers need enough detail to **size** the work. Please include:

1. **What and where.** Describe the problem or request, with links to the affected dataset, collection or page on dataverse.harvard.edu.
2. **Why it matters.** Who is affected (users, curation, support, a partner or grant) and how urgent it is. Add any deadline.
3. **Steps to reproduce**, for bugs. Include what you expected and what happened, plus screenshots or error messages.
4. **Done when.** Say what has to be true for the issue to be closed.
5. **Related issues.** Link any issues in IQSS/dataverse, HDV-Curation or this repository.

> **Note:** don't include passwords, API tokens, personal data about users, or anything that shouldn't be shared.

---

## How work moves

```
New issue → Needs Scoping → Size: Queued → sized (Size: N) → FY## Sprint N
         → Status: Development → Status: Code Review → Status: QA → closed
```

| Step | Labels | Who |
|---|---|---|
| Triage and scoping | `Needs Scoping`, `bklog: NeedsDiscussion`, `question` | Associate Director of Data Curation and the development lead |
| Ready to size | `Size: Queued`, `ready for estimation` | Development team |
| Sized | `Size: 0.5`, `3`, `10`, `20`, `30`, `33`, `80`, `130`, `210`: share of a sprint, larger is more work | Development team |
| Scheduled | `FY## Sprint N` (two-week sprints), `FY## Roadmap`, `FY## Priority`, quarter milestones such as `FY27Q2` | Planning meeting |
| In progress | `Status: This/Next Sprint`, `Status: Development`, `Status: Code Review`, `Status: QA`, `Status: Needs Input`, `Waiting` | Assignee |
| Release work | `Release`, plus a version milestone such as `6.14` | Release team |

The fiscal year runs **July to June**: Q1 is July–September, Q2 October–December, Q3 January–March and Q4 April–June.

### Other useful labels

- **Kind of work:** `bug`, `enhancement`, `Type: Feature`, `Performance`, `Support`, `Support: prod. data corruption`
- **Area:** `Feature: Harvesting`, `Feature: External Tool`, `Feature: Large Data Support`, `Feature: Large Data Upload`, `Feature: Metrics and Reporting`, `Feature: Publishing`, `Feature: Compliance`, `Feature: Collections`, `Metadata Block`, `UX & UI`, `ops: User Accounts`
- **Impact:** `Curation & Support Impact`, `Curation for Harvard Collection`, `Community Collaborations`
- **Projects and grants:** `NIH GREI` / `GREI 2`–`GREI 7` / `GREI Year 5`, `NIH CAFE`, `Project: HDV SPA Rollout`, `Project: Croissant`

---

## Recurring issues

- **Ongoing DevOps/Prod. support tasks** opens automatically every two weeks for miscellaneous systems work.
- **Release X.Y** issues are created for each Dataverse release: deploy to demo.dataverse.org, test the release candidate with the curation and support teams, then deploy to dataverse.harvard.edu.
- **Production stability:** master issues track work on server crashes, performance and rate limits.

---

## What's in this repository

| Folder | Contents |
|---|---|
| [customization](customization) | Harvard Dataverse homepage, header, footer, stylesheet, logo and analytics code |
| [metadatablocks](metadatablocks) | Custom metadata blocks used on HDV (for example CAFE, CIESIN, 3D, MORU, NDR, SAEF and review rubrics) |
| [scripts](scripts) | Operational scripts: Data Curation Tool and Open OnDemand external tool setup, Make Data Count log processing, DataCite harvesting, handles, compliance reports |
| [util/python](util/python) | Python examples for creating datasets, direct upload and publishing |
| [doc/globus](doc/globus) | User guides for uploading and downloading large data with Globus |
| [performance](performance) | Performance results for each release (Locust load tests, query counts, reindex timings) |
| [src/main/resources/db/migration](src/main/resources/db/migration) | HDV-specific database migrations |
| [setup-harvard.sh](setup-harvard.sh) | Harvard installation setup script |

---

## Related resources

- Harvard Dataverse Repository: https://dataverse.harvard.edu
- Support site: https://support.dataverse.harvard.edu
- Dataverse software: [IQSS/dataverse](https://github.com/IQSS/dataverse) · [Dataverse Guides](https://guides.dataverse.org)
- Curation team repository: [IQSS/dataverse-HDV-Curation](https://github.com/IQSS/dataverse-HDV-Curation)
- Project board: https://github.com/orgs/IQSS/projects/34

## Contact

Harvard Dataverse Repository support: support@dataverse.harvard.edu
