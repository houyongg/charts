## app chart

`app` 是一个面向 `zaobao-ops` 的通用应用部署模板，推荐搭配 Flux 的 `HelmRelease` 使用，并通过 `valuesFrom(ConfigMap/Secret)` + Kustomize overlay 完成各环境差异配置。

### 适用场景（对应 zaobao-ops 的 base/patch）

- **base**：在 `apps/base/<app>/release.yaml` 放一个最小 `HelmRelease`，只声明 chart 来源（`HelmRepository: zaobao-charts`）与基础安装策略。
- **各环境 patch**：在 `apps/<env>/<app>/kustomization.yaml` 里引入 `../../base/<app>`，通过 `configMapGenerator` 生成 `<app>-values`，并在 `patch.yaml` 中把 `HelmRelease.spec.valuesFrom` 指向这个 ConfigMap。

### 主要能力

- **Deployment**：image、replica、resources、probes、command/args、initContainers/extraContainers、volumes/volumeMounts、nodeSelector/tolerations/affinity/topologySpreadConstraints
- **Service**：多端口（`service.ports`）
- **Ingress**：支持 `networking.k8s.io/v1`，后端端口可用 name 或 number（`ingress.hosts[].paths[].servicePort`）
- **HPA/PDB**：可选
- **ServiceMonitor**：可选（Prometheus Operator）
- **env 注入**：可选创建 `ConfigMap/Secret` 并通过 `envFrom` 注入

### values 关键字段示例

```yaml
image:
  repository: zaobao-docker-registry.example.com/team/my-app
  tag: "1.2.3"

container:
  ports:
    - name: http
      containerPort: 8080
  env:
    - name: TZ
      value: Asia/Shanghai
  readinessProbe:
    httpGet:
      path: /healthz
      port: http

service:
  ports:
    - name: http
      port: 80
      targetPort: http

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
          pathType: Prefix
          servicePort: http
```

### Flux HelmRelease（base）示例

> `zaobao-ops/apps/base/<app>/release.yaml`

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: my-app
spec:
  interval: 10m
  chart:
    spec:
      chart: app
      version: "0.1.*"
      sourceRef:
        kind: HelmRepository
        name: zaobao-charts
        namespace: flux-system
      interval: 5m
  releaseName: my-app
```

### overlay 通过 valuesFrom 覆盖（patch）示例

> `zaobao-ops/apps/<env>/<app>/kustomization.yaml` + `patch.yaml`

```yaml
# kustomization.yaml
resources:
  - ../../base/my-app
patches:
  - path: patch.yaml
configMapGenerator:
  - name: my-app-values
    files:
      - values.yaml
configurations:
  - kustomizeconfig.yaml
```

```yaml
# kustomizeconfig.yaml
nameReference:
  - kind: ConfigMap
    version: v1
    fieldSpecs:
      - path: spec/valuesFrom/name
        kind: HelmRelease
```

```yaml
# patch.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: my-app
spec:
  valuesFrom:
    - kind: ConfigMap
      name: my-app-values
```
