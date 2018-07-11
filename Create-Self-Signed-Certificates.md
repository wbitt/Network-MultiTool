This document shows briefly, how to create self signed certs and use them with nginx.

# For the impatient:
Just run the `generate-self-signed-ssl-certs.sh` as:
```
$ ./generate-self-signed-ssl-certs.sh 
Generating certificate (valid for 10 years! :)
Generating a 2048 bit RSA private key
..........................................................................................+++
..............................+++
writing new private key to 'server.key'
-----

Generated files:
server.crt  server.key
```

# Detailed process:
Note: The script creates the certificate without using a CSR.

Reference: [https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-centos-6](https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-centos-6)

Run the following commands on your work computer (not inside the container):

# Creating the private server key:
```
openssl genrsa -des3 -out server.key 1024
```

# Create a certificate signing request:

Notes: 
* In the command below, the most important line is "Common Name". Enter your official domain name here or, if you don't have one yet, your site's IP address, or just `localhost`.
* Make a note of the passphrase. We will remove it in the next step. (The issue arises when nginx starts or reloads - then you need to re-enter your passphrase - which you do not want happening inside a container.)

```
openssl req -new -key server.key -out server.csr
```

Remove the passphrase you entered in the CSR:
```
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key
```

Create and sign the certificate in one step:
```
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt
```



