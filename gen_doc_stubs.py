# Generates virtual doc files for the mkdocs site.
# You can also run this script directly to actually write out those files, as a preview.

import mkdocs_gen_files

root = mkdocs_gen_files.config['plugins']['mkdocstrings'].get_handler('crystal').collector.root

for typ in root.lookup("Athena").walk_types():
    # Athena::Validator::Violation -> Validator/Violation/index.md
    filename = '/'.join(typ.abs_id.split('::')[2:] + ['index.md'])

    with mkdocs_gen_files.open(filename, 'w') as f:
        f.write(f'# ::: {typ.abs_id}\n\n')

    if typ.locations:
        mkdocs_gen_files.set_edit_path(filename, typ.locations[0].url)

for typ in root.types:
    # Write the entry of a top-level alias (e.g. `AED`) to its appropriate section.
    if typ.kind == "alias":
        # Athena::Validator::Annotations -> Validator/aliases.md
        filename = 'aliases.md'

        with mkdocs_gen_files.open(filename, 'a') as f:
            f.write(f'::: {typ.abs_id}\n\n')
