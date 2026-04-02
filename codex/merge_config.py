#!/usr/bin/env python3

import json
import re
import sys
import tomllib
from collections.abc import Mapping
from pathlib import Path


BARE_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+$")


def load_toml(path: Path) -> dict:
    with path.open("rb") as fh:
        return tomllib.load(fh)


def merge_dicts(template: dict, local: dict) -> dict:
    merged: dict = {}

    for key, template_value in template.items():
        if key in local:
            local_value = local[key]
            if isinstance(template_value, Mapping) and isinstance(local_value, Mapping):
                merged[key] = merge_dicts(dict(template_value), dict(local_value))
            else:
                merged[key] = template_value
        else:
            merged[key] = template_value

    for key, local_value in local.items():
        if key not in merged:
            merged[key] = local_value

    return merged


def format_key(key: str) -> str:
    return key if BARE_KEY_RE.match(key) else json.dumps(key)


def format_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, list):
        return "[{}]".format(", ".join(format_value(item) for item in value))
    raise TypeError(f"Unsupported TOML value type: {type(value)!r}")


def emit_table(path: list[str], table: dict, lines: list[str]) -> None:
    scalar_items = [(key, value) for key, value in table.items() if not isinstance(value, Mapping)]
    nested_items = [(key, value) for key, value in table.items() if isinstance(value, Mapping)]

    if path:
        lines.append("[{}]".format(".".join(format_key(part) for part in path)))

    for key, value in scalar_items:
        lines.append(f"{format_key(key)} = {format_value(value)}")

    if path and nested_items:
        lines.append("")

    for index, (key, value) in enumerate(nested_items):
        emit_table(path + [key], dict(value), lines)
        if index != len(nested_items) - 1:
            lines.append("")


def dump_toml(data: dict) -> str:
    lines: list[str] = []
    emit_table([], data, lines)
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: merge_config.py TEMPLATE TARGET", file=sys.stderr)
        return 2

    template_path = Path(argv[1]).expanduser()
    target_path = Path(argv[2]).expanduser()

    template = load_toml(template_path)
    local = load_toml(target_path)
    merged = merge_dicts(template, local)

    target_path.write_text(dump_toml(merged), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
