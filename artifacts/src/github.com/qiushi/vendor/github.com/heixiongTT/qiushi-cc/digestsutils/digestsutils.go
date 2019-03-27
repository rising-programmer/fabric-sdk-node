package digestsutils

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
)

//MD5 export
func MD5(msg string) string {
	h := md5.New()
	h.Write([]byte(msg))
	digestsBytes := h.Sum(nil)
	return hex.EncodeToString(digestsBytes)
}

//MD5Verify export
func MD5Verify(msg string, digests string) bool {
	expected := MD5(msg)
	return expected == digests
}

func main() {
	msg := "helloworld"
	digests := MD5(msg)
	fmt.Println(digests)
	verified := MD5Verify(msg, digests)
	fmt.Println(verified)
}
