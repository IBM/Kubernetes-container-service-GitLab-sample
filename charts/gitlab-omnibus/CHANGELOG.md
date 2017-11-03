**0.1.35**
> Upgrade note: 
* Due to the change in default access mode, existing users will have to specify `ReadWriteMany` as the access mode. For example:
```
gitlabDataAccessMode=ReadWriteMany
gitlabRegistryAccessMode=ReadWriteMany
gitlabConfigAccessMode=ReadWriteMany
```

* Sets the default access mode for `gitlab-storage`, `gitlab-registry-storage`, and `gitlab-config-storage` to be `ReadWriteOnce` to be compatible with Kubernetes 1.7.0+. 
* The parameter name to configure the size of the `gitlab-storage` PVC has changed from `gitlabRailsStorageSize` to `gitlabDataStorageSize`. For backwards compatability, `gitlabRailsStorageSize` will still apply provided `gitlabDataStorageSize` is undefined.