# TIR LLM Router Deployment

This repository now contains a deployable, phase-wise Kubernetes layout derived from `llmd.yaml`.

## What was generated from `llmd.yaml`

- `deployments/00-namespace-and-labels.yaml`: namespace and label conventions
- `deployments/10-model-lifecycle.yaml`: Kthena/Volcano model lifecycle resources
- `deployments/20-inference-pools.yaml`: `InferencePool` resources per serving class/GPU tier
- `deployments/30-inference-models.yaml`: `InferenceModel` abstraction layer
- `deployments/40-epp-deployments.yaml`: llm-d EPP service account, RBAC, and deployments
- `deployments/41-epp-config.yaml`: EPP plugin and scoring ConfigMaps
- `deployments/50-gateway-auth-classifier.yaml`: kgateway, JWT auth, external auth, request classifier
- `deployments/51-routing.yaml`: HTTPRoutes for premium/standard/economy/longctx/lora/deepseek
- `deployments/52-overflow-policy.yaml`: fallback and overflow policy config
- `deployments/53-rate-limit.yaml`: tiered local rate limit policy
- `deployments/60-observability-and-storage.yaml`: ServiceMonitors and shared model-cache PVC
- `deployments/kustomization.yaml`: ordered resource composition
- `deploy.sh`: one-command deployment helper

## Deployment workflow

1. Validate cluster prerequisites:
- GPU nodes are labeled (`gpu.e2e.ai/family`, `gpu.e2e.ai/memory`, `gpu.e2e.ai/interconnect`, `gpu.e2e.ai/cost-tier`)
- CRDs/controllers exist for Kthena/Volcano, llm-d inference APIs, kgateway, and Prometheus ServiceMonitor
- Secret `hf-token` exists in namespace `tir-inference`
- TLS secret `tir-inference-tls` exists

2. Deploy all resources:

```bash
./deploy.sh
```

Equivalent command:

```bash
kubectl apply -k deployments
```

3. Verify rollout:

```bash
kubectl get pods -n tir-inference
kubectl get inferencepools,inferencemodels -n tir-inference
kubectl get gateway,httproute -n tir-inference
```

4. Validate request path:
- Request enters `Gateway` (`tir-inference-gateway`)
- Auth and classifier policies add routing headers (`x-inference-model`, `x-serving-class`, `x-context-class`, `x-lora-adapter`, `x-overflow-allowed`)
- `HTTPRoute` maps headers to `InferencePool`
- Pool extension (`epp-*`) performs endpoint scoring and final pod selection
- Request hits selected vLLM backend

## Runtime flow summary

- Control plane:
  `ModelBooster/ModelServing` -> serving pods -> `InferencePool` -> `InferenceModel`
- Data plane:
  client -> kgateway -> auth/classifier -> route -> pool -> EPP -> selected pod
- Resilience:
  overflow policy + fallback pools + queue/cache-aware scoring + autoscaling

## Notes

- `llmd.yaml` remains unchanged as the source design file.
- Operational deep-dive is in `docs/WORKFLOW_DETAILED.md`.
