# Docker buildx build using docker-in-docker

Running:
```
git clone https://github.com/nyvanga/will_fail_on_docker_zfs.git
will_fail_on_docker_zfs/run.sh test
```

Will fail when running on a docker server with zfs storage driver:
```
39.76 Setting up ca-certificates (20230311+deb12u1) ...
40.86 mv: cannot move '/etc/ca-certificates.conf' to a subdirectory of itself, '/etc/ca-certificates.conf.dpkg-old'
```

On non-zfs storage driver docker servers it works fine.

## `tmpfs` work-around

A work-around is to use `tmpfs` for the `/var/lib/docker` volume in `dokcer:dind`.

Test by running:
```
will_fail_on_docker_zfs/run.sh test-tmpfs
```

## Checking storage driver

Run:
```
docker info
```

Docker server with zfs storage driver will return something like:
```
Server:
 Server Version: 28.2.2
 Storage Driver: zfs
  Zpool: < ... >
  Zpool Health: ONLINE
  Parent Dataset: < ... >
  Space Used By Parent: 441630720
  Space Available: 6542528937984
  Parent Quota: no
  Compression: lz4
```

Docker server with other (here it is overlay2) will return:
```
Server:
 Server Version: 28.2.2
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: true
```
