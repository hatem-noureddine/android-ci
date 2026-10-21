# Jenkins Integration Guide (`hateum/android-ci-box`)

This guide explains how to configure Jenkins pipelines with `hateum/android-ci-box`, covering Docker agents, Kubernetes Pod templates, and KVM hardware passthrough.

---

## 1. Jenkins Declarative Pipeline with Docker Agent

When Jenkins has the **Docker Pipeline Plugin** installed:

```groovy
pipeline {
    agent {
        docker {
            image 'hateum/android-ci-box:latest'
            // Mount host /dev/kvm for GMD emulators and enforce rootless execution
            args '-v /dev/kvm:/dev/kvm --user 1000:0 -v /tmp/gradle-cache:/home/runner/.gradle'
        }
    }
    stages {
        stage('Diagnostics') {
            steps {
                sh 'ci-doctor --summary'
            }
        }
        stage('Build & Test') {
            steps {
                sh './gradlew lintRelease testReleaseUnitTest assembleRelease --no-daemon'
            }
        }
    }
}
```

---

## 2. Kubernetes Agent Pod Template (Jenkins on K8s)

When running Jenkins agents dynamically on a Kubernetes cluster:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins-agent: android-ci
spec:
  containers:
    - name: android
      image: hateum/android-ci-box:latest
      command: ['cat']
      tty: true
      resources:
        limits:
          cpu: "8"
          memory: "16Gi"
          devices.kubevirt.io/kvm: "1" # Request KVM device plugin
        requests:
          cpu: "4"
          memory: "8Gi"
      volumeMounts:
        - name: dshm
          mountPath: /dev/shm
  volumes:
    - name: dshm
      emptyDir:
        medium: Memory
```

---

## 3. Ready-to-Use Template

A complete declarative Jenkinsfile is available at [`examples/ci/Jenkinsfile`](../../../examples/ci/Jenkinsfile).
