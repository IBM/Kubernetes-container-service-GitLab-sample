[![Build Status](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample.svg?branch=master)](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample)

# 쿠버네티스 클러스터에 GitLab 구축하기

본 프로젝트는 일반적인 멀티 컴포넌트 워크로드(여기에서는 GitLab)를 쿠버네티스 클러스터에 구축하는 방법을 소개합니다. Git 기반의 코드 트래킹 툴로 잘 알려져 있는 GitLab은 전형적인 멀티-티어 앱으로, 각 구성요소마다 각각의 컨터이너 기반으로 실행됩니다. 마이크로서비스 컨테이너들이 웹 티어와 상태/작업 내용 캐싱을 위한 Redis, 그리고 데이터베이스용으로 PostgreSQL에 이용됩니다.

다양한 GitLab 구성요소(NGINX, Ruby on Rails, Redis, PostgreSQL 등)들이 쿠버네티스 환경에 구성될 것입니다. 이 예제는 Bluemix의 Compose for PostgreSQL라는 관리형 데이터베이스로도 구성이 가능합니다.

![흐름도](images/gitlab_container_2.png)

1. 사용자가 웹 인터페이스를 통해, 또는 GitHub 저장소에 코드를 푸시하여 GitLab을 사용합니다. GitLab 컨테이너는 NGINX와 gitlab-workhorse(파일 다운로드 또는 Git 푸시/풀과 같은 대량의 HTTP 요청을 위한 리버시 프록시 역할을 하는) 뒤에서 메인 Ruby on Rails 애플리케이션을 실행합니다. GitLab은 HTTP/HTTPS를 통해 저장소를 제공함과 동시에, GitLab API를 활용하여 권한부여 및 접근권한을 함으로써 Git 오브젝트를 제공합니다.

2. 인증 및 권한부여 확인 후에, GitLab Rails 애플리케이션이 새로이 요청되는 작업, 작업 정보, 메타데이터 등을 비영구적 데이터베이스의 역할을 하는 Redis 작업 대기열로 전송합니다.

3. Git 저장소가 로컬 파일 시스템에 생성됩니다.

4. 사용자가 사용자, 역할, 병합 요청, 그룹 등을 생성하면, PostgreSQL에 모두 저장됩니다.

5. 사용자가 Git 쉘을 통하여 Git 저장소에 접근합니다.

## 포함된 구성요소
- [GitLab](https://about.gitlab.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [쿠버네티스 클러스터(Kubernetes Clusters)](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [Bluemix 컨테이너 서비스(Bluemix container service)](https://console.ng.bluemix.net/catalog/?taxonomyNavigation=apps&category=containers)
- [Bluemix Compose for PostgreSQL](https://console.ng.bluemix.net/catalog/services/compose-for-postgresql)

## 목표
이 시나리오는 하기 작업들에 대한 가이드를 제공합니다.

- 컨테이너 빌드 및 컨테이너 레지스트리에 빌드된 컨테이너 저장하기
- 쿠버네티스 상에서 영구적 디스크를 정의하기 위해 로컬 PersistentVolume (PV) 생성하기
- 쿠버네티스 pods 및 서비스를 사용해 컨테이너 구성하기
- 쿠버네티스 애플리케이션 상에서 Bluemix 서비스 이용하기
- 쿠버네티스에 분산형 GitLab 구성하기

## 구성 시나리오

### 도커(Docker)를 활용한 구성

[도커를 활용한 Gitlab 구성(Deploy GitLab with Docker)](docs/deploy-with-docker.md)을 참고하십시오.

### 쿠버네티스 환경에 구성하기

로컬 환경에서 테스트를 위해서는  [미니큐브(Minikube)](https://kubernetes.io/docs/getting-started-guides/minikube)로, 클라우드 상에서는  [IBM Bluemix 컨테이너 서비스(IBM Bluemix Container Service](https://github.com/IBM/container-journey-template#container-journey-template---creating-a-kubernetes-cluster) 를 활용하여 쿠버네티스 클러스터를 생성하십시오. 본 예제의 코드는 Travis를 사용하여  [Bluemix 컨테이너 서비스의 쿠버네티스 클러스터(Kubernetes Cluster from Bluemix Container Service)](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) 상에서 정기적으로 테스트 됩니다.

Bluemix 컨테이너 레지스트리(Bluemix Container Registry)를 이용하고자 하는 경우, Bluemix 컨테이너 레지스트리에  [이미지 업로드(Uploading the images)](docs/use-bluemix-container-registry)하여 시작할 수 있습니다.

### Bluemix 컨테이너 서비스의 쿠버네티스 클러스터 환경에 DevOps 툴체인 이용하여 구성하기
Gitlab을 Bluemix 환경에 직접 구성하고자 한다면, 아래의 ‘Deploy to Bluemix’ 버튼을 클릭하여 Gitlab 예제 구성을 위한  [Bluemix DevOps s서비스 툴체인과 파이프라인](https://console.ng.bluemix.net/docs/services/ContinuousDelivery/toolchains_about.html#toolchains_about)을 생성하십시오. 그렇지 않은 경우 [단계](#단계)로 이동하십시오.

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

[툴체인 가이드](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md)를 참고하여 툴체인과 파이프라인을 완성하십시오.

#### 단계

1. [쿠버네티스를 사용하여 서비스 및 Deployment 생성](#1-use-kubernetes-to-create-services-and-deployments-for-gitlab-redis-and-postgresql) 하기
  - 1.1 [별도 PostgreSQL 컨테이너 구성하여 사용하기](#11-use-postgresql-in-container) 또는
  - 1.2 [Bluemix의 PostgreSQL 사용하기 (Bluemix Compose for PostgreSQL)](#12-use-postgresql-from-bluemix)
2. [GitLab접근을 위한 외부 ip 및 포트 확인하기](#2-retrieve-external-ip-and-port-for-gitlab)
3. [GitLab이 준비되었습니다! GitLab을 사용하여 저장소를 관리하십시오](#3-gitlab-is-ready-use-gitlab-to-host-your-repositories)

#### 1. 쿠버네티스를 사용하여 GitLab, Redis, PostgreSQL용 서비스 및 Deployment생성 하기

쿠버네티스 클러스터가  `kubectl` 명령 실행을 통해 연결 가능한지 확인하십시오.  

```bash
$ kubectl get nodes
NAME             STATUS    AGE       VERSION
x.x.x.x   Ready     17h       v1.5.3-2+be7137fd3ad68f
```

> 참고:이 단계에서 실패하는 경우, [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) 또는  [IBM Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_troubleshoot.html#cs_troubleshoot)의 문제해결 문서를 참고하십시오.

##### 1.1 별도의 PostgreSQL 컨테이너 사용하기

PostgreSQL를 위한 별도 컨테이너 이미지를 사용하고 있다면, 다음 명령들을 실행하거나 퀵스타트 스크립트  `bash quickstart.sh` 를 통해 쿠버네티스 클러스터 상에서 실행시킵니다.

```bash
$ kubectl create -f kubernetes/local-volumes.yaml
$ kubectl create -f kubernetes/postgres.yaml
$ kubectl create -f kubernetes/redis.yaml
$ kubectl create -f kubernetes/gitlab.yaml
```

서비스와 deployment가 모두 생성한 후에는 3-5분 간 대기해야 합니다. 쿠버네티스 UI에서 배치 현황을 확인할 수 있습니다. 'kubectl proxy' 명령어를 실행 후,  브라우저 상에서  'http://127.0.0.1:8001/ui' 로 이동하면 GitLab 컨테이너가 언제 준비되는지 확인 가능합니다.  

![Kubernetes Status Page](images/kube_ui.png)

그 다음 [GitLab용 외부 ip 및 포트를 확인하십시오.(2-retrieve-external-ip-and-port-for-GitLab)

##### 1.2 Bluemix의 PostgreSQL 사용하기 (Bluemix Compose for PostgreSQL)

Bluemix 카탈로그나 bx 명령을 사용하여 Compose for PostgreSQL 의 서비스 인스턴스를 생성하고, 신임정보를 추가할 수 있습니다.

```bash
$ bx service create compose-for-postgresql Standard "Compose for PostgreSQL-GL"
$ bx service key-create "Compose for PostgreSQL-GL" Credentials-1
```

Bluemix에 위치한 서비스의 신임정보 오브젝트에서 연결되는 문자열을 검색하십시오.

```bash
$ bx service key-show "Compose for PostgreSQL-GL" "Credentials-1" | grep "postgres:"
```

![Postgres Connection String example](images/pg_credentials.png)

```kubernetes/gitlab-postgres-svc.yaml```파일을 수정하고, COMPOSE_PG_PASSWORD는 암호로, COMPOSE_PG_HOST는 호스트네임으로, COMPOSE_PG_PORT는 포트로 바꾸십시오

위 예의 사용 후, ```env:``` 섹션은 아래와 같이 보입니다.

```yaml
  env:
  - name: GITLAB_OMNIBUS_CONFIG
  value: |
      postgresql['enable'] = false
      gitlab_rails['db_username'] = "admin"
      gitlab_rails['db_password'] = "ETIDRKCGOEIGBMZA"
      gitlab_rails['db_host'] = "bluemix-sandbox-dal-9-portal.6.dblayer.com"
      gitlab_rails['db_port'] = "26576"
      gitlab_rails['db_database'] = "compose"
      gitlab_rails['db_adapter'] = 'postgresql'
      gitlab_rails['db_encoding'] = 'utf8'
      redis['enable'] = false
      gitlab_rails['redis_host'] = 'redis'
      gitlab_rails['redis_port'] = '6379'
      gitlab_rails['gitlab_shell_ssh_port'] = 30022
      external_url 'http://gitlab.example.com:30080'

```


다음 명령들을 실행하거나 쿠버네티스 클러스터로 퀵스타트 스크립트  `bash quickstart-postgres-svc.sh`를 실행하십시오.

```bash
$ kubectl create -f kubernetes/local-volumes.yaml
$ kubectl create -f kubernetes/redis.yaml
$ kubectl create -f kubernetes/gitlab-postgres-svc.yaml
```

서비스와 배치를 모두 생성한 후에는 3-5분 간 대기해야 합니다. 쿠버네티스 UI에서 배치 현황을 확인할 수 있습니다. 'kubectl proxy'를 실행하여 URL 'http://127.0.0.1:8001/ui' 로 이동하면 GitLab 컨테이너가 언제 준비되는지 확인 가능합니다.

![Kubernetes Status Page](images/kube_ui_gr.png)

### 2. GitLab외부 접속 ip 및 포트 확인하기

몇 분 후에 다음 명령을 실행하여 외부 IP와 NodePort 번호를 확인하십시오.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.22   Ready     23h
$ kubectl get svc gitlab
NAME      CLUSTER-IP     EXTERNAL-IP   PORT(S)                     AGE
gitlab    10.10.10.148   <nodes>       80:30080/TCP,22:30022/TCP   2s
```

> 참고: 30080 포트는 gitlab UI에 사용되고, 30022 포트는 ssh에 사용됩니다.

> 참고: gitlab 외부 url은  `gitlab.example.com` 으로 설정됩니다. 이 url이 상기 IP 주소를 가리키도록 호스트 파일에 추가하면 gitlab이 예상하는 url을 통해 사용할 수 있습니다. 이것이 불가능할 경우, IP 주소(이 예에서는 169.47.241.22)를 사용하면 됩니다.

> 참고: 만약 Minikube를 이용하여 로컬환경에서 쿠버네티스를 구성하는 경우, `minikube service list` 명령을 통해 서비스들에 대한 IP 주소를 확인할 수 있습니다. 

축하합니다. 이제, 링크  [http://gitlab.example.com:30080](http://gitlab.example.com:30080) 또는 http://<node_ip>:30080 을 이용하여 웹 브라우저에서 gitlab 서비스에 액세스할 수 있습니다.  
### 3. GitLab이 준비되었습니다! GitLab을 사용하여 저장소를 관리하십시오

Gitlab이 실행되고 있으므로, [신규 사용자로 등록하고 프로젝트를 생성할 수 있습니다.](docs/using-gitlab.md).

### 문제 해결

pods가 시작되지 않는다면, 로그를 확인해보십시오.
```bash
kubectl get pods
kubectl logs <pod name>
```

### 정리

서비스, deployment, 생성된 볼륨 등을 모두 삭제하고자 하는 경우, 다음 명령을 실행하십시오.

```bash
kubectl delete deployment,service,pvc -l app=gitlab
```

PersistentVolume(PV)을 삭제하는 명령:

```bash
kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

PostgreSQL 신임정보를 삭제하는 명령 및 Bluemix에서 서비스 인스턴스를 제거하는 명령:

```bash
bx service key-delete "Compose for PostgreSQL-GL" Credentials-1
bx service delete "Compose for PostgreSQL-GL"
```

# 라이센스
[Apache 2.0](LICENSE)
