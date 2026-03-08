# Generates virtual doc files for the mkdocs site.
# You can also run this script directly to actually write out those files, as a preview.

import json
from typing import Any

import markdown as md
import mkdocs_gen_files

handler = mkdocs_gen_files.config["plugins"]["mkdocstrings"].get_handler("crystal")

# get the `update_env` method of the handler
update_env = handler.update_env


# override the `update_env` method of the handler
def patched_update_env(config: dict[str, Any]) -> None:
    update_env(config)

    def from_json(data):
        return json.loads(data.removesuffix("of Nil"))

    # patch the filter
    handler.env.filters["from_json"] = from_json


# patch the method
handler.update_env = patched_update_env

root = handler.collector.root

# Determine which namespace this project owns based on site_url
site_url = mkdocs_gen_files.config.get("site_url", "")
local_ns = site_url.rstrip("/").rsplit("/", 1)[-1] if site_url else None

# Base URL for cross-project links (e.g. "https://athenaframework.org/")
base_url = site_url.rstrip("/").rsplit("/", 1)[0] + "/" if site_url else ""

# Get autorefs plugin for registering external type URLs
autorefs = mkdocs_gen_files.config["plugins"].get("autorefs")

# Source path prefixes for filtering local vs external aliases
source_prefixes = [dest.src_path for dest in root.source_locations]

for type in root.lookup("Athena").walk_types():
    parts = type.abs_id.split("::")
    type_ns = parts[1] if len(parts) > 1 else None

    if local_ns and type_ns and type_ns != local_ns and autorefs:
        # External type: register full URL so autorefs treats it as external
        external_url = base_url + "/".join(parts[1:]) + "/"
        autorefs.register_url(type.abs_id, external_url)
        continue

    # Athena::Validator::Violation -> Validator/Violation/index.md
    filename = "/".join(parts[2:] + ["index.md"])

    # Rename the root `index.md` to `top_level.md` so that the user lands on the introduction page instead of the root component module docs.
    # But only do this for non-framework components as the site itself is the contextual docs for the framework.
    if type.full_name != "Athena::Framework" and filename == "index.md":
        filename = "top_level.md"

    with mkdocs_gen_files.open(filename, "w") as f:
        f.write(f"# ::: {type.abs_id}\n\n")

    if type.locations:
        mkdocs_gen_files.set_edit_path(filename, type.locations[0].url)

for type in root.types:
    # Write the entry of a top-level alias (e.g. `AED`) to its appropriate section.
    if type.kind == "alias":
        # Only write aliases whose source is local to this project
        if source_prefixes and type.locations:
            is_local = any(
                loc.filename.startswith(prefix)
                for loc in type.locations
                for prefix in source_prefixes
            )
            if not is_local:
                continue

        # Athena::Validator::Annotations -> Validator/aliases.md
        with mkdocs_gen_files.open("aliases.md", "a") as f:
            f.write(f"::: {type.abs_id}\n\n")
