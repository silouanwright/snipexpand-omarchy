#!/usr/bin/env python3
"""Exercise real Quickshell Process completion and group refresh offline."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

here = Path(__file__).resolve().parent
cache = Path.home() / ".cache/snipexpand-plugin-tests"
cache.mkdir(parents=True, exist_ok=True)
fixture = Path(tempfile.mkdtemp(dir=cache))
try:
    shutil.copy2(here / "snipexpand", fixture / "snipexpand")
    for name in ["SnipExpandController.qml", "Model.js"]:
        shutil.copy2(here.parent.parent / name, fixture / name)
    shutil.copy2(here / "shell.qml", fixture / "shell.qml")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", PATH=str(fixture) + ":" + os.environ["PATH"])
    subprocess.run(["quickshell", "-p", str(fixture)], env=env, check=True, timeout=15)
finally:
    subprocess.run(["gio", "trash", "--", str(fixture)], check=True)
