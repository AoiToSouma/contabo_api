# contabo_api
Contabo VPS operations using Contabo API.<br>
[Contabo API document](https://api.contabo.com/)<br><br>

reference(参考)<br>
https://qiita.com/aoitosouma/private/9dd06daae5eafc5896ac

# Procedure
## Installing jq package
```
sudo apt install jq
```

## git clone
```
sudo apt install jq
```
```
cd contabo_api
chmod +x *.sh
```

## Environmental setting
```
nano profile.conf
```
Click [here](https://my.contabo.com/api/details) for Contabo settings.

## Execute
### Get VPS information
```
./ContaboApi.sh status
```
### Create snapshot
```
./ContaboApi.sh snapshot create
```
Enter Name and Description.

### Delete snapshot
```
./ContaboApi.sh snapshot delete
```

### Rollback from snapshot
```
./ContaboApi.sh snapshot rollback
```

