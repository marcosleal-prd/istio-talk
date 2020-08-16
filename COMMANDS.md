# Comandos

## Criação e Configuração do Cluster

#### Mostrar contextos disponíveis:
```bash
kubectl config get-contexts -o=name
```

#### Mostrar contexto atual:
```bash
kubectl config current-context
```

#### Criar o cluster com `kind`:
```bash
kind create cluster --name local --config kind-config.yaml
```

#### Mostrar contexto atual (agora deve ser `kind-local`):
```bash
kubectl config current-context
```

#### Abrir o k9s para todos os namespaces do Cluster:
```bash
k9s -n all
```

#### Subir o `metrics-server` no cluster:
```bash
kubectl apply -f metrics-server.yaml
```

## Adicionar o Istio ao Cluster

#### Download do Istio:
```bash
curl -L https://istio.io/downloadIstio | sh -
```

#### Tentar acessar a versão do Istio:
```bash
istioctl version
```

#### Adicionar o `istioctl` ao `PATH`:
```bash
export PATH=$PWD/bin:$PATH
```

#### Tentar acessar a versão do Istio:
```bash
istioctl version
```

#### Adicionar o Istio ao Cluster com profile `demo`:
```bash
istioctl install --set profile=demo
```

#### Alterar o tipo do `ingressgateway` do Istio para `NodePort`:
```bash
kubectl patch service istio-ingressgateway -n istio-system --patch "$(cat patch-ingressgateway-nodeport.yaml)"
```

#### Ver as labels do namespace `default`:
```bash
kubectl get namespaces default --show-labels # Ou no K9S
```

`control + w` para exibir as labels no K9S.

#### Habilitar a injeção automática do `sidecar` no namespace `default`:
```bash
kubectl label namespace default istio-injection=enabled
```

Sem a injeção automática é possível injetar com:

```bash
kubectl apply -f <(istioctl kube-inject -f app/my-app.yaml)
```

## Subir a Aplicação `bookinfo` (COM Istio):

#### Iniciar todos os microsserviços:
```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

#### Ver todos os `services` da aplicação:
```bash
kubectl get services # Ou no K9S
```

#### Ver todos os `pods` da aplicação:
```bash
kubectl get pods # Ou no K9S
```

#### Habilitar tráfego externo:
```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

#### Reiniciar o K9S para ver `resources`:
```bash
k9s -n default
```

#### Verifique se não há problemas com a configuração:
```bash
istioctl analyze
```

#### Aplicar as regras de destino `default`:
```bash
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

#### Verificar as regras de destino criadas:
```bash
kubectl get destinationrules -o yaml # Ou no K9S
```

Com isso, você pode em outra instância de terminal, executar o arquivo [`run.sh`](run.sh) para acumular algumas requisições.

# Casos de Uso

## Solicitação de Roteamento

#### Todo o tráfego para um Versão Específica (`v1`):
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

Verifica os **Serviços Virtuais** criados:
```bash
kubectl get virtualservices -o yaml
```

#### Tráfego baseado em `headers` (`end-user`):
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

## Injeção de Falhas

#### Atraso entre `reviews:v2` e `ratings` para o usuário `jason`:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
```

#### Cancelamento de `ratings` para o usuário `jason`:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
```

## Mudança de Tráfego

#### Voltar todo o tráfego para `v1`:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

#### Controle de tráfego por percentual entre `reviews:v1` e `v3`:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
```

#### 100% do tráfego para `reviews:v3`:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
```

## Egresss: Acessando serviços externos

#### Subir aplicação `sleep`:
```bash
kubectl apply -f samples/sleep/sleep.yaml
```

#### Criar variável de ambiente para o `SOURCE_POD`:
```bash
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
```

#### Acesso NÃO CONTROLADO a serviços externos:
O `configmap` [deve ser como nessa issue](https://github.com/istio/istio/issues/24329), caso contrário precisamos alterá-lo antes de continuar.

Alterar o configmap do `istio`, logo após a chave `accessLogFormat` inserir:
```yaml
outboundTrafficPolicy:
  mode: ALLOW_ANY
```

Garantir que o `outboundTrafficPolicy` é `ALLOW_ANY`:
```bash
kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY" | uniq
```

Algumas requisições externas:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep "HTTP/"
kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
```

Essa abordagem tem a desvantagem de perder o monitoramento e o controle do Istio para o tráfego de serviços externos.

#### Acesso CONTROLADO a serviços externos:
Usando `ServiceEntry` do Istio, você pode acessar qualquer serviço publicamente acessível a partir do cluster do Istio.

#### Alterar política para `REGISTRY_ONLY`:
```bash
kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
```

Garantir que o `outboundTrafficPolicy` é `REGISTRY_ONLY`:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep "HTTP/"
```

#### Criar um `ServiceEntry` para permitir acesso a um serviço HTTP externo:
```bash
kubectl apply -f ./external-services/httpbin-service-entry.yaml
# Ou
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF
```

Solicitação para o serviço externo:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- curl http://httpbin.org/headers
```

Verifique os logs do proxy de sidecar:
```bash
kubectl logs $SOURCE_POD -c istio-proxy | tail # Ou no K9S
```

#### Criar um `ServiceEntry` para permitir acesso a um serviço HTTPS externo:
```bash
kubectl apply -f ./external-services/google-service-entry.yaml
# Ou
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: google
spec:
  hosts:
  - www.google.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
EOF
```

Solicitação para o serviço externo:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep "HTTP/"
```

Verifique os logs do proxy de sidecar:
```bash
kubectl logs $SOURCE_POD -c istio-proxy | tail # Ou no K9S
```

#### Gerenciamento de tráfego para serviços externos:
As regras de roteamento do Istio também pode ser definidas para serviços externos por meio de `ServiceEntry`.

Solicitação com 5s de delay:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
```

Definir timeout para o serviço externo `httpbin.org`:
```bash
kubectl apply -f ./external-services/httpbin-virtual-service.yaml
# Ou
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-ext
spec:
  hosts:
    - httpbin.org
  http:
  - timeout: 3s
    route:
      - destination:
          host: httpbin.org
        weight: 100
EOF
```

Novamente solicitação com 5s de delay:
```bash
kubectl exec -it $SOURCE_POD -c sleep -- time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
```

## Mirroring / Dark Launch

Antes de começar:
```bash
kubectl delete -f samples/sleep/sleep.yaml
```

#### Adicionar o serviço `httpbin`:

**httpbin-v1:**
```bash
kubectl apply -f ./dark-launch/httpbin-v1-deployment.yaml
# Ou
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
        ports:
        - containerPort: 80
EOF
```

**httpbin-v2:**
```bash
kubectl apply -f ./dark-launch/httpbin-v2-deployment.yaml
# Ou
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v2
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:80", "httpbin:app"]
        ports:
        - containerPort: 80
EOF
```

**httpbin Kubernetes service:**
```bash
kubectl apply -f ./dark-launch/httpbin-service.yaml
# Ou
kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
EOF
```

**sleep service:**
```bash
kubectl apply -f ./dark-launch/sleep-deployment.yaml
# Ou
cat <<EOF | istioctl kube-inject -f - | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
EOF
```

O k8s vai direcionar por padrão para as duas versões, para evitar vamos redirecionar todo o tráfego para a `v1` usando `DestinationRule`:
```bash
kubectl apply -f ./dark-launch/httpbin-routing.yaml
# Ou
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
```

Fazer alguma requisição para o serviço:
```bash
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
kubectl exec -it "$SLEEP_POD" -c sleep -- sh -c 'curl http://httpbin:8000/headers' | python -m json.tool
```

Agora deve existir logs apenas na `v1`:
```bash
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
kubectl logs -f "$V1_POD" -c httpbin
```

```bash
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})
kubectl logs -f "$V2_POD" -c httpbin
```

Espelhar o tráfego para `v2`:
```bash
kubectl apply -f ./dark-launch/httpbin-v1-mirror-v2.yaml
# Ou
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
  - route:
    - destination:
        host: httpbin
        subset: v1
      weight: 100
    mirror:
      host: httpbin
      subset: v2
    mirror_percent: 100
EOF
```

Realizar a requisição:
```bash
kubectl exec -it "$SLEEP_POD" -c sleep -- sh -c 'curl http://httpbin:8000/headers' | python -m json.tool
```

Deve haver logs em ambas as versões:
```bash
kubectl logs -f "$V1_POD" -c httpbin
```

```bash
kubectl logs -f "$V2_POD" -c httpbin
```

Loop de requisições:
```bash
./dark-launch/run.sh
```

## Consulta de Métricas

#### Abrir Prometheus:
```bash
istioctl dashboard prometheus
```

#### Total de requests do Istio:
```bash
istio_requests_total
```

#### Total de *requests* para `productpage`:
```bash
istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
```

#### Total de *requests* para `reviews:v3`:
```bash
istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
```

Essa consulta retorna o total atual de *requests* para a v3 do serviço `reviews`.

#### Taxa de *requests* nos últimos 5 minutos para todas as instâncias `productpage`:
```bash
rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
```

## Visualização de Métricas

#### Verificar se o Prometheus está em execução:
```bash
kubectl -n istio-system get svc prometheus # Ou no K9S
```

#### Verificar se o Grafana está em execução:
```bash
kubectl -n istio-system get svc grafana # Ou no K9S
```

#### Abrir Grafana:
```bash
istioctl dashboard grafana
```

#### Dashboard: Istio Mesh Dashboard
Visão global da malha com serviços e workloads.

#### Dashboard: Istio Service Dashboard
- Métricas para o serviço.
- Workloads do cliente (workloads que estão chamando este serviço).
- Workloads de serviço (workloads que estão fornecendo este serviço) para esse serviço.

#### Dashboard: Istio Workload Dashboard
- Métricas para cada workload.
- Workload de entrada (workloads que estão enviando solicitação para essa carga de trabalho).
- Serviços de saída (serviços para os quais esse workload envia solicitações) para esse workload.

## Tracing Distribuído

#### Abrir Jeager:
```bash
istioctl dashboard jaeger
```

Selecionar o serviço `productpage.default` e clicar em **Find Traces**. Em seguida clique um dos resultados para analisar.

## Visualizando sua malha

#### Abrir o Kiali:
```bash
istioctl dashboard kiali
```

#### Tela: Overview:
Exibe todos os namespaces que têm serviços na malha.

#### Tela: Graph
Mostra as conexões entre os workloads da malha de serviços.

Ativar **`Traffic Animation`** e direcionar todo o tráfego para a `v1` novamente:
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

Logo em seguida adicionar uma falha para mostrar o serviço quebrando em tempo real (de `ratings` para o usuário `jason`)
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
```

## Mostrar memória e CPU dos `sidecars`:
```bash
kubectl top pod -n YOUR_NAMESPACE POD_NAME --containers
# Ou
k9s -n default
```

Com isso você já deve ser capaz de implementar os principais recursos do Istio.

**Mas isso não é o bastante.**

[Visite a documentação oficial para conhecer outros recursos](https://istio.io/latest/docs/) e acompanhe as atualizações que ferramenta recebe.