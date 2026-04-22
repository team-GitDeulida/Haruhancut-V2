# MicroFeature 모듈 생성
.PHONY: generate

# ex) make feature 모듈명
# ex) make feature name=모듈명
# - positional 인자는 접미사 없이 생성
# - name= 방식은 기존처럼 Feature 접미사를 유지
FEATURE_EXTRA_GOALS := $(filter-out feature,$(MAKECMDGOALS))
FEATURE_NAME := $(firstword $(FEATURE_EXTRA_GOALS))

ifeq ($(filter feature,$(MAKECMDGOALS)),feature)
ifneq ($(FEATURE_EXTRA_GOALS),)
$(eval $(FEATURE_EXTRA_GOALS):;@:)
endif
endif

feature:
	@if [ -n "$(FEATURE_NAME)" ]; then \
		tuist scaffold feature_nosuffix --name "$(FEATURE_NAME)"; \
	elif [ -n "$(name)" ]; then \
		tuist scaffold feature --name "$(name)"; \
	else \
		echo "Usage: make feature 모듈명 | make feature name=모듈명"; \
		exit 1; \
	fi

# ex) make ui name=모듈명
ui:
	@tuist scaffold ui --name ${name}

# ex) make domain name=모듈명
domain:
	@tuist scaffold domain --name ${name}

# ex) make module name=DesignSystem
# ex) make module name=Network dir=Shared
# ex) make module name=WidgetSupport dir=Shared
module:
	@tuist scaffold module --name $(name) $(if $(dir),--dir $(dir),)

# ex) make widget name=HaruhancutWidget
widget:
	@tuist scaffold widget --name ${name}

project:
	tuist install
	tuist generate

edit:
	tuist edit

clean:
	tuist clean
	tuist clean dependencies
	
light-reset:
	tuist clean
	rm -rf .tuist
	rm -rf Tuist/.build
	rm -rf ~/Library/Developer/Xcode/DerivedData
	tuist generate

# 4.115.0
reset:
	tuist clean
	rm -rf .tuist
	rm -rf Tuist/.build
	rm -rf ~/.tuist-cache
	rm -rf ~/Library/Developer/Xcode/DerivedData
	tuist version
	tuist install
	tuist generate

# 💣 정말 꼬였을 때만 쓰는 deep reset
deep-reset:
	tuist clean
	rm -rf .tuist
	rm -rf Tuist/.build
	rm -rf ~/.tuist-cache
	rm -rf ~/.local/state/tuist
	rm -rf ~/Library/Developer/Xcode/DerivedData
	tuist install
	tuist generate

test:
	killall Xcode || true
	killall Simulator || true

	sudo rm -rf /var/root/Library/Developer/Xcode
	sudo rm -rf /var/root/.local/state/tuist

	rm -rf ~/Library/Developer/Xcode/DerivedData
	rm -rf ~/.local/state/tuist
	rm -rf ~/.tuist

	sudo chown -R kimdonghyeon:staff \
	/Users/kimdonghyeon/2025/개발/앱출시/하루한컷

	tuist clean
	rm -rf .tuist
	rm -rf Tuist/.build
	rm -rf ~/.tuist-cache
	tuist version
	tuist install
	tuist generate --no-open
	tuist test CoreTests
