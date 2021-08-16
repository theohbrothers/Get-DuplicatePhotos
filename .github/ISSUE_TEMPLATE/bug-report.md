---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''
---

## Bug

State the unexpected behavior in one sentence.

## Expectation

State the expected behavior in one sentence.

## Discussion

Describe the unexpected behavior.

## Environment

**Output of Configuration**

For example:

```powershell
Configuration:
dryRun: 1
notesdestpath: C:\temp\notes
targetNotebook: test
usedocx: 2
keepdocx: 2
docxNamingConvention: 1
prefixFolders: 1
medialocation: 1
conversion: markdown-simple_tables-multiline_tables-grid_tables+pipe_tables-fenced_code_attributes-inline_code_attributes-fenced_code_attributes
headerTimestampEnabled: 1
keepspaces: 1
keepescape: 2
newlineCharacter: 2
```

**Output of `$PSVersionTable`**

For example:

```powershell
PS > $PSVersionTable

Name                           Value
----                           -----
PSVersion                      7.1.3
PSEdition                      Core
GitCommitId                    7.1.3
OS                             Linux 4.15.0-29-generic #31-Ubuntu SMP Tue Jul 17 15:39:52 UTC 2018
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```
