# MicroFeature 모듈 생성
.PHONY: generate

# ex) make feature name=모듈명
feature:
	@tuist scaffold feature --name ${name}

# ex) make ui name=모듈명
ui:
	@tuist scaffold ui --name ${name}

# ex) make domain name=모듈명
domain:
	@tuist scaffold domain --name ${name}
