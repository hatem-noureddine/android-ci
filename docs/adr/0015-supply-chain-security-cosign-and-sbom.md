# ADR-0015: Supply Chain Security with Keyless Cosign / Sigstore and SPDX SBOM Attestations

## Status
Accepted

## Context
Containers deployed in enterprise CI/CD workflows and mission-critical production systems face increasing scrutiny regarding supply chain provenance, build tampering, and vulnerability traceability. 

While `hateum/android-ci-box` already enforces strict quality and security gates (0 unfixed critical CVEs via Trivy, rootless POSIX compliance, and automated testing), it lacked cryptographic proof of origin and a machine-readable Software Bill of Materials (SBOM) attached directly to the published container images.

Traditional container signing required long-lived GPG or Cosign private keys stored in CI secrets, introducing risks of key leakage, unauthorized signing, and rotation overhead.

## Decision
We adopt **Keyless Cryptographic Signing via Sigstore / Cosign** and **Automated SPDX SBOM Attestation** for all official multi-arch releases (`hateum/android-ci-box` and `ghcr.io/hatem-noureddine/android-ci-box`):

1. **Keyless Signing via OpenID Connect (OIDC)**:
   - Leverage GitHub Actions OIDC identity (`id-token: write`) and Sigstore's Fulcio CA / Rekor transparency log.
   - Eliminate static private keys: short-lived certificates are generated dynamically for the GitHub Actions workflow run and verified against GitHub's immutable issuer and repository claims.

2. **Automated SPDX SBOM Generation**:
   - Integrate Anchore's **Syft** into Job 4 (`publish-manifest`) to generate a standardized, machine-readable Software Bill of Materials (`.spdx.json`).
   - The SBOM catalogues every OS package, binary utility, Java library, Python package, and Ruby gem bundled inside the container.

3. **In-Registry OCI Attestation & Distribution**:
   - Attach the SBOM directly to the OCI container image registry using `cosign attest --type spdxjson --predicate ...`.
   - Publish the raw `android-ci-box-${VERSION}.spdx.json` artifact as an asset attached to the official GitHub Release (`vX.Y.Z`).

4. **Cryptographic Signing of Multi-Arch Images**:
   - Sign multi-arch images (`${VERSION}` and `latest`) using `cosign sign --yes`.
   - Record the cryptographic signature in the public Sigstore Rekor ledger for independent verification.

## Public Verification Protocol
Consumers and automated enterprise gates can verify the provenance and authenticity of the image using the Cosign CLI:

```bash
# Verify image signature against GitHub OIDC issuer
cosign verify ghcr.io/hatem-noureddine/android-ci-box:latest \
  --certificate-identity-regexp "https://github.com/hatem-noureddine/android-ci/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

# Verify and extract the in-toto SPDX SBOM attestation
cosign verify-attestation --type spdxjson ghcr.io/hatem-noureddine/android-ci-box:latest \
  --certificate-identity-regexp "https://github.com/hatem-noureddine/android-ci/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

## Consequences
- **Positive**:
  - Full compliance with SLSA (Supply-chain Levels for Software Artifacts) Level 3 requirements.
  - Zero private key management overhead; immune to static key leakage.
  - Transparent auditing: every release is verifiably tied to the specific GitHub commit and workflow execution via Rekor.
  - Enterprise security compliance teams can ingest the SPDX SBOM directly into dependency scanners (Trivy, Grype, Dependency-Track).
- **Negative**:
  - Adds ~15–30 seconds to the `publish-manifest` release step for Syft scanning and Sigstore network registration.
