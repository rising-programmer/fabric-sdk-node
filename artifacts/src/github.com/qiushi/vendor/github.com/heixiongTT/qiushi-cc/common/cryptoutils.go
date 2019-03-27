package common

import (
	"fmt"
	"log"

	rsautils "github.com/heixiongTT/qiushi-cc/rsautils"
	"github.com/tidwall/gjson"
)

//CryptoDescriptor comments
type CryptoDescriptor struct {
	Level        string   `json:"level"`
	CryptoFields []string `json:"cryptoFields"`
}

//CryptoDataByDescriptor export
func CryptoDataByDescriptor(jsonData string, cds []CryptoDescriptor, pubKey string) (map[string]interface{}, error) {
	rawData, ok := gjson.Parse(jsonData).Value().(map[string]interface{})
	if !ok {
		return rawData, fmt.Errorf("json is invalidate")
	}
	if len(cds) < 1 {
		return rawData, nil
	}
	for _, cd := range cds {
		if cd.Level == "PUBLIC" || cd.Level == "PATH" {
			keys := cd.CryptoFields
			for _, key := range keys {
				rawValue := gjson.Get(jsonData, key).String()
				log.Printf("@@CryptoDataByDescriptor execute begin key is [%s]\nvalue is [%v]\n", key, rawValue)
				if rawValue != "" {
					encryptValue := rsautils.RSAEncrypt(pubKey, rawValue)
					log.Printf("@@CryptoDataByDescriptor encryptData sucess.[%s]\n", encryptValue)
					rawData[key] = encryptValue
				}
			}
		}
		if cd.Level == "REPORT" {
			//KEY IS REPORT NAME
			keys := cd.CryptoFields
			for _, key := range keys {
				innerReport := make(map[string]interface{}, 128)
				result := gjson.Get(jsonData, key)
				result.ForEach(func(key, value gjson.Result) bool {
					reportVal := value.String()
					if reportVal != "" {
						encryptReportValue := rsautils.RSAEncrypt(pubKey, reportVal)
						innerReport[key.String()] = encryptReportValue
					}
					return true // keep iterating
				})
				rawData[key] = innerReport
			}
		}
	}
	return rawData, nil
}

//DecryptoDataByDescriptor export
func DecryptoDataByDescriptor(encryptJSONData string, cds []CryptoDescriptor, privKey string) (map[string]interface{}, error) {
	rawData, ok := gjson.Parse(encryptJSONData).Value().(map[string]interface{})
	if !ok {
		return rawData, fmt.Errorf("json is invalidate")
	}
	if len(cds) < 1 {
		return rawData, nil
	}
	for _, cd := range cds {
		if cd.Level == "PUBLIC" || cd.Level == "PATH" {
			keys := cd.CryptoFields
			for _, key := range keys {
				rawValue := gjson.Get(encryptJSONData, key).String()
				log.Printf("@@DecryptoDataByDescriptor execute begin key is [%s]\nvalue is [%v]\n", key, rawValue)
				decryptValue := rsautils.RSADecrypt(privKey, rawValue)

				log.Printf("@@CryptoDataByDescriptor decryptValue sucess.[%s]\n", decryptValue)
				rawData[key] = decryptValue
			}
		}

		if cd.Level == "REPORT" {
			//KEY IS REPORT NAME
			keys := cd.CryptoFields
			for _, key := range keys {
				innerReport := make(map[string]interface{}, 128)
				result := gjson.Get(encryptJSONData, key)
				result.ForEach(func(key, value gjson.Result) bool {
					reportVal := value.String()
					if reportVal != "" {
						decryptReportValue := rsautils.RSADecrypt(privKey, reportVal)
						innerReport[key.String()] = decryptReportValue
					}
					return true // keep iterating
				})
				rawData[key] = innerReport
			}
		}

	}
	//字符串还原为对象
	for _, cd := range cds {
		keys := cd.CryptoFields
		if cd.Level == "PUBLIC" || cd.Level == "PATH" {
			for _, key := range keys {
				rawData[key] = gjson.Parse(rawData[key].(string)).Value()
			}
		}

		//REPORT场景无需处理

	}

	return rawData, nil
}
