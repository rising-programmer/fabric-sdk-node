package ksutils

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"time"

	"github.com/pavel-v-chernykh/keystore-go"
)

//ReadKeyStore export
func ReadKeyStore(filename string, password []byte) (keystore.KeyStore, error) {
	f, err := os.Open(filename)
	defer f.Close()

	if err != nil {
		return nil, fmt.Errorf("dump keystore from [%s] meet error", filename)
	}

	keyStore, err := keystore.Decode(f, password)
	if err != nil {
		return nil, fmt.Errorf("dump keystore from [%s] meet error", filename)
	}
	return keyStore, nil
}

//WriteKeyStore export
func WriteKeyStore(keyStore keystore.KeyStore, filename string, password []byte) {
	o, err := os.Create(filename)
	defer o.Close()

	if err != nil {
		log.Fatal(err)
	}

	err = keystore.Encode(o, keyStore, password)

	if err != nil {
		log.Fatal(err)
	}
}

func zeroing(s []byte) {
	for i := 0; i < len(s); i++ {
		s[i] = 0
	}
}

func main() {
	pke, err := ioutil.ReadFile("./privkey.pem")
	if err != nil {
		log.Fatal(err)
	}
	p, _ := pem.Decode(pke)
	if p == nil {
		log.Fatal("Should have at least one pem block")
	}
	if p.Type != "PRIVATE KEY" {
		log.Fatal("Should be a rsa private key")
	}

	keyStore := keystore.KeyStore{
		"100000": &keystore.PrivateKeyEntry{
			Entry: keystore.Entry{
				CreationDate: time.Now(),
			},
			PrivKey: p.Bytes,
		},
	}

	password := []byte("BrlBOjFC84jag1I6")

	defer zeroing(password)
	WriteKeyStore(keyStore, "keystore.jks", password)

	ks, _ := ReadKeyStore("keystore.jks", password)

	entry := ks["100000"]
	privKeyEntry := entry.(*keystore.PrivateKeyEntry)

	key, err := x509.ParsePKCS8PrivateKey(privKeyEntry.PrivKey)

	if err != nil {
		log.Fatal(err)
	}

	log.Printf("%v", key)

}
