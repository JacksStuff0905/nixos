{
  lib,
  pkgs,
  tags,
}:

let
  yamlGenerator =
    pkgs.writers.writePython3 "authentik-yaml-generator"
      {
        libraries = [ pkgs.python3Packages.pyyaml ];
        flakeIgnore = [
          "E501"
          "F841"
        ];
      }
      ''
        import json
        import sys
        import yaml
        from typing import Any


        class AuthentikDumper(yaml.SafeDumper):
            pass


        class TaggedValue:
            def __init__(self, tag_type: str, data: dict):
                self.tag_type = tag_type
                self.data = data


        def represent_find(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            model = data.data["__model__"]
            lookup = data.data["__lookup__"]
            lookup_list = []
            for k, v in lookup.items():
                lookup_list.extend([k, v])
            return dumper.represent_sequence(
                "!Find",
                [model, lookup_list],
                flow_style=True
            )


        def represent_keyof(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            value = data.data["__id__"]
            return dumper.represent_scalar("!KeyOf", value, style=None)


        def represent_context(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            name = data.data["__name__"]
            return dumper.represent_scalar("!Context", name, style=None)


        def represent_env(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            name = data.data["__name__"]
            default = data.data["__default__"]
            return dumper.represent_sequence(
                "!Env",
                [name, default],
                flow_style=True
            )


        def represent_condition(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            cond_type = data.data["__type__"]
            value = data.data["__value__"]
            return dumper.represent_sequence(
                "!Condition",
                [cond_type, value],
                flow_style=True
            )


        def represent_if(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            cond = convert_tags(data.data["__condition__"])
            then_val = convert_tags(data.data["__then__"])
            else_val = convert_tags(data.data["__else__"])
            return dumper.represent_sequence(
                "!If",
                [cond, then_val, else_val],
                flow_style=True
            )


        def represent_format(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            fmt = data.data["__format__"]
            args = [convert_tags(a) for a in data.data.get("__args__", [])]
            return dumper.represent_sequence(
                "!Format",
                [fmt] + args,
                flow_style=True
            )


        def tagged_representer(dumper: yaml.Dumper, data: TaggedValue) -> yaml.Node:
            handlers = {
                "find": represent_find,
                "keyof": represent_keyof,
                "context": represent_context,
                "env": represent_env,
                "condition": represent_condition,
                "if": represent_if,
                "format": represent_format,
            }
            handler = handlers.get(data.tag_type)
            if handler:
                return handler(dumper, data)
            return dumper.represent_mapping("!" + data.tag_type, data.data)


        AuthentikDumper.add_representer(TaggedValue, tagged_representer)


        def convert_tags(obj: Any) -> Any:
            if isinstance(obj, dict):
                if "__tag__" in obj:
                    return TaggedValue(obj["__tag__"], obj)
                return {k: convert_tags(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_tags(item) for item in obj]
            return obj


        def main():
            blueprint = json.load(sys.stdin)
            processed = convert_tags(blueprint)
            yaml.dump(
                processed,
                sys.stdout,
                Dumper=AuthentikDumper,
                default_flow_style=False,
                allow_unicode=True,
                sort_keys=False,
            )


        if __name__ == "__main__":
            main()
      '';
in
{
  mkBlueprint =
    name: blueprint:
    pkgs.runCommand "${name}.yaml"
      {
        passAsFile = [ "blueprintJson" ];
        blueprintJson = builtins.toJSON blueprint;
      }
      ''
        ${yamlGenerator} < "$blueprintJsonPath" > $out
      '';
}
