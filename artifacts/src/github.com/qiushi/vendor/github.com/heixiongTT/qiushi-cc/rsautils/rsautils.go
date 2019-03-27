package rsautils

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"io/ioutil"
	"log"

	keystore "github.com/pavel-v-chernykh/keystore-go"
	"github.com/heixiongTT/qiushi-cc/ksutils"
)

//RSAEncrypt export
func RSAEncrypt(pubKeyBase64 string, msg string) string {
	pubKey, err := LoadPublicKeyBase64(pubKeyBase64)
	if err != nil {
		log.Fatal(err)
	}
	dataBytes := []byte(msg)

	encryptedData, err := rsa.EncryptPKCS1v15(rand.Reader, pubKey, dataBytes)
	if err != nil {
		log.Fatal(err)
	}
	return base64.StdEncoding.EncodeToString(encryptedData)
}

//RSADecrypt export
func RSADecrypt(privKeyBase64 string, msg string) string {
	privKey, err := LoadPrivateKeyBase64(privKeyBase64)
	if err != nil {
		log.Fatal(err)
	}

	dataBytes, err := base64.StdEncoding.DecodeString(msg)
	if err != nil {
		log.Fatal(err)
	}
	v, err := rsa.DecryptPKCS1v15(rand.Reader, privKey, dataBytes)
	return string(v)
}

//RSASignature export
func RSASignature(privKeyBase64 string, msg string) string {

	privKey, err := LoadPrivateKeyBase64(privKeyBase64)
	if err != nil {
		log.Fatal(err)
	}
	h := crypto.Hash.New(crypto.SHA1)
	h.Write([]byte(msg))
	hashed := h.Sum(nil)
	signedData, err := rsa.SignPKCS1v15(rand.Reader, privKey, crypto.SHA1, hashed)
	return base64.StdEncoding.EncodeToString(signedData)
}

//RSAVerify export
func RSAVerify(pubKeyBase64 string, msg string, signedData string) bool {
	pubKey, err := LoadPublicKeyBase64(pubKeyBase64)
	if err != nil {
		log.Fatal(err)
	}
	h := crypto.Hash.New(crypto.SHA1)
	h.Write([]byte(msg))
	hashed := h.Sum(nil)
	dataBytes, err := base64.StdEncoding.DecodeString(signedData)
	if err != nil {
		log.Fatal(err)
	}
	vr := rsa.VerifyPKCS1v15(pubKey, crypto.SHA1, hashed, dataBytes)
	if vr != nil {
		return false
	}
	return true
}

//DumpKSBase64 export
func DumpKSBase64(kspath string, kspwd string, key string) (string, error) {
	ks, err := ksutils.ReadKeyStore(kspath, []byte(kspwd))
	if err != nil {
		return "", fmt.Errorf("dump keystore from [%s] meet error", kspath)
	}
	entry := ks[key]
	privKeyEntry := entry.(*keystore.PrivateKeyEntry)

	private, err := x509.ParsePKCS8PrivateKey(privKeyEntry.PrivKey)
	//private, err := x509.ParsePKCS8PrivateKey(p.Bytes)

	if err != nil {
		return "", fmt.Errorf("dump keystore from [%s] meet error", kspath)
	}
	privkeyBytes, err := x509.MarshalPKCS8PrivateKey(private)
	if err != nil {
		return "", fmt.Errorf("dump keystore from [%s] meet error", kspath)
	}
	keybase64 := base64.StdEncoding.EncodeToString(privkeyBytes)
	return keybase64, nil
}

//DumpPublicKeyBase64 export
func DumpPublicKeyBase64(filename string) (string, error) {
	pbe, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", fmt.Errorf("dump public key from [%s] meet error", filename)
	}

	p, _ := pem.Decode(pbe)
	if p == nil {
		return "", fmt.Errorf("dump public key from [%s] meet error", filename)
	}

	if p.Type != "PUBLIC KEY" {
		return "", fmt.Errorf("dump public key from [%s] meet error", filename)
	}

	pub, err := x509.ParsePKIXPublicKey(p.Bytes)
	if err != nil {
		log.Fatal(err)
	}
	publickeyBytes, err := x509.MarshalPKIXPublicKey(pub)
	if err != nil {
		return "", err
	}
	keybase64 := base64.StdEncoding.EncodeToString(publickeyBytes)
	return keybase64, nil
}

//DumpPrivateKeyBase64 export
func DumpPrivateKeyBase64(filename string) (string, error) {
	pbe, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", fmt.Errorf("dump private key from [%s] meet error", filename)
	}

	p, _ := pem.Decode(pbe)
	if p == nil {
		return "", fmt.Errorf("dump private key from [%s] meet error", filename)
	}

	if p.Type != "PRIVATE KEY" {
		return "", fmt.Errorf("dump private key from [%s] meet error", filename)
	}

	private, err := x509.ParsePKCS8PrivateKey(p.Bytes)

	if err != nil {
		log.Fatal(err)
	}

	privkeyBytes, err := x509.MarshalPKCS8PrivateKey(private)
	if err != nil {
		return "", err
	}
	keybase64 := base64.StdEncoding.EncodeToString(privkeyBytes)
	return keybase64, nil
}

//LoadPrivateKeyBase64 export
func LoadPrivateKeyBase64(base64key string) (*rsa.PrivateKey, error) {
	keybytes, err := base64.StdEncoding.DecodeString(base64key)
	if err != nil {
		return nil, fmt.Errorf("base64 decode failed, error=%s", err.Error())
	}

	privatekey, err := x509.ParsePKCS8PrivateKey(keybytes)
	if err != nil {
		return nil, errors.New("parse private key error")
	}

	return privatekey.(*rsa.PrivateKey), nil
}

//LoadPublicKeyBase64 export
func LoadPublicKeyBase64(base64key string) (*rsa.PublicKey, error) {
	keybytes, err := base64.StdEncoding.DecodeString(base64key)
	if err != nil {
		return nil, fmt.Errorf("base64 decode failed, error=%s", err.Error())
	}

	pubKey, err := x509.ParsePKIXPublicKey(keybytes)
	if err != nil {
		return nil, err
	}
	return pubKey.(*rsa.PublicKey), nil
}

// func main() {
// 	privPath := "./privkey.pem"
// 	pubPath := "./pubkey.pem"

// 	msg := "helloworld"
// 	// /msg2 := "helloworld2"
// 	privKeyBase64, _ := DumpPrivateKeyBase64(privPath)
// 	pubKeyBase64, _ := DumpPublicKeyBase64(pubPath)
// 	fmt.Println(privKeyBase64)
// 	fmt.Println(pubKeyBase64)
// 	encryptMsg := RSAEncrypt(pubKeyBase64, msg)
// 	decryptMsg := RSADecrypt(privKeyBase64, encryptMsg)
// 	fmt.Println(decryptMsg)

// 	signedMsg := RSASignature(privPath, msg)
// 	err := RSAVerify(pubPath, msg, signedMsg)

// 	fmt.Println(err)
// }

func main() {
	priKey := "MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMHaqzNXFWMuCJn91eCtmC+s0VhvUr7HhpIFITGZBUikfjR1WuwMSH/ryh6GWy2fpHdu3+8H0V4wcbATGRG0jiS5e80Kb/+MldOAXO8EPkWfXAQGGg6PKMIgqoes0pnJ81oMqFmHQYAKMI8cuJ300FWjL5FRai16F0CTcZZLRObnAgMBAAECgYAE15ZxKNqy6IJ0fj+qZguoHTP5doZll4xH93LVz1Gvd9RjMQ89WC0zbMtWqdp7MEKmbRGQ4ewb4y/jywZUR+NJAmsYoBLLcdnJ98zUMqaCa8/AjmgVIW1c6gsFCMTFuv3fInYjibAkPmlIYMN3DFM1oiqaOmWUYnHaOmfuhTOGKQJBAOSZEaPkeD0O2ImnrpnHeZYQa2NLqb2zyC+gptcVRi1OFHPUnZmxAGhMwYdbayNLU2G/COQmNxv33xoJV49HMPUCQQDZF20upoB8N2jPLLqiBqiktqlYHIBrGtiRf59/6kl73gT1XQn9kNJt413rFjrTqyxDl5EvNhQTpZvr2uLCjV7rAkEAobXqta7UpBTRd6eIKz7iMxcQcKDAxfLdJVwXSkXBbCE09K+ugV+mMyJBMVipVMFfjeEPEB48k+toBsofB7tL1QJAdgta/ybibqjigOTdhwT/5rC8XIEDAzpR0KwI2tFWq9gJ8jFpIUwCYGZlx1MLIdXN9+MOuxE40YYXxqP68bdViQJBAMTS4UKxV6UYEqtffrToJtz5edggPsRyEGZJbwiJSLN9O4QB17KvSKsF0ljHyrjPLZGOW+GNzEPi2mLBJPvr/Io="
	LoadPrivateKeyBase64(priKey)
}
