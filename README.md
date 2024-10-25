# 개요
- 목적 : MacBook M 시리즈에서 cilium cni 테스트하기 위해 vagrant 이용하여 vanilla-k8s Cluster 구성
- 준비사항 : VMware Fusion과 vagrant 설치 필요함

```bash
# 소스 Download
❯ git clone https://github.com/icebreaker70/kans-vanilla-k8s-cilium
❯ cd kans-vanilla-k8s-cilium

# VM 생성
❯ vagrant up --provision

# VM 상태 확인
❯ vagrant status
Current machine states:

k8s-s                     running (vmware_desktop)
k8s-w1                    running (vmware_desktop)
k8s-w2                    running (vmware_desktop)
testpc                    running (vmware_desktop)

# VM 접속
❯ vagrant ssh k8s-s
❯ vagrant ssh k8s-w1
❯ vagrant ssh k8s-w2
❯ vagrant ssh testpc

# K8s Cluster 확인
❯ vagrant ssh k8s-s
$ kc cluster-info      # kc는 kubectl 실행 내용을 Color로 보여주는 Tool의 Alias
$ kc get nodes -o wide
$ kc get pods -A

# VM 일시멈춤
❯ vagrant suspend

# VM 멈춤재개
❯ vagrant resume

# VM 삭제
❯ vagrant destory -f
```
![k8s와 cilium 설치 후 k8s 구성 정보](https://github.com/icebreaker70/kans-vanilla-k8s-cilium/blob/main/vanilla-k8s-cilium.png)
