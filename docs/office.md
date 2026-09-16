# Office Applications

Curi*OS* ships a productivity set for notes, documents, and project work. Extra
office suites, email, CRM/ERP shortcuts, and conferencing apps can be enabled
from **Curi*OS* Manager**.

## Default Applications

These applications are installed when the office module is enabled (the default):

- **Obsidian**: A local-first knowledge base and markdown editor.
- **Joplin**: An open-source notes app with synchronization support.
- **Evince**: A document viewer for PDF and PostScript.
- **Xournal++**: Handwriting and annotation, including PDF markup.
- **Basecamp**: A desktop shortcut to [Basecamp](https://basecamp.com/) project
  management by 37signals.

## Enable or disable office apps

You can install extra office applications via the **Curi*OS* Manager**:

1. Open `curios-manager` (Shortcut: `Super+Return`).
2. Go to the `Applications` menu, then `Install/uninstall CuriOS Apps` menu.
3. Search for `(curios.desktop) office` or a specific app name.
4. Toggle the application options that you need (Space bar).
5. Press Enter to Save and `curios-manager` will handle the installation.

From a terminal, you can do the same with `curios-update`. For example, to
install LibreOffice:

```bash
sudo curios-update --update-module curios.desktop.office.libreoffice.enable true && \
sudo curios-update --update
```

## Office suites and documents

Applications that you can install:

- **LibreOffice**: Full open-source office suite (Writer, Calc, Impress, and more).
- **OnlyOffice Desktop Editors**: Desktop editors compatible with Microsoft Office
  formats. Available on amd64 only.
- **Calibre**: E-book library manager and converter.
- **Thunderbird**: Mozilla email, calendar, and contacts client.

Evince and Xournal++ are enabled by default. You can disable them from the same
modules menu if you prefer another viewer or annotation tool.

## Microsoft 365 web apps

Curi*OS* can add desktop shortcuts for Microsoft 365 in the browser (a Microsoft
account / subscription is required):

- **Word**: `curios.desktop.office.ms.office365.word.enable`
- **Excel**: `curios.desktop.office.ms.office365.excel.enable`
- **PowerPoint**: `curios.desktop.office.ms.office365.powerpoint.enable`

## Project management

- **Basecamp** is enabled by default and opens the 37signals sign-in page. You
  can point the shortcut at your workspace URL:

  ```bash
  sudo curios-update --update-module curios.desktop.office.projects.basecamp.baseUrl "3.basecamp.com/0123456/" && \
  sudo curios-update --update
  ```

- **Basecamp CLI**: official command-line interface
  (`curios.desktop.office.projects.basecamp.cli`).
- **Jira**: Atlassian Jira Cloud desktop shortcut. Set your company domain
  before or after enabling it:

  ```bash
  sudo curios-update --update-module curios.desktop.office.projects.jira.baseUrl "mycompany.atlassian.net" && \
  sudo curios-update --update-module curios.desktop.office.projects.jira.enable true && \
  sudo curios-update --update
  ```

## CRM and ERP web apps

These options add a desktop shortcut that opens your tenant in the browser.
Replace the default URL with your own domain:

- **Salesforce**: `curios.desktop.office.crm.salesforce.enable` and
  `curios.desktop.office.crm.salesforce.baseUrl` - Example:

```bash
sudo curios-update --update-module curios.desktop.office.crm.salesforce.enable true && \
sudo curios-update --update-module curios.desktop.office.crm.salesforce.baseUrl "your-domain.my.salesforce.com" && \
sudo curios-update --update
```

- **HubSpot**: `curios.desktop.office.crm.hubspot.enable` and
  `curios.desktop.office.crm.hubspot.baseUrl` (default: `app.hubspot.com`).
- **Odoo**: `curios.desktop.office.erp.odoo.enable` and
  `curios.desktop.office.erp.odoo.baseUrl` (example:
  `mycompany.odoo.com`).

## Conferencing

- **Slack**: web app shortcut.
- **Microsoft Teams**: web app shortcut.
- **Zoom**: native Zoom client. Available on amd64 only.

Enable them from `curios-manager` under `(curios.desktop.office) conferencing`,
or from a terminal, for example:

```bash
sudo curios-update --update-module curios.desktop.office.conferencing.slack.enable true && \
sudo curios-update --update
```

---
**Next**: [Virtualisation](virtualisation.md).

**Previous**: [Audio/Video applications](audio-video.md)

**Back**: [index](index.md).
