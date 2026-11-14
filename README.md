<p align="center">
  <img src="https://raw.githubusercontent.com/cert-manager/cert-manager/d53c0b9270f8cd90d908460d69502694e1838f5f/logo/logo-small.png" height="256" width="256" alt="cert-manager project logo" />
</p>

# Porkbun Webhook for cert-manager

An implementation of the cert-manager [`webhook.Solver` interface](https://pkg.go.dev/github.com/cert-manager/cert-manager/pkg/acme/webhook#Solver) for [Porkbun](https://porkbun.com/).

This is a maintained rebuild of [talinx/cert-manager-webhook-porkbun](https://github.com/talinx/cert-manager-webhook-porkbun), which is based on [bcspragu/cert-manager-webhook-porkbun](https://github.com/bcspragu/cert-manager-webhook-porkbun) and [cert-manager/webhook-example](https://github.com/cert-manager/webhook-example). The solver logic is unchanged. Differences from upstream:

- Go 1.27 and current dependencies: cert-manager v1.21, Kubernetes client libraries v0.36, `golang.org/x/net` v0.61.
- The image runs on `gcr.io/distroless/static-debian13`, so it carries no OS packages beyond CA certificates and tzdata.
- Images are published to `ghcr.io/mechazawa/cert-manager-webhook-porkbun` for `linux/amd64` and `linux/arm64`.
- The Go module path is `github.com/Mechazawa/cert-manager-webhook-porkbun`.

Modified files: `go.mod`, `go.sum`, `main.go`, `example/example_test.go`, `Dockerfile`, `.github/workflows/`, `charts/cert-manager-webhook-porkbun/Chart.yaml`, `charts/cert-manager-webhook-porkbun/values.yaml` and this README.

## Installation

### Install cert-manager

Install cert-manager using its [installation documentation](https://cert-manager.io/docs/installation/).

### Install webhook

The chart is not published to a Helm repository. Install it from a checkout of this repository, or use the upstream chart and set `image.repository` to `ghcr.io/mechazawa/cert-manager-webhook-porkbun`.

[Generate a porkbun API key](https://kb.porkbun.com/article/190-getting-started-with-the-porkbun-api) and create a secret with it:

```yaml
apiVersion: v1
stringData:
  PORKBUN_API_KEY: pk1_yourapikeyhere
  PORKBUN_SECRET_API_KEY: sk1_yoursecretkeyhere
kind: Secret
metadata:
  name: porkbun-secret
  namespace: cert-manager
type: Opaque
```

Install helm chart in a namespace of your choice, e. g. `cert-manager`:

```bash
helm install cert-manager-webhook-porkbun ./charts/cert-manager-webhook-porkbun -n cert-manager
```

Add an issuer (change the email address; the `groupName` has to match the `groupName` value of the helm chart), e. g.:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
spec:
  acme:
    email: youremailhere@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-porkbun-tls
    solvers:
    - dns01:
        webhook:
          groupName: porkbun.talinx.dev
          solverName: porkbun
          config:
            apiKey:
              key: PORKBUN_API_KEY
              name: porkbun-secret
            secretApiKey:
              key: PORKBUN_SECRET_API_KEY
              name: porkbun-secret
```

Add a certificate, e. g.:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: prod-cert
spec:
  secretName: prod-cert
  issuerRef:
    name: letsencrypt-issuer
    kind: ClusterIssuer
  dnsNames:
  - 'mysub.example.com'
```

### Testing

The repository does not include the cert-manager DNS01 conformance suite. To check a deployment, issue a short-lived certificate through the issuer and confirm that it becomes `Ready`.

## License

Changes in this repository are licensed under the MIT License (`LICENSE`). The upstream code is licensed under the Apache License 2.0 (`LICENSE-APACHE`), which still applies to the parts that come from upstream.
