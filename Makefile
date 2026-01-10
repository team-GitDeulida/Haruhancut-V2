.PHONY: generate

# MicroFeature 모듈 생성
# ex) make module name=모듈명
feature:
	@tuist scaffold feature --name ${name}

ui:
	@tuist scaffold ui --name ${name}






# .PHONY: module feature domain

# feature:
# ifndef name
# 	$(error name 필요: make feature name=Login)
# endif
# 	@tuist scaffold feature --name $(name)

# domain:
# ifndef name
# 	$(error name 필요: make domain name=User)
# endif
# 	@tuist scaffold domain --name $(name)
