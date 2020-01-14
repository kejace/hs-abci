# Thank you Apple
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	SED=sed -i''
endif
ifeq ($(UNAME_S),Darwin)
	SED=sed -i ''
endif

install:
	sudo apt-get install -y bundler pandoc && \
	bundle update && \
	bundle install 

pre-process:
	find ./tutorial -type f -name "*.md" -exec $(SED) -e 's/~~~ haskell.*/```haskell/g' {} + && \
	find ./tutorial -type f -name "*.md" -exec $(SED) -e 's/~~~/```/g' {} +

build: install pre-process
	JEKYLL_ENV=production bundle exec jekyll build --destination _site

serve: install pre-process
	bundle exec jekyll serve --incremental --trace
