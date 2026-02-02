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

# ex) make module name=DesignSystem
# ex) make module name=Network dir=Shared
module:
	@tuist scaffold module --name $(name) $(if $(dir),--dir $(dir),)

project:
	tuist install
	tuist generate

edit:
	tuist edit

clean:
	tuist clean
	tuist clean dependencies
	
# 4.115.0
reset:
	tuist clean
	rm -rf Tuist/.build
	rm -rf ~/.tuist-cache
	tuist version
	tuist install
	tuist generate --no-open