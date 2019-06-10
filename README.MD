# START

```
docker run -d --network iq84_network cockroachdb/cockroach start --insecure
docker run -it --network iq84_network --add-host=iq84_db:172.19.0.2 -v $PWD/iq84:/home/iq84 iq84 /bin/bash
```