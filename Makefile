.PHONY=build
build: clean
	scripts/write-git-info
	pyinstaller --onefile --add-data cogctl/GITSHA:. --add-data cogctl/GITTAG:. bin/cogctl

clean:
	rm -Rf build
	rm -Rf dist

lint:
        # Bumped up to handle long string literals
        # in unit tests
	flake8 --max-line-length=85

test:
	pytest --cov-report=term:skip-covered --cov=cogctl

acceptance:
	bin/cucumber

all: clean lint test acceptance build

deps: python-deps ruby-deps

python-deps:
	pip install -r requirements.txt
	pip install -r requirements.build.txt

ruby-deps:
	bundle install --path=vendor --binstubs
