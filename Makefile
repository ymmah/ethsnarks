ROOT_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))

ifeq ($(OS),Windows_NT)
	detected_OS := Windows
	DLL_EXT := .dll
else
	detected_OS := $(shell uname -s)
	ifeq ($(detected_OS),Darwin)
		DLL_EXT := .dylib
		export LD_LIBRARY_PATH := /usr/local/opt/openssl/lib:"$(LD_LIBRARY_PATH)"
		export CPATH := /usr/local/opt/openssl/include:"$(CPATH)"
		export PKG_CONFIG_PATH := /usr/local/opt/openssl/lib/pkgconfig:"$(PKG_CONFIG_PATH)"
	else
		DLL_EXT := .so
	endif
endif

PIP_ARGS ?= --user
PYTHON ?= python3
NAME ?= ethsnarks
NPM ?= npm
GANACHE ?= $(ROOT_DIR)/node_modules/.bin/ganache-cli
TRUFFLE ?= $(ROOT_DIR)/node_modules/.bin/truffle

COVERAGE = $(PYTHON) -mcoverage run --source=$(NAME) -p


#######################################################################


all: build/src/libmiximus.$(DLL_EXT) truffle-compile

clean: coverage-clean
	rm -rf build
	find . -name '__pycache__' -exec rm -rf '{}' ';'


#######################################################################


build:
	mkdir -p build

bin/miximus_genKeys: build/Makefile
	make -C build

build/src/libmiximus.$(DLL_EXT): build/Makefile
	make -C build

build/Makefile: build CMakeLists.txt
	cd build && cmake ..

depends/libsnarks/CMakeLists.txt:
	git submodule update --init --recursive


#######################################################################


.PHONY: test
test: cxx-tests python-test truffle-test

python-test:
	$(COVERAGE) -m unittest discover test/

cxx-tests:
	./bin/test_field_packing > /dev/null
	./bin/test_hashpreimage
	./bin/test_longsightl
	./bin/test_longsightl_hash_mp
	./bin/test_merkle_tree
	./bin/test_one_of_n
	./bin/test_r1cs_gg_ppzksnark_zok
	./bin/test_shamir_poly
	./bin/test_sha256_full_gadget

	time ./bin/hashpreimage_cli genkeys zksnark_element/hpi.pk.raw zksnark_element/hpi.vk.json
	ls -lah zksnark_element/hpi.pk.raw
	time ./bin/hashpreimage_cli prove zksnark_element/hpi.pk.raw 0x9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a089f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08 zksnark_element/hpi.proof.json
	time ./bin/hashpreimage_cli verify zksnark_element/hpi.vk.json zksnark_element/hpi.proof.json
	time ./bin/test_load_proofkey zksnark_element/hpi.pk.raw

	time ./bin/miximus_cli genkeys zksnark_element/miximus.pk.raw zksnark_element/miximus.vk.json


#######################################################################


coverage: coverage-combine coverage-report

coverage-clean:
	rm -rf .coverage .coverage.* htmlcov

coverage-combine:
	$(PYTHON) -m coverage combine

coverage-report:
	$(PYTHON) -m coverage report

coverage-html:
	$(PYTHON) -m coverage html


#######################################################################


lint: python-pyflakes python-pylint cxx-lint

python-pyflakes:
	$(PYTHON) -mpyflakes $(NAME)

python-pylint:
	$(PYTHON) -mpylint $(NAME) || true

cxx-lint:
	cppcheck -I depends/libsnark/ -I depends/libsnark/depends/libff/ -I depends/libsnark/depends/libfqfft/ -I src/ --enable=all src/ || true


#######################################################################


python-dependencies: requirements requirements-dev

requirements:
	$(PYTHON) -m pip install $(PIP_ARGS) -r requirements.txt

requirements-dev:
	$(PYTHON) -m pip install $(PIP_ARGS) -r requirements-dev.txt

fedora-dependencies:
	dnf install procps-ng-devel gmp-devel boost-devel cmake g++ python3-scipy python3-pip

ubuntu-dependencies:
	apt-get install cmake make g++ libgmp-dev libboost-all-dev libprocps-dev python3-pip python3-scipy

mac-dependencies:
	brew install pkg-config boost cmake gmp openssl || true


#######################################################################


nvm-install:
	./utils/nvm-install
	nvm install --lts

node_modules:
	$(NPM) install

$(TRUFFLE): node_modules

$(GANACHE): node_modules

.PHONY: truffle-test
truffle-test: $(TRUFFLE)
	$(NPM) run test

truffle-compile: $(TRUFFLE)
	$(TRUFFLE) compile

testrpc: $(TRUFFLE)
	$(NPM) run testrpc

