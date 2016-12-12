This document shows briefly, how to create self signed certs and use them with nginx.

Reference: [https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-centos-6](https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-centos-6)

Run the following commands on your work computer (not inside the container):

# Creating the private server key:
```
sudo openssl genrsa -des3 -out server.key 1024
```

# Create a certificate signing request:

Notes: 
* In the command below, the most important line is "Common Name". Enter your official domain name here or, if you don't have one yet, your site's IP address, or just `localhost`.
* Make a note of the passphrase. We will remove it in the next step. (The issue arises when nginx starts or reloads - then you need to re-enter your passphrase - which you do not want happening inside a container.)

```
sudo openssl req -new -key server.key -out server.csr
```

Remove the passphrase you entered in the CSR:
```
sudo cp server.key server.key.org
sudo openssl rsa -in server.key.org -out server.key
```

Create and sign the certificate in one step:
```
sudo openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```



