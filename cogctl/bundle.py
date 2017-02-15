import glob
import os
import yaml

EXTENSIONS = (".greenbar", ".md")


def from_yaml(yaml_string):
    return yaml.load(yaml_string)

# TODO: do we accept JSON files, too?


def add_templates(config, template_dir):
    t = config.get('templates', {})
    from_dir = {template_name(f): template_body(f)
                for f in templates(template_dir)}
    new_t = {**t, **from_dir}  # Merge dicts
    config['templates'] = new_t
    return config


def templates(dir):
    return [f for f in glob.glob("%s/*" % dir)
            if f.endswith(EXTENSIONS)]


def template_name(path):
    # TODO: add this to a util module
    base = os.path.basename(path)
    (name, _) = os.path.splitext(base)
    return name


def template_body(path):
    with open(path) as f:
        return f.read()
