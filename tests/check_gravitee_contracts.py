"""Validate actual mocked Terraform plan configurations against pinned policy schemas.

No real APIM/Azure requests, apply, or state inspection. Run from any directory.
Requires jsonschema; use an approved Python environment. Output contains counts,
not token values. Fixtures represent no installed platform or model approval.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from jsonschema import Draft7Validator


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--terraform', default='terraform')
    parser.add_argument('--events', type=Path, help='Existing verbose JSON mock-test output')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.events:
        output = args.events.read_text()
    else:
        result = subprocess.run(
            [args.terraform, 'test', '-filter=tests/gravitee-module.tftest.hcl',
             '-verbose', '-json'], cwd=root / 'gateways',
            capture_output=True, text=True, check=True,
        )
        output = result.stdout
    events = [json.loads(line) for line in output.splitlines() if line.strip()]
    assert events[-1]['type'] == 'test_summary' and events[-1]['test_summary']['status'] == 'pass'
    schemas_dir = root / 'modules/gravitee/schemas'
    provenance = json.loads((schemas_dir / 'PROVENANCE.json').read_text())
    validators = {}
    for policy, source in provenance.items():
        data = (schemas_dir / (policy + '.json')).read_bytes()
        assert hashlib.sha256(data).hexdigest() == source['sha256'], policy
        validators[policy] = Draft7Validator(json.loads(data))
    checked = 0
    policy_counts = {}

    def check_policy(policy, configuration):
        nonlocal checked
        payload = json.loads(configuration)
        if policy == 'shared-policy-group-policy':
            # Verified in provider v1.2.0's shared-policy-group example, not a
            # claim that Terraform itself validates arbitrary policy JSON.
            assert set(payload) == {'hrid'} and payload['hrid']
        else:
            assert policy in validators, policy
            validators[policy].validate(payload)
        checked += 1
        policy_counts[policy] = policy_counts.get(policy, 0) + 1

    plans = 0
    for event in events:
        if event.get('type') != 'test_plan':
            continue
        plans += 1
        for change in event['test_plan'].get('resource_changes', []):
            after = change.get('change', {}).get('after')
            if not after:
                continue
            if change['type'] == 'apim_apiv4':
                assert after['visibility'] == 'PRIVATE'
                assert after['flow_execution']['match_required'] is True
                logging = after['analytics']['logging']
                assert not any(logging['content'].values())
                assert not any(logging['mode'].values())
                assert after['analytics']['otel_logs']['enabled'] is False
                assert after['analytics']['tracing']['verbose'] is False
                for plan in after['plans']:
                    assert plan['security']['type'] == 'JWT'
                    check_policy('jwt', plan['security']['configuration'])
                for flow in after['flows']:
                    selector = flow['selectors'][0]['http']
                    assert selector['path'] == '/chat/completions'
                    assert selector['path_operator'] == 'EQUALS' and selector['methods'] == ['POST']
                    for step in flow['request'] + flow['response']:
                        check_policy(step['policy'], step['configuration'])
            elif change['type'] == 'apim_shared_policy_group':
                for step in after['steps']:
                    check_policy(step['policy'], step['configuration'])
                    payload = json.loads(step['configuration'])
                    assert payload['async'] is False
                    assert payload['errorStrategy'] == 'BLOCK_ON_INTERNAL_ERROR'
            elif change['type'] == 'apim_subscription':
                assert not after.get('api_keys')
            elif change['type'] == 'apim_application':
                assert after['settings']['app']['client_id']
    assert plans > 0 and checked > 0
    report = {'status': 'pass', 'mock_plans_inspected': plans,
              'policy_configurations_checked': checked, 'policy_counts': policy_counts,
              'upstream_schema_hashes_verified': len(validators),
              'runtime_enforcement_verified': False}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
