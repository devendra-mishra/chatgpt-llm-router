# Detailed Workflow Documentation (Presentation Version)

## 1. Objective

Build a production LLM inference platform that optimizes latency, throughput, and cost by combining:
- workload lifecycle + autoscaling (Kthena/Volcano)
- endpoint selection intelligence (llm-d EPP)
- secure, policy-driven ingress (kgateway)
- GPU tier-aware routing and fallback

## 2. Architecture Components

- **Kthena + Volcano**
  Manages model lifecycle, autoscaling, and specialized scheduling (including prefill/decode disaggregation).
- **vLLM pods**
  Actual serving backends with model-specific and class-specific configs.
- **InferencePool**
  Groups compatible endpoints (by model, GPU tier, serving class).
- **InferenceModel**
  Client-facing logical model abstraction.
- **llm-d EPP**
  Performs final endpoint selection using scoring plugins (queue, KV cache, prefix, LoRA affinity).
- **kgateway**
  Handles TLS termination, JWT auth, ext-auth, request classification, and route dispatch.
- **Policy/observability**
  Overflow/fallback policy, rate limiting, and Prometheus scraping.

## 3. Phase-by-Phase Pipeline

### Phase 0: Namespace and labeling
- Creates `tir-inference` namespace.
- Establishes strict labeling schema for nodes and pods.
- These labels are the contract used by scheduling, pool selection, and fallback logic.

### Phase 1: Model lifecycle (base + advanced)
- Deploys `ModelBooster` instances for `llama-3.1-8b` across:
  - H100 premium realtime
  - A100 standard realtime
  - L40S economy batch
  - H100 long-context
  - H100 LoRA dedicated
- Deploys `ModelServing` for `deepseek-v3` with prefill/decode role split:
  - prefill on H100
  - decode on A100
- Autoscaling uses queue-depth-style metrics for elasticity.

### Phase 2: Pool abstraction
- Creates `InferencePool` objects for each serving lane.
- Each pool selects pods via labels and binds to an EPP extension.
- This is where the system transitions from pod-level scheduling to pool-level routing.

### Phase 3: Model abstraction
- Creates `InferenceModel` resources mapping logical model names to pools.
- Allows stable model interfaces while pool implementations evolve.

### Phase 4/5: EPP runtime + scoring policies
- Deploys llm-d EPP instances per pool (`epp-llama-*`, `epp-deepseek-pd`).
- Configures scoring profiles:
  - premium: balanced queue/KV/prefix
  - standard: queue-first balance
  - economy: queue-dominant
  - long-context: cache-affinity heavy
  - lora: LoRA affinity priority
  - deepseek PD: prefill/decode-aware plugin chain

### Phase 6/7: Gateway security + request routing
- Gateway terminates TLS.
- JWT auth and ext-auth enforce security context.
- Request classifier writes routing headers.
- HTTPRoutes map headers to correct `InferencePool`.

### Phase 8/9: Fallback and protection
- Policy defines controlled overflow and fallback conditions.
- Prevents invalid downgrades (e.g., LoRA to non-LoRA pod).
- Applies local token-bucket rate limiting.

### Phase 10: Observability and storage
- ServiceMonitors scrape EPP and vLLM metrics.
- Shared RWX PVC stores model cache.

## 4. End-to-End Request Journey

1. Client calls `/v1/chat/completions`.
2. kgateway accepts TLS and validates identity.
3. Request classifier assigns headers (model/class/context/adapter/overflow).
4. HTTPRoute picks target pool using header matches.
5. Pool invokes its EPP extension.
6. EPP scores candidate pods and selects best endpoint.
7. Request is forwarded to selected vLLM pod.
8. Metrics emitted for gateway, EPP, and backend observability.

## 5. Deployment Order

Use `kubectl apply -k deployments` (already ordered in `deployments/kustomization.yaml`):
1. namespace/labels
2. model lifecycle
3. pools and model abstractions
4. EPP config and deployments
5. gateway/auth/classifier/routing
6. overflow + rate limits
7. observability + storage

## 6. Operational Validation Checklist

- `kubectl get pods -n tir-inference` shows ready EPP and serving pods.
- `kubectl get inferencepools,inferencemodels -n tir-inference` returns expected resources.
- `kubectl get httproute -n tir-inference` shows route acceptance.
- Prometheus discovers `epp-metrics` and `vllm-metrics` ServiceMonitors.
- Synthetic traffic confirms class-based routing and overflow behavior.

## 7. Presentation Talking Points

- **Why this design**: balances performance and cost by routing workloads to the right GPU tier.
- **Where intelligence lives**: EPP scoring + request classification headers.
- **How reliability is achieved**: controlled fallback, autoscaling, and route/pool abstractions.
- **How to operate it**: phase-wise manifests, kustomize deployment, and clear verification commands.
