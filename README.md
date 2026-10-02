# SnipExpand for Omarchy

A native Omarchy bar panel for [SnipExpand](https://github.com/silouanwright/snipexpand).

Search configured snippets, add or edit generated snippets, manage snippet
packs and personal groups, restart the service, and run setup diagnostics without leaving the bar.
Handwritten YAML remains read-only and opens in your configured editor.

## Install

```bash
omarchy plugin add https://github.com/silouanwright/snipexpand-omarchy --enable
```

SnipExpand 0.4.0 or newer must already be installed and available as
`snipexpand`. Personal group controls require SnipExpand 0.5.0 or newer.

Open **Groups** to enable or disable collections defined in `snippet_groups` in
`config.yml`. Choices persist across service and shell restarts. Counts show
availability before application filters; overlapping groups and nested snippet
dependencies can reduce that count. Global Pause still takes precedence. The
picker hides snippets disabled by group choices. Group definitions stay in YAML;
**Open config** opens them in your editor.

Automatic expansion needs keyboard read access as well as a running service.
Use the [SnipExpand setup instructions](https://github.com/silouanwright/snipexpand#set-up)
and run `snipexpand doctor` if typed triggers do not expand. Selecting a snippet
in the panel can still paste successfully when keyboard access is missing.
Restart service reports success or failure in Diagnostics and refreshes the
checks after restarting.

## Development

Dependencies are vendored reproducibly with [QMLPack](https://github.com/silouanwright/qmlpack):

```bash
qmlpack verify
node test_model.js
python3 tests/controller/run.py
omarchy plugin validate .
vendor/qmlpack/oma-showcase/bin/oma-showcase \
  --project "$PWD" --preview tools/showcase/Preview.qml \
  --output docs/assets/themes.png
```

## License

GPL-3.0-or-later
