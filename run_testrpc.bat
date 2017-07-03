# precreate accounts
start testrpc ^
	--account="0x83c14ddb845e629975e138a5c28ad5a72a49252ea65b3d3ec99810c82751cc3a,1000000000000000000000000" ^
	--account="0x52f3a1fa15405e1d5a68d7774ca45c7a3c7373a66c3c44db94a7f99a22c14d28,1000000000000000000000000" ^
	--account="0xdc6a7f0cd30f86da5e55ca7b62ac1a86f5d8b76a796176152803e0fcbc253900,1000000000000000000000000" ^
	--account="0xd3b6b98613ce7bd4636c5c98cc17afb0403d690f9c2b646726e08334583de101,2000000000000000000000000" ^
	--unlock "0xf1f42f995046e67b79dd5ebafd224ce964740da3"
# 0xaec3ae5d2be00bfc91597d7a1b2c43818d84396a - account for the first given private key
# 0x444a798fad3ef318bfd7cee26c5937298cc2cbec - account for the second given private key
# 0xa921ef355a7d2729e7674a081aeeceff28419e23  - account for the third given private key
# 0xf1f42f995046e67b79dd5ebafd224ce964740da3 - account for the last given private key

# use the first account as founder of the contracts and multisig
# use others as accounts of investor
