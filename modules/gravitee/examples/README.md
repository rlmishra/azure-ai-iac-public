# Disabled review example

`reviewed-inputs.tfvars.json.example` demonstrates the input structure for `gateways/dev`; it is not a platform inventory, model recommendation or approval. It leaves deployment/publication/analytics/tracing disabled and operational flags false. All sample IDs, domains, model/deployment metadata and version values must be replaced and independently reviewed. `plugin_versions` is intentionally empty rather than inventing an installed compatible set.

Copy to a protected actual JSON tfvars file only after reading docs/phase3/DEPLOYMENT.md. Default environment examples in gateways/{dev,test,prod} are even smaller disabled configurations. No provider secret, API key, JWT, client secret or live state is supplied by any example. Do not use synthetic plugin versions from tests as production input.
