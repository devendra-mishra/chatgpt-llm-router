# TIR GPU-Tier-Aware LLM Inference Platform

## Overview

The TIR (Transformer Inference Router) platform is a production-grade, GPU-tier-aware LLM inference system designed to optimize latency, throughput, and cost by intelligently routing workloads to appropriate GPU resources. The platform combines advanced scheduling, endpoint selection intelligence, and policy-driven traffic management to deliver enterprise-scale LLM inference capabilities.

## Key Features

### 🚀 **Intelligent GPU Tier Management**
- **H100**: Premium realtime and long-context workloads
- **A100**: Standard realtime workloads with balanced performance
- **L40S**: Economy batch processing and overflow capacity

### 🎯 **Advanced Workload Classification**
- **Premium Realtime**: Low-latency, high-priority requests on H100
- **Standard Realtime**: Balanced performance requests on A100
- **Economy Batch**: Cost-optimized async processing on L40S
- **Long Context**: Specialized handling for large context windows
- **LoRA Dedicated**: Optimized for fine-tuned model adapters

### 🧠 **Smart Endpoint Selection**
- Queue-aware scoring for optimal load distribution
- KV cache utilization optimization
- Prefix cache affinity for improved performance
- LoRA adapter affinity for specialized workloads

### 🛡️ **Enterprise Security & Governance**
- JWT-based authentication with role-based access
- External authorization integration
- Request classification and header enrichment
- Comprehensive rate limiting and quota management

### 📊 **Production Observability**
- Comprehensive Prometheus metrics collection
- Real-time performance monitoring
- Health checks and alerting
- Request tracing and debugging

## Architecture Components

### **Model Lifecycle Management (Kthena + Volcano)**
- Automated model deployment and scaling
- Gang scheduling for multi-GPU workloads
- Topology-aware placement
- Prefill/decode disaggregation for large models

### **Inference Pools**
- GPU-tier specific resource grouping
- Automatic endpoint discovery
- Health monitoring and failover
- Load balancing across pool members

### **Gateway & Traffic Management (kgateway)**
- TLS termination and certificate management
- Authentication and authorization
- Request classification and routing
- Rate limiting and overflow policies

### **Endpoint Picker Extension (EPP)**
- Real-time endpoint scoring and selection
- Plugin-based scoring system
- Context-aware routing decisions
- Performance optimization algorithms

## Supported Models

### **Llama 3.1 8B**
- Available across all GPU tiers (H100, A100, L40S)
- Multiple serving classes (premium, standard, economy, long-context, LoRA)
- Optimized configurations per tier
- LoRA adapter support on capable tiers

### **DeepSeek V3**
- Prefill/decode disaggregation
- H100 prefill processing
- A100 decode generation
- Large model optimization

## Service Classes & SLA

| Service Class | GPU Tier | Latency Target | Use Cases |
|---------------|----------|----------------|-----------|
| Premium Realtime | H100 | < 100ms | Production APIs, real-time chat |
| Standard Realtime | A100 | < 200ms | General applications, user interfaces |
| Economy Batch | L40S | < 2s | Batch processing, non-critical workloads |
| Long Context | H100 | < 500ms | Document analysis, long conversations |
| LoRA Dedicated | H100 | < 150ms | Fine-tuned models, specialized tasks |

## Request Flow

1. **Client Request**: TLS-encrypted request to `/v1/chat/completions`
2. **Authentication**: JWT validation and user context extraction
3. **Authorization**: External auth service validates permissions
4. **Classification**: Request analysis determines serving class and model
5. **Routing**: HTTPRoute directs to appropriate InferencePool
6. **Endpoint Selection**: EPP scores and selects optimal backend
7. **Processing**: vLLM backend processes the inference request
8. **Response**: Streaming or batch response back to client

## Fallback & Overflow Strategy

### **Controlled Degradation**
- Premium → Standard (when overflow allowed)
- Standard → Economy (for async/batch requests)
- Long Context → Premium H100 (emergency fallback)

### **Strict Constraints**
- LoRA requests never fallback to non-LoRA capable pods
- Long context maintains context limits across fallbacks
- Security context preserved during tier transitions

## Deployment Architecture

### **Phase-Based Deployment**
1. **Namespace & Labels**: Foundation and conventions
2. **Model Lifecycle**: Kthena/Volcano managed deployments
3. **Pool Abstraction**: InferencePool resource creation
4. **Model Abstraction**: Client-facing InferenceModel mapping
5. **EPP Services**: Endpoint picker deployment and configuration
6. **Gateway Security**: Authentication and request classification
7. **Traffic Routing**: HTTPRoute configuration
8. **Policies**: Fallback, overflow, and rate limiting
9. **Observability**: Metrics and monitoring setup

### **High Availability**
- Multi-replica EPP deployments
- Cross-tier redundancy
- Automatic failover and recovery
- Health-based traffic shifting

## API Compatibility

### **OpenAI Compatible**
- Standard `/v1/chat/completions` endpoint
- Streaming and non-streaming responses
- Model selection via request parameters
- Error handling and status codes

### **Extended Headers**
- `x-serving-class`: Override default serving class
- `x-context-class`: Request context classification
- `x-lora-adapter`: Specify LoRA adapter
- `x-overflow-allowed`: Enable tier fallback

## Performance Characteristics

### **Throughput**
- H100 Premium: 500+ requests/second per pod
- A100 Standard: 300+ requests/second per pod
- L40S Economy: 150+ requests/second per pod

### **Scaling**
- Automatic horizontal scaling based on queue depth
- Configurable min/max replica limits
- Fast scale-up (30s) and conservative scale-down (5min)

### **Latency Optimization**
- Prefix caching for repeated prompts
- KV cache optimization
- Queue-aware load balancing
- Connection pooling and keep-alive

## Cost Optimization

### **Tiered Pricing Strategy**
- Premium tier for latency-critical workloads
- Standard tier for balanced price/performance
- Economy tier for cost-sensitive batch processing

### **Resource Efficiency**
- GPU memory utilization optimization
- Automatic model caching and sharing
- Efficient batch processing on economy tier

## Getting Started

### **Prerequisites**
- Kubernetes cluster with GPU nodes
- Node labels for GPU classification
- TLS certificates for gateway
- HuggingFace token for model access

### **Quick Deploy**
```bash
# Clone repository
git clone <repo-url>
cd chatgpt-llm-router

# Deploy all components
./deploy.sh

# Verify deployment
kubectl get pods -n tir-inference
```

### **Validation**
```bash
# Check inference pools
kubectl get inferencepools -n tir-inference

# Check gateway status
kubectl get gateway -n tir-inference

# Test inference endpoint
curl -X POST https://your-domain/v1/chat/completions \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"model": "llama-3.1-8b", "messages": [{"role": "user", "content": "Hello!"}]}'
```

## Support & Documentation

### **Operational Guides**
- [Detailed Workflow Documentation](./WORKFLOW_DETAILED.md)
- [Deployment Guide](../README.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)

### **API Reference**
- [OpenAI API Compatibility](./API_REFERENCE.md)
- [Extended Headers](./HEADERS_REFERENCE.md)
- [Error Codes](./ERROR_CODES.md)

### **Monitoring & Alerting**
- [Metrics Guide](./METRICS.md)
- [Alert Configuration](./ALERTS.md)
- [Performance Tuning](./PERFORMANCE.md)

---

*TIR Platform - Intelligent LLM Inference at Scale*