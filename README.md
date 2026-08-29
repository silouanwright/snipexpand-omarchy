# SnipExpand for Omarchy

A native Omarchy bar panel for [SnipExpand](https://github.com/silouanwright/snipexpand).

Search configured snippets, add or edit generated snippets, restart the service,
and run setup diagnostics without leaving the bar. Handwritten YAML remains
read-only and opens in your configured editor.

## Install

```bash
omarchy plugin add https://github.com/silouanwright/snipexpand-omarchy --enable
```

SnipExpand must already be installed and available as `snipexpand`.

## Development

Dependencies are vendored reproducibly with [QMLPack](https://github.com/silouanwright/qmlpack):

```bash
qmlpack verify
node test_model.js
omarchy plugin validate .
```

## License

GPL-3.0-or-later
