package common

//Header the data header in fabric network
type Header struct {
	//数据标识
	Key string `json:"key"`

	//父数据标识
	PKey string `json:"pkey"`

	//被授权人标识
	Licensee string `json:" licensee"`

	//授权人标识
	Authorizer string `json:"authorizer"`

	//数据关联业务方
	Partner string `json:"partner"`

	//数据关联业务方上链策略
	Strategy string `json:"strategy"`

	//加密描述符
	CryptoDescriptor string `json:"cryptoDescriptor"`

	MetaInfo string `json:"metaInfo"`
}

//Footer the data footer in fabric network
type Footer struct {

	//数据摘要
	Digests string `json:"digests"`

	//授权人签名
	Signature string `json:"signature"`
}

//DataContent we import from request.
//The struct will be :
//{
//	"_hdr":Header
//	"_ftr":Footer
//	"reqField1":reqVal1
//	....
//}
